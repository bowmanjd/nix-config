{
  lib,
  pkgs,
  environment ? "home",
  ...
}: let
  scriptpath = lib.makeBinPath [pkgs.llmscripts];

  # Helper function for creating merged config files
  mergeConfigs = {
    name,
    commonFile,
    environmentFile,
    environmentFirst ? false,
  }:
    pkgs.writeText "${name}-merged.yml" (
      if environmentFirst
      then
        "\n\n# ${environment} config\n"
        + builtins.readFile environmentFile
        + builtins.readFile commonFile
      else
        builtins.readFile commonFile
        + "\n\n# ${environment} config\n"
        + builtins.readFile environmentFile
    );
in {
  imports = [
    (import ./vllm.nix {
      inherit pkgs lib environment;
    })
  ];
  # Systemd services
  systemd.user.services = {
    "litellm" = {
      Unit = {
        Description = "LiteLLM API server";
        StartLimitIntervalSec = "120";
        StartLimitBurst = "5";
        After = ["network.target"];
      };
      Service = {
        ExecStart = "${pkgs.litellm}/bin/litellm --port 1173 --config ${./litellm-config.yaml}";
        EnvironmentFile = "-%t/llmconf/keys";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    "copilotkey" = {
      Unit = {
        Description = "Refresh Github Copilot API key";
      };
      Service = {
        ExecStart = "${scriptpath}/copilotkey.js";
        Type = "oneshot";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
    };
  };

  # Systemd timers
  systemd.user.timers = {
    "copilotkey" = {
      Unit = {
        Description = "Refresh Github Copilot API key regularly";
      };
      Timer = {
        OnCalendar = "*:0/15";
        Persistent = true;
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };

  # Bash config
  programs.bash.bashrcExtra = ''
    if [ ! -s "$XDG_RUNTIME_DIR/llmconf/keys" ]; then
      llm_vars.sh
    fi
    set -a
    . "$XDG_RUNTIME_DIR/llmconf/keys"
    set +a
  '';

  # Packages
  home.packages = with pkgs; [
    aichat
    aider-chat-with-playwright
    claude-code
    codex
    fabric-ai
    goose-cli
    llmscripts
    mods
    ollama
    vllm
    # (vllm.override {
    #   cudaSupport = false;
    #   rocmSupport = false;
    # })
  ];

  # Config files
  xdg.configFile = {
    "mods.yml" = {
      enable = true;
      source = ./mods.yml;
      target = "mods/mods.yml";
    };

    "aichat.yml" = {
      enable = true;
      source = mergeConfigs {
        name = "aichat";
        environmentFile = ./aichat-${environment}.yml;
        commonFile = ./aichat-common.yml;
        environmentFirst = true;
      };
      target = "aichat/config.yaml";
    };
  };

  # Home files
  home.file."aider" = {
    enable = true;
    source = mergeConfigs {
      name = "aider";
      environmentFile = ./aider-${environment}.conf.yml;
      commonFile = ./aider-common.conf.yml;
    };
    target = "./.aider.conf.yml";
  };
}
