# 📸 webcam-snap for Agents

Give agents eyes. **webcam-snap** lets an agent capture a still photo from your machine's local webcam using `ffmpeg`, then read the image with a multimodal model to describe or analyze what it sees — or hand the photo back to you.

Ask *"take a selfie"*, *"拍张照片看看现在的环境"*, or *"what's in front of the camera?"* and the agent runs the capture and looks at the result.

```
you   ▸ 拍张照片看看房间乱不乱
agent ▸ (captures selfie.jpg from the webcam, reads it)
      ▸ 拍到了：桌面上有一个马克杯和几本书，椅子上搭着一件外套，整体还算整齐……
```

- 🖥 **Cross-platform** — Linux (V4L2), macOS (AVFoundation), Windows (DirectShow), same skill
- 🎛 **Exposure-aware** — skips the first 30 frames so auto-exposure settles before the shot
- 🧩 **Three install formats** — standalone skill, plugin, or plugin marketplace
- 🪶 **Tiny & dependency-light** — one `ffmpeg` call, no services; bash on Linux/macOS, PowerShell on Windows

---

## Requirements

- A local webcam (built-in or USB)
- **ffmpeg** on `PATH`:
  - Linux: `sudo apt install ffmpeg` (Debian/Ubuntu) / `sudo dnf install ffmpeg` (Fedora)
  - macOS: `brew install ffmpeg`
  - Windows: `winget install --id Gyan.FFmpeg` (or `scoop install ffmpeg` / `choco install ffmpeg`), then reopen the terminal
- Camera permission for your terminal/agent (see [Troubleshooting](docs/HOWTOUSE.md#troubleshooting))
- An agent host (for skill/plugin use) — the raw `ffmpeg` command works anywhere

---

## Install

Pick the method that fits how you use your agent. Full walkthrough in **[docs/HOWTOUSE.md](docs/HOWTOUSE.md)**.

### 1. As a plugin marketplace (recommended)

In an interactive session:

```
/plugin marketplace add longsizhuo/webcam-snap
/plugin install webcam-snap@webcam-snap-marketplace
```

### 2. As a standalone skill (no plugin system)

Copy the skill folder into your personal skills directory (`~/.claude/skills/` by default):

```bash
git clone https://github.com/longsizhuo/webcam-snap.git
cp -r webcam-snap/plugins/webcam-snap/skills/webcam-snap ~/.claude/skills/
```

On Windows PowerShell:

```powershell
git clone https://github.com/longsizhuo/webcam-snap.git
Copy-Item -Recurse webcam-snap/plugins/webcam-snap/skills/webcam-snap "$env:USERPROFILE\.claude\skills\"
```

Restart the session — the `webcam-snap` skill is now available.

### 3. Just the script (no agent at all)

```bash
# Linux / macOS
bash plugins/webcam-snap/skills/webcam-snap/scripts/take_selfie.sh /tmp/selfie.jpg 1280x720
```

```powershell
# Windows
powershell -NoProfile -ExecutionPolicy Bypass `
  -File plugins/webcam-snap/skills/webcam-snap/scripts/take_selfie.ps1 -Output "$env:TEMP\selfie.jpg"
```

---

## How it works

1. A skill (`SKILL.md`) tells the agent *when* to reach for the camera and *how* to capture a frame on each OS.
2. Capture is a single `ffmpeg` grab that discards the first 30 frames (auto-exposure warm-up) and writes one JPEG. The only per-OS difference is the backend flag and how the device is named:

   | OS | Backend | Device |
   |----|---------|--------|
   | Linux | `-f v4l2` | `/dev/video0` |
   | macOS | `-f avfoundation` | index `0` |
   | Windows | `-f dshow` | `video="Integrated Camera"` |

3. The agent reads the JPEG directly — modern multimodal models "see" the image without any extra OCR/vision service — and describes or acts on it, or sends it to you.

```bash
# Linux example
ffmpeg -y -f v4l2 -video_size 1280x720 -i /dev/video0 \
       -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 -f image2 /tmp/selfie.jpg
```

---

## Repository layout

```
webcam-snap/
├── .claude-plugin/
│   └── marketplace.json              # marketplace manifest (method 1)
├── plugins/
│   └── webcam-snap/                  # the plugin
│       ├── .claude-plugin/
│       │   └── plugin.json           # plugin manifest
│       ├── skills/
│       │   └── webcam-snap/          # the skill (method 2 — copy this dir)
│       │       ├── SKILL.md
│       │       ├── README.md
│       │       └── scripts/
│       │           ├── take_selfie.sh    # Linux / macOS
│       │           └── take_selfie.ps1   # Windows
│       └── README.md
├── docs/
│   └── HOWTOUSE.md                   # detailed usage + troubleshooting
├── LICENSE                           # MIT
└── README.md
```

---

## Scope & non-goals

**In scope:** local USB / built-in webcams on Linux (V4L2), macOS (AVFoundation), and Windows (DirectShow).

**Out of scope (by design):** network/IP cameras (RTSP/ONVIF) and video recording. These need different tooling; keeping the skill to one job keeps it reliable.

---

## License

[MIT](LICENSE) © longsizhuo
