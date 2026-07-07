# webcam-snap (skill)

A Claude Code skill that captures a still photo from a local V4L2 webcam (`/dev/video0`) with `ffmpeg`, so Claude can see the physical environment.

## Standalone install (without the plugin system)

Copy this directory to your personal skills folder:

```bash
cp -r webcam-snap ~/.claude/skills/
```

The result must be `~/.claude/skills/webcam-snap/SKILL.md`. Restart Claude Code (skills load at session start).

## Files

- `SKILL.md` — the skill definition (trigger conditions + capture instructions)
- `scripts/take_selfie.sh` — capture helper with exposure warm-up and device fallback

## Trigger

Ask to "take a photo", "selfie", "拍照", "看看现在的环境", etc. See [../../../../docs/HOWTOUSE.md](../../../../docs/HOWTOUSE.md).

## License

MIT © longsizhuo
