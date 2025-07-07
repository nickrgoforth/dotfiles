#!/bin/bash

# If Audacious is running, toggle the special workspace
if pgrep -x audacious > /dev/null; then
    hyprctl dispatch togglespecialworkspace audacious
else
    audacious &
fi

