# webcam-snap (plugin)

Adds the **webcam-snap** skill: capture a still photo from the machine's local webcam with `ffmpeg`, then let the agent read and analyze it or send it to the user. Cross-platform — Linux (V4L2), macOS (AVFoundation), Windows (DirectShow).

## Install

```
/plugin marketplace add longsizhuo/claude-webcam-snap
/plugin install webcam-snap@webcam-snap-marketplace
```

## What it provides

| Component | Name | Purpose |
|-----------|------|---------|
| Skill | `webcam-snap` | Triggers on "take a photo" / "selfie" / "拍照"; captures a frame and reads it |

## Requirements

A local webcam and `ffmpeg` installed (Linux/macOS/Windows). See the [top-level README](../../README.md) and [docs/HOWTOUSE.md](../../docs/HOWTOUSE.md) for details and troubleshooting.

## License

MIT © longsizhuo
