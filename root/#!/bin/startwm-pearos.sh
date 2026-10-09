#!/bin/bash
export DISPLAY=:1
export LANG=en_US.UTF-8

exec dbus-launch --exit-with-session pear-session
