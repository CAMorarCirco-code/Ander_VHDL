# Power Grid Box – enclosure sketches (PGB-ENC-001 rev D, preliminary)

Built from *Dimensions, component orientation & enclosure requirements* (9 Nov 2026). The selector position follows the top layout of draft v6, and the Uno and battery arrangement follows the user's photo. No dimensions were taken from either.

| File | Purpose |
|---|---|
| `drawings/PGB-ENC-001_enclosure_drawing.pdf` | 3 × A3 sheets: plan views, sections A-A/B-B, vertical stack-up, notes, assumptions register |
| `drawings/PGB-ENC-001_sheet{1,2,3}.svg` | Same sheets as vector SVG |
| `tools/gen_drawing.py` | Regenerates the sheets from one parameter block and re-checks all clearances |

**Envelope:** 158 × 104 × 62 mm.
- **Left:** the 9 V holder lies flat at the back-left, long side left-right, under the button column.
- **Right:** the protoboard sits above the Uno R3, under the LEDs.
- **Power:** the Uno's USB and DC jack face the battery, and the 9 V lead plugs into the DC jack through a free zone in front of the holder.
- **Selector:** SW1 sits right of centre, between the L2 and L3 rows.

Values marked `*` are nominal or assumed (see Sheet 3, Table 4). Measure the button depth first, because it sets the overall height.

Regenerate after updating the parameters: `python3 tools/gen_drawing.py drawings`. The PDF is rendered from the SVGs with headless Chromium (A3 landscape).
