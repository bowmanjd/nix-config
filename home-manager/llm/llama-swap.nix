{ lib, pkgs, ... }:

{
  systemd.user.services.llama-swap = {
    Unit = {
      Description = "llama-swap for managing llama.cpp models";
      After = "network.target";
    };

    Service = {
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap -config %E/llama-swap/llama-swap.yaml -listen 0.0.0.0:5349";
      Restart = "on-failure";
      RestartSec = "10s"; # what does this do?
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}


