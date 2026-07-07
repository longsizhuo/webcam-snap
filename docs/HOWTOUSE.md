# How to use webcam-snap

A step-by-step guide to installing, triggering, and troubleshooting the **webcam-snap** skill/plugin.

---

## 1. Check your prerequisites

```bash
# Is there a webcam?
ls -la /dev/video*        # expect /dev/video0 (maybe video1, ...)

# Is ffmpeg installed?
command -v ffmpeg || sudo apt install ffmpeg

# Can you read the device? (no "permission denied")
ffmpeg -f v4l2 -list_formats all -i /dev/video0
```

If the last command fails with a permission error, jump to [Troubleshooting](#troubleshooting).

---

## 2. Install

### Method 1 — Plugin marketplace (recommended for Claude Code users)

In an **interactive** Claude Code session (not a one-shot/headless run):

```
/plugin marketplace add longsizhuo/claude-webcam-snap
/plugin install webcam-snap@webcam-snap-marketplace
```

`/plugin marketplace add` registers this repo as a source; `/plugin install` pulls the `webcam-snap` plugin from it. Verify with `/plugin` (you should see webcam-snap listed and enabled).

### Method 2 — Standalone skill

If you don't use the plugin system, drop the skill straight into your personal skills directory:

```bash
git clone https://github.com/longsizhuo/claude-webcam-snap.git
cp -r claude-webcam-snap/plugins/webcam-snap/skills/webcam-snap ~/.claude/skills/
```

The final path must be `~/.claude/skills/webcam-snap/SKILL.md`. Skills are loaded at session start, so **start a new Claude Code session** afterward.

### Method 3 — Script only

No Claude needed — the capture script stands on its own:

```bash
bash plugins/webcam-snap/skills/webcam-snap/scripts/take_selfie.sh ~/Pictures/snap.jpg 1280x720
```

---

## 3. Trigger it

Skills activate automatically from natural language. Any of these will invoke webcam-snap:

- "take a photo" / "take a selfie" / "take a picture"
- "拍张照片" / "自拍一张" / "看看现在的环境" / "看看房间"
- "what does the camera see right now?"
- "拍张照片并分析" (Claude captures **and** describes the frame)

Claude will run the capture, then either describe what it sees or send you the JPEG.

### Manually, inside a session

You can also just ask Claude to run the capture command:

```bash
ffmpeg -y -loglevel error -f v4l2 -video_size 1280x720 -i /dev/video0 \
       -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 -f image2 /tmp/selfie.jpg
```

…then ask it to read `/tmp/selfie.jpg`.

---

## 4. The capture script

`scripts/take_selfie.sh [output_path] [resolution]`

| Argument | Default | Example |
|----------|---------|---------|
| `output_path` | `/tmp/selfie_<timestamp>.jpg` | `~/Pictures/room.jpg` |
| `resolution` | `640x480` | `1280x720` |

It checks that `ffmpeg` exists, falls back to the first available `/dev/video*` if `video0` is missing, warms up auto-exposure (skips 30 frames), then writes one JPEG and prints the file size.

---

## Troubleshooting

### `Cannot open video device` / permission denied

Your user isn't allowed to read the camera. Add yourself to the `video` group (preferred):

```bash
sudo usermod -a -G video $USER
# log out and back in for the group to take effect
```

Or, as a quick temporary fix (resets on reboot / device re-plug):

```bash
sudo chmod 666 /dev/video0
```

### `/dev/video0` does not exist

```bash
ls -la /dev/video*
```

Use whichever index exists (e.g. `/dev/video2`). The helper script already auto-selects the first available device.

### The photo is black, gray, or over-exposed

The camera needs longer to settle. Increase the warm-up frame count in the ffmpeg filter — change `gte(n\,30)` to `gte(n\,60)` — or raise the resolution so the driver initializes the full sensor.

### Multiple cameras / picking a specific one

```bash
v4l2-ctl --list-devices          # shows names → /dev/videoN mapping
```

Then pass the right device into ffmpeg (`-i /dev/videoN`).

### `ffmpeg: command not found`

```bash
sudo apt install ffmpeg      # Debian / Ubuntu
sudo dnf install ffmpeg      # Fedora
```

---

## Uninstall

- **Plugin**: `/plugin uninstall webcam-snap@webcam-snap-marketplace`
- **Standalone skill**: `rm -rf ~/.claude/skills/webcam-snap`
