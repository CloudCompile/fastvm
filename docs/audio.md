# FastVM audio

FastVM follows the same audio model as BlobeVM: it leaves PulseAudio and the
browser audio bridge to `ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy`.
Desktop launchers do not replace the base image's PulseAudio configuration,
start a second daemon, force a socket, or create synthetic devices.

Verify both directions in a running container:

```text
/fastvm-scripts/audio-self-test.sh
```

The test discovers the base image's default sink and source, plays a short
tone, and captures samples. This validates the in-container PulseAudio path;
actual browser microphone data still requires browser permission and a live
KasmVNC session.