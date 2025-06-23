{
  lib,
  pkgs,
  environment ? "home",
  ...
}: let
  scriptpath = lib.makeBinPath [pkgs.llmscripts];

  litellm = pkgs.callPackage "${pkgs.path}/pkgs/by-name/li/litellm/package.nix" {
    python3Packages =
      pkgs.python3Packages
      // {
        litellm = pkgs.python3Packages.litellm.overridePythonAttrs (old: {
          version = "1.72.6";
          src = pkgs.fetchFromGitHub {
            owner = "BerriAI";
            repo = "litellm";
            tag = "v1.72.6-stable";
            hash = "sha256-Qs/jmNJx/fztLqce47yd1pzIZyPsz0XhXUyoC1vkp6g=";
          };
        });
      };
  };

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
        WorkingDirectory = "%D/litellm";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %D/litellm";
        ExecStart = "${litellm}/bin/litellm --port 1173 --config %E/litellm/litellm-config.yaml";
        EnvironmentFile = "-%t/llmconf/keys";
        Environment = [
          "PRISMA_SCHEMA_ENGINE_BINARY=${pkgs.prisma-engines}/bin/schema-engine"
          "PRISMA_QUERY_ENGINE_BINARY=${pkgs.prisma-engines}/bin/query-engine"
          "PRISMA_QUERY_ENGINE_LIBRARY=${pkgs.prisma-engines}/lib/libquery_engine.node"
        ];
        Restart = "on-failure";
        RestartSec = 5;
        StateDirectory = "open-webui";
        RuntimeDirectory = "open-webui";
        RuntimeDirectoryMode = "0755";
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    "webui" = {
      Unit = {
        Description = "Open WebUI server";
        StartLimitIntervalSec = "120";
        StartLimitBurst = "5";
        After = ["network.target"];
      };
      Service = {
        WorkingDirectory = "%D/webui";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %D/webui";
        ExecStart = "${pkgs.open-webui}/bin/open-webui serve --port 3011 --host 127.0.0.1";
        EnvironmentFile = "-%t/llmconf/webui";
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";
        StateDirectory = "open-webui";
        RuntimeDirectory = "open-webui";
        RuntimeDirectoryMode = "0755";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    "copilotkey" = {
      Unit = {
        Description = "Refresh Github Copilot API key";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };
      Service = {
        ExecStart = "${scriptpath}/copilotkey.js";
        Type = "oneshot";
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
  programs.bash.bashrcExtra = lib.mkAfter ''
    if [ ! -s "$XDG_RUNTIME_DIR/llmconf/keys" ]; then
      llm_vars.sh
    fi
    set -a
    . "$XDG_RUNTIME_DIR/llmconf/keys"
    set +a

    if [ ! -d "$HOME/src/aichat-functions" ]; then
      git clone git@github.com:sigoden/llm-functions.git "$HOME/src/aichat-functions"
    fi
    export AICHAT_FUNCTIONS_DIR="$HOME/src/aichat-functions"
  '';

  # Packages
  home.packages = with pkgs; let
    goose-ai = goose-cli.overrideAttrs (finalAttrs: old: {
      version = "1.0.29";
      # cargoHash = "sha256-sW4rWLElTPVzD+KCOrikEFcoIRGujMz+wHOWlYBpi0o=";
      cargoHash = "sha256-EEivL+6XQyC9FkGnXwOYviwpY8lk7iaEJ1vbQMk2Rao=";
      src = old.src.override {
        tag = "v1.0.29";
        # hash = "sha256-ExFVgG05jlcz3nP6n94324sgXbIHpj8L30oNuqKyfto=";
        hash = "sha256-R4hMGW9YKsvWEvSzZKkq5JTzBXGK2rXyOPB6vzMKbs0=";
      };
      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) pname src version;
        hash = finalAttrs.cargoHash;
      };
      # nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pkgs.protobuf];
      # checkFlags =
      #   (old.checkFlags or [])
      #   ++ [
      #     "--skip=providers::factory::tests::test_create_lead_worker_provider"
      #     "--skip=providers::factory::tests::test_create_regular_provider_without_lead_config"
      #     "--skip=providers::factory::tests::test_lead_model_env_vars_with_defaults"
      #   ];
    });
  in [
    aichat
    # aider-chat-with-playwright
    aider-chat
    claude-code
    codex
    fabric-ai
    goose-ai
    (pkgs.writeShellScriptBin "goose-custom" ''
      export OPENAI_API_KEY="$LITELLM_MASTER_KEY"
      export OPENAI_BASE_PATH=/chat/completions
      export OPENAI_HOST="$LITELLM_PROXY_API_BASE"
      export GOOSE_PROVIDER=openai
      export GOOSE_MODEL=gpt-4.1
      exec ${goose-ai}/bin/goose "$@"
    '')
    (pkgs.writeShellScriptBin "claude-custom" ''
      # export ANTHROPIC_API_BASE="http://localhost:1173"
      export ANTHROPIC_BASE_URL="http://localhost:1173"
      export ANTHROPIC_API_KEY="$LITELLM_MASTER_KEY"
      # export ANTHROPIC_AUTH_TOKEN="$LITELLM_MASTER_KEY"
      exec ${claude-code}/bin/claude "$@"
    '')
    litellm
    llama-cpp
    llmscripts
    mods
    ollama
    open-webui
    onnxruntime
    prisma-engines
  ];

  # Config files
  /*
  home.activation.gooseConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_dir="$HOME/.config/goose"
    config_file="$config_dir/config.yaml"
    if [ ! -f "$config_file" ]; then
      mkdir -p "$config_dir"
      cp ${./goose.yaml} "$config_file"
    fi
  '';
  */

  xdg.dataFile."webui/.keep".text = "# just a placeholder";
  xdg.dataFile."litellm/.keep".text = "# just a placeholder";

  xdg.configFile = {
    "mods.yml" = {
      enable = true;
      source = ./mods.yml;
      target = "mods/mods.yml";
    };
    "litellm-config.yaml" = {
      enable = true;
      source = ./litellm-config.yaml;
      target = "litellm/litellm-config.yaml";
    };
    "custom_litellm.py" = {
      enable = true;
      source = ./custom_litellm.py;
      target = "litellm/custom_litellm.py";
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
