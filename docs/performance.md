# Performance Notes

## Particle Animation

The particle sphere (800 particles, 15fps Canvas rendering) uses ~10-15% CPU in Activity Monitor with "High" energy impact when the panel or floating widget is open.

### Why this is fine

- Activity Monitor shows CPU % **per core**, not total CPU.
- On Apple Silicon (8-10 cores), 15% per core ≈ **1.5% of total CPU**.
- "High" energy impact means the app prevents CPU sleep due to continuous rendering — this is normal for any app with live animation (e.g., clock apps, visualizers).
- When the panel/floating widget is closed, CPU drops to **~0%** and energy impact is **Low** — the content view is destroyed on close.

### Design decision

The floating widget is meant to stay open during entire focus sessions so users can watch particles fill as they work. Smooth rotation at 15fps is the minimum acceptable frame rate. We intentionally chose visual quality over energy efficiency here.

### What we tried

| Approach | CPU | Visual Quality | Outcome |
|----------|-----|---------------|---------|
| 60fps, 2500 particles | ~50% | Excellent | Way too heavy |
| 15fps, 2500 particles | ~25% | Great | Still too heavy |
| 15fps, 800 particles | ~10-15% | Good | **Current — acceptable** |
| 5fps, 800 particles | ~5% | Choppy | Too janky |
| 1fps CGImage snapshot | ~1% | No rotation | Defeats the purpose |
