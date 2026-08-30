# Walkthrough — the `chat` screen (Figma prototype, 2026-08-30)

Frames captured from the Figma file in `docs/figma.yml` (page `chat`, 1280 wide) and stitched
locally with ffmpeg per the `figma-walkthrough-video` skill; the Figma file stays private.

| File | What |
|---|---|
| `01-empty.png` … `04-failed.png` | the four states (nodes `5:51`, `5:93`, `4:11`, `5:143`) |
| `rita-chat-states.mp4` | crossfade slideshow of the four states, 1440x900, 8.8 s |
| `rita-chat-flow.mp4` | prototype flow empty → Send → loading → happy, tap hotspots, 6 s |
| `boxes.txt` | hotspot boxes (frame-relative `x:y:w:h`) used for the flow video |

No captions: this machine's ffmpeg has no drawtext and no PIL. Regenerate with the skill's
`references/build.sh` / `hotspots.sh` from the PNGs.
