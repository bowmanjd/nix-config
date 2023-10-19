#!/usr/bin/env python
"""Interactions with libinput touchpad."""
import json
import subprocess  # noqa: S404


def get_device() -> dict:
    """Get device id of touchpad.

    Returns:
        Device info dict
    """
    raw_inputs = subprocess.check_output(  # noqa: S603
        ["/usr/bin/swaymsg", "-r", "-t", "get_inputs"], text=True
    )
    inputs = json.loads(raw_inputs)
    touchpad = next(i for i in inputs if i["type"] == "touchpad")
    return touchpad


def dwt_enabled(device: dict) -> bool:
    """Test if touchpad disable-when-typing is enabled.

    Args:
        device: dictionary of device info

    Returns:
        True if dwt is enabled
    """
    return device["libinput"]["dwt"] == "enabled"


def dwt_toggle(device: dict) -> bool:
    """Toggle touchpad disable-when-typing.

    Args:
        device: dictionary of device info

    Returns:
        True if dwt is enabled
    """
    enabled = dwt_enabled(device)
    if enabled:
        flag = "disable"
    else:
        flag = "enable"
    subprocess.check_output(  # noqa: S603
        ["/usr/bin/swaymsg", "input", device["identifier"], "dwt", flag], text=True
    )
    return not enabled


def waybar(device: dict) -> str:
    """Output custom icon for waybar.

    Args:
        device: dictionary of device info

    Returns:
        relevant icon
    """
    enabled = dwt_enabled(device)
    if enabled:
        output = ""
    else:
        output = "ﳶ"
    return output


def run() -> None:
    """Command runner."""
    import sys

    device = get_device()

    if sys.argv[1] == "waybar":
        print(waybar(device))
    elif sys.argv[1] == "status":
        print(dwt_enabled(device))
    elif sys.argv[1] == "toggle":
        print(dwt_toggle(device))
    elif sys.argv[1] == "id":
        print(get_device())


if __name__ == "__main__":
    run()
