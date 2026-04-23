#!/bin/bash
# Start XFCE4 desktop environment

# Set up environment
export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=xfce
export XDG_CURRENT_DESKTOP=XFCE

# Start XFCE4
exec startxfce4
