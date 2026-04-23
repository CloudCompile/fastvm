#!/bin/bash
# Start i3 window manager

# Set up environment
export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=i3
export XDG_CURRENT_DESKTOP=i3

# Start i3
exec i3
