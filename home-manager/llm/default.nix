{
  lib,
  pkgs,
  ...
}: {
  systemd.user.services = let
    scriptpath = lib.makeBinPath [pkgs.basescripts];
  in {
    "litellm" = {
      Unit = {
        Description = "LiteLLM API server";
        After = ["network.target"];
      };

      Service = {
        ExecStart = "${pkgs.litellm}/bin/litellm --port 1173 --config ${./litellm-config.yaml}";
        EnvironmentFile = "%h/.config/llm/keys";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = ["default.target"];
      };
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
