---
name: webcam-snap
description: Take a still photo from a local V4L2 webcam (/dev/video0) with ffmpeg, then read/analyze or send the image. Trigger when the user asks to "take a photo", "take a picture", "selfie", "拍照", "自拍", "看看现在的环境/房间", or when Claude needs to visually observe the physical environment through the machine's camera. Linux-only; requires ffmpeg and a V4L2 device.
---

# Webcam Snap

Capture a single frame from the machine's local webcam, then either **read** the JPEG (multimodal models can see it directly) or **send** it to the user.

## Capture (primary — no path dependency)

Run this one-liner. It skips the first 30 frames so auto-exposure settles before the frame is grabbed:

```bash
ffmpeg -y -loglevel error -f v4l2 -video_size 1280x720 -i /dev/video0 \
       -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 -f image2 /tmp/selfie.jpg
```

Lower-resolution / fastest fallback:

```bash
ffmpeg -y -f v4l2 -i /dev/video0 -frames:v 1 -f image2 /tmp/selfie.jpg
```

### Helper script (optional)

This skill also ships `scripts/take_selfie.sh`, which adds the exposure warm-up, device auto-fallback (tries the next `/dev/video*` if `video0` is missing), and dependency checks. Invoke it from the skill directory:

```bash
bash scripts/take_selfie.sh /tmp/selfie.jpg 1280x720
```

Arguments are optional: `take_selfie.sh [output_path] [resolution]` (defaults: `/tmp/selfie_<timestamp>.jpg`, `640x480`).

## After capture

- **To analyze the scene**: use the Read tool on the JPEG — a multimodal model sees the image directly, no extra script needed.
- **To hand it to the user**: send the JPEG through whatever the host supports (e.g. Claude Code's file-send / `SendUserFile`).

## Environment

- **Device**: `/dev/video0` (machines often also expose `/dev/video1`)
- **Dependency**: `ffmpeg` (`sudo apt install ffmpeg` on Debian/Ubuntu)
- **Permissions**: the user must be able to read the video device. If not, add them to the `video` group.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Cannot open video device` / permission denied | `sudo usermod -a -G video $USER` (re-login), or temporarily `sudo chmod 666 /dev/video0` |
| `/dev/video0` not found | `ls -la /dev/video*` and use another index; the helper script auto-falls-back to the first available device |
| Frame is black or over-exposed | raise the warm-up count (e.g. `gte(n,60)`) or bump the resolution |
| List devices / formats | `v4l2-ctl --list-devices`, `ffmpeg -f v4l2 -list_formats all -i /dev/video0` |

## Scope

- **In scope**: local USB / built-in webcams exposed as V4L2 (`/dev/video*`) on Linux.
- **Out of scope**: network/IP cameras (RTSP/ONVIF), macOS/Windows capture, video recording. These need different tooling and are intentionally not handled here.
