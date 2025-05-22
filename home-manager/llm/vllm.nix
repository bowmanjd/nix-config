{
  lib,
  pkgs,
  environment ? "home",
  ...
}: let
  # Script to launch vLLM server in CPU-only mode
  vllm-serve-script = pkgs.writeShellScriptBin "vllm-serve-rerank" ''
    exec ${pkgs.stable.vllm}/bin/vllm serve \
      BAAI/bge-reranker-base \
      --host 127.0.0.1 \
      --port 5113 \
      --tensor-parallel-size 1 \
      --max-model-len 512 \
      --dtype half \
      --disable-log-stats \
      --load-format safetensors \
      --enforce-eager
  '';
in {
  # User systemd service definition
  systemd.user.services.vllm-rerank = {
    Unit = {
      Description = "vLLM Rerank API Server";
      After = "network.target";
    };

    Service = {
      Type = "simple";
      ExecStart = "${vllm-serve-script}/bin/vllm-serve-rerank";
      Restart = "on-failure";
      RestartSec = "10s";

      # Add timeout to ensure service restarts if hanging
      TimeoutStartSec = "300s";
      TimeoutStopSec = "90s";

      # Idle resource control
      MemoryLow = "0";
      CPUSchedulingPolicy = "idle";
      Nice = 19; # Lowest CPU priority when system is busy
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7; # Lowest IO priority
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Add the script to the user's path
  home.packages = with pkgs.stable; [
    vllm
    vllm-serve-script
  ];
}
