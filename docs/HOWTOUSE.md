# How to use webcam-snap

A step-by-step guide to installing, triggering, and troubleshooting the **webcam-snap** skill/plugin on Linux, macOS, and Windows.

---

## 1. Check your prerequisites

**Linux**

```bash
ls -la /dev/video*                            # expect /dev/video0 (maybe video1, ...)
command -v ffmpeg || sudo apt install ffmpeg  # install if missing
ffmpeg -f v4l2 -list_formats all -i /dev/video0   # no "permission denied"?
```

**macOS**

```bash
command -v ffmpeg || brew install ffmpeg
ffmpeg -f avfoundation -list_devices true -i ""   # lists cameras with [index]
```

**Windows** (PowerShell)

```powershell
Get-Command ffmpeg -ErrorAction SilentlyContinue   # or: winget install --id Gyan.FFmpeg
ffmpeg -f dshow -list_devices true -i dummy        # lists cameras by "name"
```

If listing/formats fails with a permission error, jump to [Troubleshooting](#troubleshooting).

---

## 2. Install

### Method 1 — Plugin marketplace (recommended)

In an **interactive** session (not a one-shot/headless run):

```
/plugin marketplace add longsizhuo/webcam-snap
/plugin install webcam-snap@webcam-snap-marketplace
```

`/plugin marketplace add` registers this repo as a source; `/plugin install` pulls the `webcam-snap` plugin from it. Verify with `/plugin` (you should see webcam-snap listed and enabled).

### Method 2 — Standalone skill

Drop the skill straight into your personal skills directory:

```bash
# Linux / macOS
git clone https://github.com/longsizhuo/webcam-snap.git
cp -r webcam-snap/plugins/webcam-snap/skills/webcam-snap ~/.claude/skills/
```

```powershell
# Windows
git clone https://github.com/longsizhuo/webcam-snap.git
Copy-Item -Recurse webcam-snap/plugins/webcam-snap/skills/webcam-snap "$env:USERPROFILE\.claude\skills\"
```

The final path must be `.../.claude/skills/webcam-snap/SKILL.md`. Skills are loaded at session start, so **start a new session** afterward.

### Method 3 — Script only

No agent needed — the capture script stands on its own:

```bash
# Linux / macOS
bash plugins/webcam-snap/skills/webcam-snap/scripts/take_selfie.sh ~/Pictures/snap.jpg 1280x720
```

```powershell
# Windows
powershell -NoProfile -ExecutionPolicy Bypass `
  -File plugins/webcam-snap/skills/webcam-snap/scripts/take_selfie.ps1 -Output "$env:USERPROFILE\Pictures\snap.jpg"
```

---

## 3. Trigger it

Skills activate automatically from natural language. Any of these will invoke webcam-snap:

- "take a photo" / "take a selfie" / "take a picture"
- "拍张照片" / "自拍一张" / "看看现在的环境" / "看看房间"
- "what does the camera see right now?"
- "拍张照片并分析" (the agent captures **and** describes the frame)

The agent will run the capture, then either describe what it sees or send you the JPEG.

### Manually, inside a session

You can also just ask the agent to run the capture command for your OS:

```bash
# Linux
ffmpeg -y -loglevel error -f v4l2 -video_size 1280x720 -i /dev/video0 \
       -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 -f image2 /tmp/selfie.jpg

# macOS (index from -list_devices)
ffmpeg -y -loglevel error -f avfoundation -framerate 30 -video_size 1280x720 -i "0" \
       -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 -f image2 /tmp/selfie.jpg
```

```powershell
# Windows (name from -list_devices)
ffmpeg -y -loglevel error -f dshow -video_size 1280x720 -i video="Integrated Camera" `
       -vf "select=gte(n\,30)" -frames:v 1 -fps_mode passthrough -f image2 "$env:TEMP\selfie.jpg"
```

…then ask it to read the resulting JPEG.

---

## 4. The capture scripts

**Linux / macOS** — `scripts/take_selfie.sh [output_path] [resolution]`

| Argument | Default | Example |
|----------|---------|---------|
| `output_path` | `$TMPDIR/selfie_<timestamp>.jpg` | `~/Pictures/room.jpg` |
| `resolution` | `1280x720` | `640x480` |

It checks that `ffmpeg` exists, picks the backend by `uname` (V4L2 on Linux, AVFoundation on macOS), on Linux falls back to the first available `/dev/video*`, warms up auto-exposure (skips 30 frames), then writes one JPEG and prints the path + size. On macOS, override the camera with `CAMERA_INDEX=1 bash take_selfie.sh`.

**Windows** — `scripts/take_selfie.ps1 [-Output <path>] [-Resolution 1280x720] [-Device "name"]`

Auto-detects the first DirectShow video device (override with `-Device`), warms up auto-exposure, falls back to the device default resolution if the requested one is rejected, then prints the path + size.

---

## Troubleshooting

### `ffmpeg: command not found` / not recognized

```bash
sudo apt install ffmpeg      # Debian / Ubuntu
sudo dnf install ffmpeg      # Fedora
brew install ffmpeg          # macOS
```

```powershell
winget install --id Gyan.FFmpeg    # Windows — then reopen the terminal so PATH refreshes
```

### Permission denied (Linux) — `Cannot open video device`

Add yourself to the `video` group (preferred):

```bash
sudo usermod -a -G video $USER   # log out and back in
```

Or a quick temporary fix (resets on reboot / re-plug): `sudo chmod 666 /dev/video0`.

### Camera permission (macOS / Windows)

- macOS: System Settings → Privacy & Security → Camera → enable your terminal app. The first capture may trigger the prompt.
- Windows: Settings → Privacy & security → Camera → allow desktop apps to access the camera.

### The device doesn't exist / is busy

Close any app holding the camera (Zoom, Teams, the Camera app), then list devices:

```bash
v4l2-ctl --list-devices                         # Linux (name → /dev/videoN)
ffmpeg -f avfoundation -list_devices true -i ""  # macOS (index)
ffmpeg -f dshow -list_devices true -i dummy      # Windows (name)
```

On Linux pass the right `/dev/videoN`; on macOS pass the right index (`CAMERA_INDEX`); on Windows pass the right `-Device "Name"`.

### The photo is black, gray, or over-exposed

The camera needs longer to settle. Increase the warm-up frame count in the ffmpeg filter — change `gte(n\,30)` to `gte(n\,60)` — or raise the resolution so the driver initializes the full sensor.

### Requested resolution rejected

Omit `-video_size` (the helper scripts auto-fall-back to the device default), or query supported modes on Windows:

```powershell
ffmpeg -f dshow -list_options true -i video="Integrated Camera"
```

---

## Uninstall

- **Plugin**: `/plugin uninstall webcam-snap@webcam-snap-marketplace`
- **Standalone skill**: `rm -rf ~/.claude/skills/webcam-snap` (Windows: `Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills\webcam-snap"`)
