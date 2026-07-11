# webcam-snap (skill)

A skill that captures a still photo from the machine's local webcam with `ffmpeg`, so the agent can see the physical environment. Cross-platform: Linux (V4L2), macOS (AVFoundation), Windows (DirectShow).

## Standalone install (without the plugin system)

Copy this directory to your personal skills folder:

```bash
cp -r webcam-snap ~/.claude/skills/
```

The result must be `~/.claude/skills/webcam-snap/SKILL.md`. Restart Claude Code (skills load at session start).

## Files

- `SKILL.md` — the skill definition (trigger conditions + capture instructions)
- `scripts/take_selfie.sh` — Linux/macOS capture helper (exposure warm-up, device fallback)
- `scripts/take_selfie.ps1` — Windows capture helper (DirectShow, device auto-detect)

## Trigger

Ask to "take a photo", "selfie", "拍照", "看看现在的环境", etc. See [../../../../docs/HOWTOUSE.md](../../../../docs/HOWTOUSE.md).

## License

MIT © longsizhuo
