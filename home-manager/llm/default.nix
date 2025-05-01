{
  lib,
  pkgs,
  ...
}: {
  systemd.user.services.litellm = {
    Unit = {
      Description = "LiteLLM API server";
      After = ["network.target"];
    };

    Service = {
      ExecStart = "${pkgs.litellm}/bin/litellm --port 1173 --config ${pkgs.writeText "litellm-config.yaml" (builtins.toJSON {
        model_list = [
          {
            model_name = "ollama/gemma3:4b";
            litellm_params = {
              model = "ollama/gemma3:4b";
              api_base = "http://localhost:11434";
            };
          }
          {
            model_name = "claude-3-7-sonnet";
            litellm_params = {
              model = "anthropic/claude-3-sonnet-20240229";
            };
          }
        ];
        router_settings = {
          routing_strategy = "simple-shuffle";
        };
      })}";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

  home.packages = with pkgs; [
    aichat
    aider-chat-with-playwright
    fabric-ai
    goose-cli
    mods
  ];
}
