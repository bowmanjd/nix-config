{
  lib,
  pkgs,
  ...
}: {
  systemd.user.services = let
    scriptpath = lib.makeBinPath [pkgs.llmscripts];
  in {
    "litellm" = {
      Unit = {
        Description = "LiteLLM API server";
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
    (python3.withPackages (ps:
      with ps; [
        hf-transfer
        hf-xet
        huggingface-hub
        litellm
        #langchain
        #llama-index-core
        #llama-index-program-openai
        #llama-index-llms-openai
        #llama-index-llms-openai-like
        #llama-index-llms-ollama
        #llama-index-embeddings-openai
        #llama-index-embeddings-ollama
        #llama-index-embeddings-huggingface
        #llama-index-readers-file
        #llama-index-readers-json
        #llama-index-readers-database
        #llama-index-vector-stores-qdrant
        #llama-index-vector-stores-chroma
      ]))
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
}
