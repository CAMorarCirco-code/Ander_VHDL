# Power Grid Box – 3D printed enclosure (PGB-ENC-001 rev C, preliminary)

Built from *Dimensions, component orientation & enclosure requirements* (9 Nov 2026).

| File | Purpose |
|---|---|
| `drawings/PGB-ENC-001_enclosure_drawing.pdf` | 3 × A3 drawing set: plan views, sections A-A/B-B, stack-up, isometric, notes, assumptions register |
| `drawings/PGB-ENC-001_sheet{1,2,3}.svg` | Same sheets as vector SVG |
| `cad/power_grid_box_enclosure.scad` | Parametric OpenSCAD model (`part="base"`, `"lid"`, `"assembly"`) |
| `cad/stl/pgb_base.stl`, `pgb_lid.stl` | STL exports at the current parameters (lid is oriented face-down for printing) |
| `tools/gen_drawing.py` | Regenerates the SVG sheets and checks the clearances |

**Envelope:** 160 × 104 × 62 mm (the old 200 × 120 × 75 mm envelope is replaced).
Battery bay is on the left under the 3 buttons. The protoboard sits above the Uno R3 on the right under the 3 LEDs. As in the user photo, the Uno's USB and DC jack face left towards the battery, and the 9 V lead plugs into the DC jack (a 38 mm plug/cable zone is kept free). The selector SW1 sits right of centre, midway between the L2 and L3 rows, following the top layout of draft v6 (position only). There is no USB opening.

Values marked `*` are nominal or assumed because the spec lists them as TBC (see Sheet 3, Table 4).
The **button depth below the panel (30 mm assumed)** sets the overall height. Measure it first.

Regenerate after changing parameters:
```
python3 tools/gen_drawing.py drawings
openscad -D 'part="base"' -o cad/stl/pgb_base.stl cad/power_grid_box_enclosure.scad
openscad -D 'part="lid"'  -o cad/stl/pgb_lid.stl  cad/power_grid_box_enclosure.scad
```
The PDF is rendered from the SVGs with headless Chromium (A3 landscape).
