# i-see-you (plugin)

Adds the **i-see-you** skill: capture a still photo from the machine's local webcam with `ffmpeg`, then let the agent read and analyze it or send it to the user. Cross-platform — Linux (V4L2), macOS (AVFoundation), Windows (DirectShow).

## Install

```
/plugin marketplace add longsizhuo/i-see-you
/plugin install i-see-you@i-see-you-marketplace
```

## What it provides

| Component | Name | Purpose |
|-----------|------|---------|
| Skill | `i-see-you` | Triggers on "看看我" / "take a photo" / "selfie" / "拍照"; captures a frame and reads it |

## Requirements

A local webcam and `ffmpeg` installed (Linux/macOS/Windows). See the [top-level README](../../README.md) and [docs/HOWTOUSE.md](../../docs/HOWTOUSE.md) for details and troubleshooting.

## License

MIT © longsizhuo
