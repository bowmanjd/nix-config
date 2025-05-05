{
  lib,
  pkgs,
  environment ? "home",
  ...
}: {
  systemd.user.services = let
    scriptpath = lib.makeBinPath [pkgs.llmscripts];
  in {
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

  programs.bash.bashrcExtra = ''
    if [ ! -s "$XDG_RUNTIME_DIR/llmconf/keys" ]; then
      llm_vars.sh
    fi
    set -a
    . "$XDG_RUNTIME_DIR/llmconf/keys"
    set +a
  '';

  home.packages = with pkgs; [
    aichat
    aider-chat-with-playwright
    fabric-ai
    goose-cli
    llmscripts
    mods
  ];

  xdg.configFile."mods.yml" = {
    enable = true;
    source = ./mods.yml;
    target = "mods/mods.yml";
  };

  xdg.configFile."aichat.yml" = {
    enable = true;
    source = ./aichat.yml;
    target = "aichat/config.yaml";
  };

  home.file."aider" = let
    mergedConfig = pkgs.writeText "aider-merged.conf.yml" (
      builtins.readFile ./aider-common.conf.yml
      + "\n\n# ${environment} config\n"
      + builtins.readFile ./aider-${environment}.conf.yml
    );
  in {
    enable = true;
    source = mergedConfig;
    target = "./.aider.conf.yml";
  };
}
