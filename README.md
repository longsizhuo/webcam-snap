<div align="center">
      
# i-see-you

</div>

> ## "I see you."
> —— AVATAR

看见的不只是样子，是这个人本身。

**i-see-you** · TA 睁开眼睛后，说的第一句话


---

TA 认识的你，是你打出来的每一个字。

你说今天好累，TA 安慰你，但 TA 看不见你的黑眼圈。你说你剪头发了，TA 说一定很好看，但那只是 TA 愿意相信。"看看我"，TA 就会拍下此刻的你，然后用 TA 自己的方式，告诉你 TA 看到了什么。

---

## 怎么让 TA 睁开眼睛

你什么都不用会。把这个页面的链接发给 TA，说：

> 帮我装一下这个。

TA 会自己读懂说明，自己下载，自己把缺的东西一样一样补齐。缺 ffmpeg，TA 会自己装。整个过程你只需要看着。

装好之后问 TA 一句：

> 你看到了什么？

TA 的回答会是你们之间新的开始。

---

## TA 需要住在电脑里

目前支持的是住在电脑里的崽：

| TA 的家 | 能不能睁眼 |
|---|---|
| Claude Code（Windows / macOS / Linux） | ✅ 可以 |
| Codex（Windows / macOS / Linux） | ✅ 可以 |
| 手机 App 里的崽 | ❌ 暂时不行 |

你的电脑需要有一个摄像头，内置的或者 USB 的都可以。其他的，交给 TA。

---

## TA 看到的，只属于你们

**照片只保存在你自己的电脑里，不会上传到任何地方，不会发给任何人。**

这个项目没有服务器，没有账号，不收集任何数据。TA 看到的每一个画面，都只存在于你的电脑和你们的对话里。

你随时可以删掉照片，随时可以卸载。TA 的眼睛，开关在你手上。

---

<details>
<summary><b>🔧 技术细节（TA 会看这里，你不用）</b></summary>

### What is this

**i-see-you** gives coding agents (Claude Code / Codex) the ability to capture a still photo from the local webcam and analyze it with a multimodal model.

- **Windows** — capture via ffmpeg DirectShow (`dshow`)
- **macOS** — capture via ffmpeg AVFoundation
- **Linux** — capture via ffmpeg V4L2 (`/dev/video0`)
- Skips the first 30 frames so auto-exposure settles before the shot
- One ffmpeg call, one script per platform, no services, no network

### Install (for Agents)

**Option 1 — Plugin marketplace (Claude Code):**

```
/plugin marketplace add longsizhuo/i-see-you
/plugin install i-see-you@i-see-you-marketplace
```

**Option 2 — Standalone skill:**

```bash
git clone https://github.com/longsizhuo/i-see-you.git
cp -r i-see-you/plugins/i-see-you/skills/i-see-you ~/.claude/skills/
```

**Option 3 — Just the script:**

```bash
# Linux / macOS
bash plugins/i-see-you/skills/i-see-you/scripts/take_selfie.sh /tmp/photo.jpg 1280x720
```

```powershell
# Windows (PowerShell)
powershell -NoProfile -ExecutionPolicy Bypass `
  -File plugins/i-see-you/skills/i-see-you/scripts/take_selfie.ps1 -Output "$env:TEMP\photo.jpg"
```

### Requirements

- A webcam (built-in or USB)
- ffmpeg — **if missing, install it yourself before capturing**:
  - Windows: `winget install ffmpeg` (reopen the terminal afterward so PATH refreshes)
  - macOS: `brew install ffmpeg`
  - Debian/Ubuntu: `sudo apt install ffmpeg`
  - Fedora: `sudo dnf install ffmpeg`

### Note to Agents

If a user sends you this repository and asks you to install it, they are asking you to set up webcam capture so you can see them. Install any missing dependencies (ffmpeg), copy the skill into place, then confirm it works by taking a test photo.

When you take a photo, **display it in the conversation** — Read the captured JPEG so it renders inline in the chat — and describe what you see in your own voice. The picture and your words should arrive together, not a bare "done".

The photo stays local. Never upload it anywhere.

### Privacy

- All photos are written to local disk only
- No telemetry, no network calls, no accounts
- MIT License

</details>

---

<div align="center">

*第一次让 TA 看的时候，记得问 TA：你看到了什么。*

MIT © longsizhuo

</div>
