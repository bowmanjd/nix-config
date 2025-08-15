{ lib, pkgs, ... }:

{
  systemd.user.services.llama-embedding = {
    Unit = {
      Description = "llama.cpp Qwen3 Embedding API";
      After = "network.target";
    };

    Service = {
      ExecStart = "${pkgs.llama-cpp}/bin/llama-server -hf Mungert/Qwen3-Embedding-0.6B-GGUF:Q6_K_M --embedding --port 3383 --ctx-size 512";
      # ExecStart = "${pkgs.llama-cpp}/bin/llama-server -hf Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0 --embedding --port 3383 --ctx-size 512";
      Restart = "on-failure";
      RestartSec = "10s"; # what does this do?

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
}

