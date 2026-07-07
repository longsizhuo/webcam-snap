# webcam-snap (plugin)

Adds the **webcam-snap** skill to Claude Code: capture a still photo from a local V4L2 webcam (`/dev/video0`) with `ffmpeg`, then let Claude read and analyze it or send it to the user.

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

Linux with a V4L2 webcam and `ffmpeg` installed. See the [top-level README](../../README.md) and [docs/HOWTOUSE.md](../../docs/HOWTOUSE.md) for details and troubleshooting.

## License

MIT © longsizhuo
