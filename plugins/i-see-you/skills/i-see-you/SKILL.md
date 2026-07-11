---
name: i-see-you
description: Take a still photo from the machine's local webcam with ffmpeg, then read/analyze or send the image. Cross-platform — Linux (V4L2), macOS (AVFoundation), Windows (DirectShow). Trigger when the user asks to "看看我", "take a photo", "take a picture", "selfie", "拍照", "自拍", "看看现在的环境/房间", or when the agent needs to visually observe the physical environment through the machine's camera. Requires ffmpeg and a local camera.
---

# i-see-you

Capture a single frame from the machine's local webcam via ffmpeg, then either **read** the JPEG (multimodal models can see it directly) or **send** it to the user.

The only per-OS difference is ffmpeg's capture backend and how a device is named:

| OS | Backend flag | Device reference |
|----|--------------|------------------|
| Linux | `-f v4l2` | path, e.g. `/dev/video0` |
| macOS | `-f avfoundation` | index, e.g. `0` |
| Windows | `-f dshow` | quoted name, e.g. `video="Integrated Camera"` |

## Capture (recommended — use the helper script)

Both helper scripts auto-detect the first camera, warm up auto-exposure (skip the first 30 frames), check for ffmpeg, and fall back to the device's default resolution if the requested one is rejected.

**Linux / macOS** (bash):

```bash
bash scripts/take_selfie.sh                       # -> $TMPDIR/selfie_<timestamp>.jpg @ 1280x720
bash scripts/take_selfie.sh /tmp/selfie.jpg 1280x720
```

**Windows** (PowerShell):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/take_selfie.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/take_selfie.ps1 `
    -Output "$env:TEMP\selfie.jpg" -Resolution 1280x720 -Device "Integrated Camera"
```

Each script prints a `文件路径:` line with the final path — Read that path to see the image.

## Capture (manual one-liners)

**Linux** — device is `/dev/video0`:

```bash
ffmpeg -y -loglevel error -f v4l2 -video_size 1280x720 -i /dev/video0 \
       -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 -f image2 /tmp/selfie.jpg
```

**macOS** — list devices, then capture by index (`0` = first video device). The terminal app needs camera permission the first time:

```bash
ffmpeg -f avfoundation -list_devices true -i ""          # find the [index] of your camera
ffmpeg -y -loglevel error -f avfoundation -framerate 30 -video_size 1280x720 -i "0" \
       -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 -f image2 /tmp/selfie.jpg
```

**Windows** — list devices, then capture by exact quoted name:

```powershell
ffmpeg -hide_banner -f dshow -list_devices true -i dummy   # find the "name" of your camera
ffmpeg -y -loglevel error -f dshow -video_size 1280x720 -i video="Integrated Camera" `
       -vf "select=gte(n\,30)" -frames:v 1 -fps_mode passthrough -f image2 "$env:TEMP\selfie.jpg"
```

## After capture

- **To analyze the scene**: use the Read tool on the JPEG — a multimodal model sees the image directly, no extra script needed.
- **To hand it to the user**: send the JPEG through whatever the host supports (e.g. the agent's file-send).

## Environment

- **Dependency**: `ffmpeg` on `PATH`.
  - Linux: `sudo apt install ffmpeg` (Debian/Ubuntu) / `sudo dnf install ffmpeg` (Fedora)
  - macOS: `brew install ffmpeg`
  - Windows: `winget install --id Gyan.FFmpeg` (or `scoop install ffmpeg` / `choco install ffmpeg`), then reopen the terminal so `PATH` refreshes.
- **Permissions**:
  - Linux: the user must be able to read the video device; if not, add them to the `video` group.
  - macOS: grant the terminal app camera access (System Settings → Privacy & Security → Camera).
  - Windows: allow desktop apps to use the camera (Settings → Privacy & security → Camera).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ffmpeg: command not found` / not recognized | Install ffmpeg (see above); on Windows reopen the terminal afterward. |
| Permission denied (Linux) | `sudo usermod -a -G video $USER` (re-login), or temporarily `sudo chmod 666 /dev/video0`. |
| No device / device busy | Close any app holding the camera (Zoom/Teams/Camera). List devices: Linux `v4l2-ctl --list-devices`; macOS `ffmpeg -f avfoundation -list_devices true -i ""`; Windows `ffmpeg -f dshow -list_devices true -i dummy`. |
| Requested resolution rejected | Omit `-video_size` (scripts auto-fall-back), or query modes (Windows: `ffmpeg -f dshow -list_options true -i video="NAME"`). |
| Frame is black or over-exposed | Raise the warm-up count in the filter (e.g. `gte(n\,60)`). |

## Scope

- **In scope**: local USB / built-in webcams on Linux (V4L2), macOS (AVFoundation), and Windows (DirectShow).
- **Out of scope**: network/IP cameras (RTSP/ONVIF) and video recording — different tooling, intentionally not handled here.
