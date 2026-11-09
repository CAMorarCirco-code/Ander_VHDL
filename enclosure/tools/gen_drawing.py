#!/usr/bin/env python3
"""Generate the PGB-ENC-001 enclosure drawing set (3 x A3 SVG sheets).

All geometry comes from the parameter block below, which is the same set of
numbers written into ../cad/power_grid_box_enclosure.scad.  Change a value
here, re-run, and the drawing and the CAD model stay consistent.

Model coordinates (mm): origin = external front-left-bottom corner,
X = left -> right, Y = front -> back, Z = bottom -> top.
"""
import math, os, sys

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "drawings")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- parameters
T_WALL, T_FLOOR, T_LID = 2.5, 2.5, 3.0
D = 104.0
BASE_H = 59.0                       # base tub height (lid sits on top)
H = BASE_H + T_LID                  # 62 overall
IX0, IY0 = T_WALL, T_WALL
IY1 = D - T_WALL
CY = D / 2                          # 52 - common centre line of all three columns

# battery zone (left)
BAY_B = (IX0, 43.5, 19.5, 84.5)     # planning reserve 41 x 65
HOLDER = (7.5, 38.5, 24.5, 79.5, T_FLOOR, T_FLOOR + 21.0)  # 31 x 55 x 21 (approx.)
RIB = (43.5, 45.5, IY0, IY1, T_FLOOR, T_FLOOR + 15.0)
NOTCH = (CY - 4, CY + 4, RIB[5] - 8, RIB[5])  # 8 x 8 wire notch in rib

# Arduino Uno R3 - orientation per user photo: USB-B and DC jack face LEFT (towards the
# battery); the battery holder lead ends in a DC barrel plug in the Uno jack.
PLUG_L = 30.0                       # * plug + strain relief length out of the jack
PLUG_D = 10.0                       # * plug body diameter
PLUG_BEND = 8.0                     # * room for the cable to turn 90 deg
CHAN = (RIB[1], RIB[1] + PLUG_L + PLUG_BEND)   # plug / cable zone (38 wide)
TIE_Y = (25.0, 79.0)                # cable-tie anchors in plug/cable zone
UNO_L, UNO_W = 68.58, 53.34
UNO_DCJ_PROJ, UNO_USB_PROJ = 1.8, 6.35
UNO_X0 = CHAN[1] + UNO_DCJ_PROJ
UNO = (UNO_X0, UNO_X0 + UNO_L, CY - UNO_W / 2, CY + UNO_W / 2)
UNO_Z0, UNO_T = 8.5, 1.6
UNO_COMP = 10.9                     # USB-B / DC jack height above PCB
UNO_HDR = 8.5                       # female header height above PCB
# Uno R3 reference holes, connector edge = local x0 (standard orientation, as in photo)
_uno_ref = [(13.97, 2.54), (15.24, 50.80), (66.04, 7.62), (66.04, 35.56)]
UNO_HOLES = [(round(UNO[0] + hx, 2), round(UNO[2] + hy, 2)) for hx, hy in _uno_ref]
UNO_USB = (UNO[0] - UNO_USB_PROJ, UNO[0] + 9.65, UNO[2] + 32.0, UNO[2] + 44.0)
UNO_DCJ = (UNO[0] - UNO_DCJ_PROJ, UNO[0] + 12.0, UNO[2] + 3.3, UNO[2] + 12.3)
JACK_Y = (UNO_DCJ[2] + UNO_DCJ[3]) / 2
JACK_Z = UNO_Z0 + UNO_T + 6.5       # * jack pin centre height
PLUG = (UNO_DCJ[0] - PLUG_L, UNO_DCJ[0], JACK_Y - PLUG_D / 2, JACK_Y + PLUG_D / 2, JACK_Z - PLUG_D / 2, JACK_Z + PLUG_D / 2)

# overall width follows from the Uno position (3 mm to the right wall)
W = float(math.ceil(UNO[1] + 3.0 + T_WALL))
IX1 = W - T_WALL
EBAY = (CHAN[0], IX1)

# protoboard above, on its own pillars; may overhang the plug zone (it sits above the plug)
PB_SPAN = (29 * 2.54, 32 * 2.54)     # 73.66 x 81.28 hole-centre span (from spec)
PB_EDGE = 2.54                       # ASSUMED edge margin (one pitch) each side
PB_W, PB_D = PB_SPAN[0] + 2 * PB_EDGE, PB_SPAN[1] + 2 * PB_EDGE  # 78.74 x 86.36
PB = (IX1 - 6.0 - PB_W, IX1 - 6.0, CY - PB_D / 2, CY + PB_D / 2)
PB_CX = (PB[0] + PB[1]) / 2
PB_Z0, PB_T = 25.0, 1.6
PB_COMP_MAX = 12.0                   # ASSUMED tallest part on protoboard
PB_PILLARS = [(PB[0] + 2.54, PB[2] + 2.54), (PB[1] - 2.54, PB[2] + 2.54),
              (PB[0] + 2.54, PB[3] - 2.54), (PB[1] - 2.54, PB[3] - 2.54)]

BOSSES = [(IX0 + 3, IY0 + 3), (IX1 - 3, IY0 + 3), (IX0 + 3, IY1 - 3), (IX1 - 3, IY1 - 3)]
FEET = [(12, 12), (W - 12, 12), (12, D - 12), (W - 12, D - 12)]

# top panel controls (x, y)
BTN_X = 23.0
LED_X = W - BTN_X                    # mirrors the button column
SEL_X = LED_X - 37.0
ROWS = (27.0, 52.0, 77.0)
# SW1 position follows the top layout of draft v6 (position only, no dimensions taken):
# right of centre, between the L2 and L3 rows.
SEL_Y = (ROWS[0] + ROWS[1]) / 2       # 39.5
SEL_KO = (SEL_X - 11.5, SEL_X + 11.5, SEL_Y - 11.5, SEL_Y + 11.5)  # protoboard keep-out under SW1
LED_KO = (LED_X - 7, LED_X + 7, ROWS[0] - 7, ROWS[2] + 7)
BTN_CUT, BTN_BEZEL, BTN_BODY, BTN_DEPTH = 16.2, 18.0, 16.0, 30.0   # depth ASSUMED
SEL_CUT, SEL_BODY, SEL_DEPTH = 6.2, (7.8, 13.0), 22.0             # depth ASSUMED
LED_CUT, LED_BEZEL, LED_DEPTH = 8.2, 10.0, 12.0                    # ASSUMED 8 mm holder
LIP_W, LIP_H, LIP_GAP = 1.5, 3.0, 0.3
SEL_KO_H = 5.0                       # max part height on protoboard under SW1
PILLAR_H = PB_Z0 - T_FLOOR

# derived checks ----------------------------------------------------------
gap_btn_batt = (BASE_H - BTN_DEPTH) - HOLDER[5]
gap_led_pb = (BASE_H - LED_DEPTH) - (PB_Z0 + PB_T + PB_COMP_MAX)
gap_pb_uno = PB_Z0 - (UNO_Z0 + UNO_T + max(UNO_COMP, UNO_HDR))
gap_sel_pb = (BASE_H - SEL_DEPTH) - (PB_Z0 + PB_T + SEL_KO_H)
gap_plug_pb = PB_Z0 - PLUG[5]
gap_plug_rib = PLUG[0] - RIB[1]
assert gap_sel_pb >= 5 and gap_btn_batt >= 5 and gap_led_pb >= 5 and gap_pb_uno >= 2.5 and gap_plug_pb >= 2.5 and gap_plug_rib >= PLUG_BEND, (gap_btn_batt, gap_led_pb, gap_pb_uno)
for bx, by in BOSSES:
    for cx, cy in [(PB[0], PB[2]), (PB[1], PB[2]), (PB[0], PB[3]), (PB[1], PB[3])]:
        assert math.hypot(bx - cx, by - cy) > 3.5 + 0.5

def f(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return s

# ---------------------------------------------------------------- svg kit
INK = "#111"
BLUE = "#1f4e9c"
PHANTOM = "#7a7a7a"
FONT = "font-family='Arial, Helvetica, sans-serif'"

class Sheet:
    def __init__(self, n, title):
        self.n, self.title, self.e = n, title, []
    def add(self, s): self.e.append(s)
    def line(self, x1, y1, x2, y2, w=0.35, c=INK, dash=None):
        d = f" stroke-dasharray='{dash}'" if dash else ""
        self.add(f"<line x1='{x1:.3f}' y1='{y1:.3f}' x2='{x2:.3f}' y2='{y2:.3f}' stroke='{c}' stroke-width='{w}'{d} stroke-linecap='round'/>")
    def rect(self, x, y, w, h, sw=0.5, c=INK, fill="none", dash=None, op=None, rx=0):
        d = f" stroke-dasharray='{dash}'" if dash else ""
        o = f" fill-opacity='{op}'" if op is not None else ""
        self.add(f"<rect x='{x:.3f}' y='{y:.3f}' width='{w:.3f}' height='{h:.3f}' rx='{rx}' fill='{fill}'{o} stroke='{c}' stroke-width='{sw}'{d}/>")
    def circle(self, x, y, r, sw=0.5, c=INK, fill="none", dash=None):
        d = f" stroke-dasharray='{dash}'" if dash else ""
        self.add(f"<circle cx='{x:.3f}' cy='{y:.3f}' r='{r:.3f}' fill='{fill}' stroke='{c}' stroke-width='{sw}'{d}/>")
    def poly(self, pts, sw=0.35, c=INK, fill="none", op=None, close=True):
        p = " ".join(f"{x:.3f},{y:.3f}" for x, y in pts)
        o = f" fill-opacity='{op}'" if op is not None else ""
        tag = "polygon" if close else "polyline"
        self.add(f"<{tag} points='{p}' fill='{fill}'{o} stroke='{c}' stroke-width='{sw}' stroke-linejoin='round'/>")
    def text(self, x, y, s, size=2.5, anchor="start", c=INK, weight="normal", rot=0, italic=False):
        r = f" transform='rotate({rot} {x:.3f} {y:.3f})'" if rot else ""
        it = " font-style='italic'" if italic else ""
        s = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        self.add(f"<text x='{x:.3f}' y='{y:.3f}' font-size='{size}' {FONT} text-anchor='{anchor}' fill='{c}' font-weight='{weight}'{it}{r}>{s}</text>")
    def arrow(self, x, y, ang, c=INK):
        L, Wd = 2.2, 0.7
        a = math.radians(ang)
        bx, by = x - L * math.cos(a), y - L * math.sin(a)
        px, py = -math.sin(a) * Wd, math.cos(a) * Wd
        self.poly([(x, y), (bx + px, by + py), (bx - px, by - py)], sw=0.1, c=c, fill=c)
    def hdim(self, x1, x2, yfeat1, yfeat2, ydim, label, c=INK, above=True):
        for x, yf in ((x1, yfeat1), (x2, yfeat2)):
            s = 1 if ydim > yf else -1
            self.line(x, yf + s * 1.0, x, ydim + s * 1.5, 0.18, c)
        self.line(x1, ydim, x2, ydim, 0.18, c)
        if abs(x2 - x1) > 6:
            self.arrow(x1, ydim, 180, c); self.arrow(x2, ydim, 0, c)
        else:
            self.arrow(x1, ydim, 0, c); self.arrow(x2, ydim, 180, c)
            self.line(x1 - 4, ydim, x1, ydim, 0.18, c); self.line(x2, ydim, x2 + 4, ydim, 0.18, c)
        tx = (x1 + x2) / 2 if abs(x2 - x1) > 9 else x2 + 5
        self.text(tx, ydim - 0.9 if above else ydim + 3.2, label, 2.5, "middle" if abs(x2 - x1) > 9 else "start", c)
    def vdim(self, y1, y2, xfeat1, xfeat2, xdim, label, c=INK):
        for y, xf in ((y1, xfeat1), (y2, xfeat2)):
            s = 1 if xdim > xf else -1
            self.line(xf + s * 1.0, y, xdim + s * 1.5, y, 0.18, c)
        self.line(xdim, y1, xdim, y2, 0.18, c)
        if abs(y2 - y1) > 6:
            self.arrow(xdim, min(y1, y2), -90, c); self.arrow(xdim, max(y1, y2), 90, c)
            self.text(xdim - 0.9, (y1 + y2) / 2, label, 2.5, "middle", c, rot=-90)
        else:
            lo, hi = min(y1, y2), max(y1, y2)
            self.arrow(xdim, lo, 90, c); self.arrow(xdim, hi, -90, c)
            self.line(xdim, lo - 4, xdim, lo, 0.18, c); self.line(xdim, hi, xdim, hi + 4, 0.18, c)
            self.text(xdim + 1.2, hi + 3.5, label, 2.3, "start", c)
    def leader(self, x, y, tx, ty, label, size=2.4, c=INK, anchor=None):
        self.line(x, y, tx, ty, 0.18, c)
        self.circle(x, y, 0.35, 0.1, c, c)
        a = anchor or ("start" if tx >= x else "end")
        self.line(tx, ty, tx + (8 if a == "start" else -8), ty, 0.18, c)
        self.text(tx + (1 if a == "start" else -1), ty - 0.8, label, size, a, c)
    def cl(self, x1, y1, x2, y2):
        self.line(x1, y1, x2, y2, 0.18, BLUE, "6 1.2 1 1.2")
    def cross(self, x, y, r):
        self.cl(x - r, y, x + r, y); self.cl(x, y - r, x, y + r)
    def label_view(self, x, y, title, sub):
        self.text(x, y, title, 3.8, "middle", weight="bold")
        self.line(x - len(title) * 1.15, y + 1.2, x + len(title) * 1.15, y + 1.2, 0.35)
        self.text(x, y + 5, sub, 2.4, "middle")

    def frame(self):
        self.add("<rect x='0' y='0' width='420' height='297' fill='#fff'/>")
        self.rect(10, 10, 400, 277, 0.7)
        for i in range(8):  # zone marks
            x = 10 + 50 * i + 25
            self.text(x, 8.6, str(i + 1), 2.4, "middle"); self.text(x, 291.2, str(i + 1), 2.4, "middle")
            if i: self.line(10 + 50 * i, 10, 10 + 50 * i, 7, 0.25); self.line(10 + 50 * i, 287, 10 + 50 * i, 290, 0.25)
        for j, ch in enumerate("ABCDEF"):
            y = 10 + 277 / 6 * j + 277 / 12
            self.text(5, y + 1, ch, 2.4, "middle"); self.text(415, y + 1, ch, 2.4, "middle")
        self.title_block()

    def title_block(self):
        x0, y0, w, h = 250, 252, 160, 35
        self.rect(x0, y0, w, h, 0.6)
        rows = [y0 + 8, y0 + 17, y0 + 26]
        for r in rows: self.line(x0, r, x0 + w, r, 0.3)
        for cx in (x0 + 60, x0 + 100):
            self.line(cx, y0 + 17, cx, y0 + h, 0.3)
        self.line(x0 + 130, y0 + 17, x0 + 130, y0 + 26, 0.3)
        self.line(x0 + 110, y0, x0 + 110, y0 + 17, 0.3)
        self.text(x0 + 2, y0 + 3, "PROJECT", 1.7, c="#555")
        self.text(x0 + 2, y0 + 7, "POWER GRID BOX - 3D PRINTED ENCLOSURE", 3.0, weight="bold")
        self.text(x0 + 112, y0 + 3, "DRAWING No.", 1.7, c="#555")
        self.text(x0 + 112, y0 + 7.2, "PGB-ENC-001", 3.4, weight="bold")
        self.text(x0 + 2, y0 + 11, "TITLE", 1.7, c="#555")
        self.text(x0 + 2, y0 + 15.5, self.title, 3.0, weight="bold")
        self.text(x0 + 112, y0 + 11, "SHEET", 1.7, c="#555")
        self.text(x0 + 112, y0 + 15.5, f"{self.n} OF 3", 3.0, weight="bold")
        cells = [(x0, "UNITS / SCALE", "mm   1:1 @ A3"), (x0 + 60, "REV", "C - PRELIM."),
                 (x0 + 100, "DATE", "2026-11-09"), (x0 + 130, "PROJECTION", "")]
        for cx, k, v in cells:
            self.text(cx + 2, y0 + 20, k, 1.7, c="#555"); self.text(cx + 2, y0 + 24.5, v, 2.6)
        # third-angle symbol
        px, py = x0 + 148, y0 + 22.6
        self.poly([(px - 5, py - 1.4), (px - 1, py - 2.6), (px - 1, py + 2.6), (px - 5, py + 1.4)], 0.3)
        self.circle(px + 4, py, 2.6, 0.3); self.circle(px + 4, py, 1.2, 0.3)
        self.text(x0 + 2, y0 + 29, "MATERIAL / PROCESS", 1.7, c="#555")
        self.text(x0 + 2, y0 + 33.4, "PETG, FDM, 0.2 mm layers", 2.4)
        self.text(x0 + 62, y0 + 29, "GENERAL TOL.", 1.7, c="#555")
        self.text(x0 + 62, y0 + 33.4, "+/-0.3 unless stated", 2.4)
        self.text(x0 + 102, y0 + 29, "STATUS", 1.7, c="#555")
        self.text(x0 + 102, y0 + 33.4, "DESIGN BRIEF - NOT FOR PRODUCTION", 2.4, weight="bold", c="#b00020")
        # left block: revision note
        self.rect(165, 252, 85, 35, 0.6)
        self.text(167, 256, "REVISION HISTORY", 1.9, c="#555", weight="bold")
        self.line(165, 258, 250, 258, 0.3)
        self.text(167, 262, "A  2026-11-09  First issue from spec (9 Nov 2026).", 2.2)
        self.text(167, 265.5, "B  2026-11-09  SW1 to layout-v6 position.", 2.2)
        self.text(167, 269, "C  2026-11-09  Uno + 9 V plug per photo. * = assumed.", 2.2)
        self.text(167, 276, "Drawn: Claude Code     Checked: ________", 2.2)
        self.text(167, 280.5, "Approved: ________", 2.2)

    def svg(self):
        body = "\n".join(self.e)
        return (f"<svg xmlns='http://www.w3.org/2000/svg' width='420mm' height='297mm' viewBox='0 0 420 297'>\n"
                f"<defs><pattern id='hatch' patternUnits='userSpaceOnUse' width='1.6' height='1.6' patternTransform='rotate(45)'>"
                f"<line x1='0' y1='0' x2='0' y2='1.6' stroke='#111' stroke-width='0.22'/></pattern>"
                f"<pattern id='hatch2' patternUnits='userSpaceOnUse' width='1.6' height='1.6' patternTransform='rotate(-45)'>"
                f"<line x1='0' y1='0' x2='0' y2='1.6' stroke='#555' stroke-width='0.2'/></pattern></defs>\n{body}\n</svg>\n")

# view helpers: model (a,b) -> sheet
class View:
    def __init__(self, sh, ox, oy, s=1.0):
        self.sh, self.ox, self.oy, self.s = sh, ox, oy, s
    def p(self, a, b): return self.ox + a * self.s, self.oy - b * self.s
    def rect(self, a0, a1, b0, b1, **kw):
        x, y = self.p(a0, b1); self.sh.rect(x, y, (a1 - a0) * self.s, (b1 - b0) * self.s, **kw)
    def circle(self, a, b, d, **kw):
        x, y = self.p(a, b); self.sh.circle(x, y, d / 2 * self.s, **kw)
    def line(self, a0, b0, a1, b1, **kw):
        x0, y0 = self.p(a0, b0); x1, y1 = self.p(a1, b1); self.sh.line(x0, y0, x1, y1, **kw)
    def cross(self, a, b, r):
        x, y = self.p(a, b); self.sh.cross(x, y, r)

sheets = []

# =============================================================== SHEET 1
s1 = Sheet(1, "GENERAL ARRANGEMENT - PLAN VIEWS")
s1.frame()

# ---- View 1: top view of lid / control panel
v = View(s1, 38, 152)
v.rect(0, W, 0, D, sw=0.6, rx=0)
# lid lip (hidden)
v.rect(IX0 + LIP_GAP, IX1 - LIP_GAP, IY0 + LIP_GAP, IY1 - LIP_GAP, sw=0.25, dash="1.5 0.8")
for bx, by in BOSSES:
    v.circle(bx, by, 3.4, sw=0.45); v.circle(bx, by, 6.0, sw=0.25, dash="1.2 0.7")
# zones under the lid (phantom)
v.rect(BAY_B[0], BAY_B[1], BAY_B[2], BAY_B[3], sw=0.25, c=PHANTOM, dash="5 1 1 1 1 1")
v.rect(PB[0], PB[1], PB[2], PB[3], sw=0.25, c=PHANTOM, dash="5 1 1 1 1 1")
for y in ROWS:
    v.circle(BTN_X, y, BTN_CUT, sw=0.6); v.circle(BTN_X, y, BTN_BEZEL, sw=0.25, c=PHANTOM, dash="1.2 0.7")
    v.cross(BTN_X, y, 11)
    v.circle(LED_X, y, LED_CUT, sw=0.6); v.circle(LED_X, y, LED_BEZEL, sw=0.25, c=PHANTOM, dash="1.2 0.7")
    v.cross(LED_X, y, 7)
v.circle(SEL_X, SEL_Y, SEL_CUT, sw=0.6); v.cross(SEL_X, SEL_Y, 6)
x, y = v.p(SEL_X, SEL_Y); s1.rect(x - 3.9, y - 6.5, 7.8, 13, 0.25, PHANTOM, dash="1.2 0.7")
v.line(BTN_X, 5, BTN_X, D - 5, c=BLUE, w=0.18, dash="6 1.2 1 1.2")
v.line(LED_X, 5, LED_X, D - 5, c=BLUE, w=0.18, dash="6 1.2 1 1.2")
v.line(5, CY, W - 5, CY, c=BLUE, w=0.18, dash="6 1.2 1 1.2")
# panel legends
for i, y in enumerate(ROWS):
    xx, yy = v.p(BTN_X + 13, y); s1.text(xx, yy + 0.9, f"PB{3-i}", 2.2, c=PHANTOM)
    xx, yy = v.p(LED_X - 9, y); s1.text(xx, yy + 0.9, f"L{3-i}", 2.2, "end", c=PHANTOM)
xx, yy = v.p(SEL_X - 8, SEL_Y - 4); s1.text(xx, yy, "SW1", 2.2, "end", c=PHANTOM)
xx, yy = v.p(SEL_X + 5, SEL_Y + 6.5); s1.text(xx, yy, "throw", 1.8, "start", c=PHANTOM)
s1.line(*v.p(SEL_X + 5, SEL_Y + 4.5), *v.p(SEL_X + 5, SEL_Y - 4.5), 0.18, PHANTOM); s1.arrow(*v.p(SEL_X + 5, SEL_Y + 4.5), -90, PHANTOM); s1.arrow(*v.p(SEL_X + 5, SEL_Y - 4.5), 90, PHANTOM)
xd = v.p(SEL_X + 16, 0)[0]
s1.vdim(v.p(0, ROWS[0])[1], v.p(0, SEL_Y)[1], v.p(LED_X - 6, 0)[0], v.p(SEL_X + 7, 0)[0], xd, f(SEL_Y - ROWS[0]))
s1.vdim(v.p(0, SEL_Y)[1], v.p(0, ROWS[1])[1], v.p(SEL_X + 7, 0)[0], v.p(LED_X - 6, 0)[0], xd, f(ROWS[1] - SEL_Y))
# stepped cutting plane A-A
s1.poly([v.p(-6, CY), v.p(SEL_X - 13, CY), v.p(SEL_X - 13, SEL_Y), v.p(SEL_X + 13, SEL_Y), v.p(SEL_X + 13, CY), v.p(W + 6, CY)], 0.35, INK, close=False)
# section markers
xa, ya = v.p(-6, CY); xb, yb = v.p(W + 6, CY)
for xx in (xa, xb):
    s1.line(xx, ya, xx, ya - 6, 0.6); s1.arrow(xx, ya - 6.2, -90)
    s1.text(xx, ya + 4, "A", 3.4, "middle", weight="bold")
xa, ya = v.p(LED_X, -6); xb, yb = v.p(LED_X, D + 6)
for yy in (ya, yb):
    s1.line(xa, yy, xa + 6, yy, 0.6); s1.arrow(xa + 6.2, yy, 0)
    s1.text(xa - 3, yy + 1.2, "B", 3.4, "middle", weight="bold")
# dimensions
x0, yb0 = v.p(0, 0); x1, _ = v.p(W, 0)
s1.hdim(x0, x1, yb0, yb0, yb0 + 22, f"{f(W)}")
xs = [v.p(a, 0)[0] for a in (0, BTN_X, SEL_X, LED_X, W)]
for a0, a1 in ((0, BTN_X), (BTN_X, SEL_X), (SEL_X, LED_X), (LED_X, W)):
    xa_, _ = v.p(a0, 0); xb_, _ = v.p(a1, 0)
    s1.hdim(xa_, xb_, yb0 - D + ROWS[0] if False else v.p(0, ROWS[0])[1] if a0 else yb0, v.p(0, ROWS[0])[1] if a1 != W else yb0, yb0 + 12, f(a1 - a0))
xl, _ = v.p(0, 0)
s1.vdim(v.p(0, 0)[1], v.p(0, D)[1], xl, xl, xl - 24, f(D))
for b0, b1 in ((0, ROWS[0]), (ROWS[0], ROWS[1]), (ROWS[1], ROWS[2]), (ROWS[2], D)):
    s1.vdim(v.p(0, b0)[1], v.p(0, b1)[1], xl if b0 == 0 else v.p(BTN_X, 0)[0] - 9, xl if b1 == D else v.p(BTN_X, 0)[0] - 9, xl - 12, f(b1 - b0))
# callouts
s1.leader(*v.p(BTN_X - BTN_CUT / 2 * 0.7, ROWS[2] + BTN_CUT / 2 * 0.7), *v.p(BTN_X - 15, D + 14), "3x  Ø16.2 THRU - PUSHBUTTON PB1-3 *", anchor="start")
s1.leader(*v.p(SEL_X + 2.2, SEL_Y + 2.2), *v.p(SEL_X - 3, D + 7), "Ø6.2 THRU - SELECTOR SW1 (M6x0.75)", anchor="end")
s1.leader(*v.p(LED_X + 2.9, ROWS[2] + 2.9), *v.p(LED_X - 5, D + 14), "3x  Ø8.2 THRU - LED HOLDER *", anchor="start")
s1.leader(*v.p(BOSSES[1][0], BOSSES[1][1]), *v.p(W + 3, -7), "4x Ø3.4, CSK Ø6.5x90°", anchor="start")
s1.label_view(38 + W / 2, 20, "VIEW 1 - TOP (CONTROL PANEL / LID)", "Lid 3.0 thick. Hidden: lid locating lip. Phantom: bays below.")

# ---- View 2: plan view with lid removed
v2 = View(s1, 230, 152)
v2.rect(0, W, 0, D, sw=0.6)
v2.rect(IX0, IX1, IY0, IY1, sw=0.45)
# rib
v2.rect(RIB[0], RIB[1], IY0, NOTCH[0], sw=0.4, fill="url(#hatch2)")
v2.rect(RIB[0], RIB[1], NOTCH[1], IY1, sw=0.4, fill="url(#hatch2)")
v2.rect(RIB[0], RIB[1], NOTCH[0], NOTCH[1], sw=0.25, dash="1 0.6")
# battery bay
v2.rect(*BAY_B, sw=0.25, c=PHANTOM, dash="5 1 1 1 1 1")
v2.rect(HOLDER[0], HOLDER[1], HOLDER[2], HOLDER[3], sw=0.5, fill="#f2f2f2")
x, y = v2.p((HOLDER[0] + HOLDER[1]) / 2, CY)
s1.text(x, y - 2, "9 V BATTERY", 2.4, "middle", weight="bold"); s1.text(x, y + 1.5, "HOLDER *", 2.4, "middle", weight="bold")
s1.text(x, y + 5, "31 x 55 x 21", 2.2, "middle")
# channel / ties
for ty in TIE_Y:
    v2.rect(CHAN[0] + 2, CHAN[0] + 10, ty - 2, ty + 2, sw=0.3)
    v2.line(CHAN[0] + 2, ty, CHAN[0] + 10, ty, w=0.2)
x, y = v2.p((CHAN[0] + CHAN[1]) / 2, CY)
s1.text(x - 9, y, "DC PLUG / CABLE ZONE", 2.0, "middle", rot=-90)
v2.rect(PLUG[0], PLUG[1], PLUG[2], PLUG[3], sw=0.45, fill="#333", op=0.85)
v2.rect(PLUG[0] - 6, PLUG[0], JACK_Y - 1.5, JACK_Y + 1.5, sw=0.3, fill="#b00020", op=0.6)
x, y = v2.p((PLUG[0] + PLUG[1]) / 2, PLUG[2] - 3.5); s1.text(x, y, "DC PLUG *", 1.9, "middle")
# electronics bay
v2.rect(PB[0], PB[1], PB[2], PB[3], sw=0.55, fill="#eef3fb")
v2.rect(UNO[0], UNO[1], UNO[2], UNO[3], sw=0.3, dash="2 0.8")
v2.rect(UNO_USB[0], UNO_USB[1], UNO_USB[2], UNO_USB[3], sw=0.25, dash="1.2 0.6")
v2.rect(UNO_DCJ[0], UNO_DCJ[1], UNO_DCJ[2], UNO_DCJ[3], sw=0.25, dash="1.2 0.6")
for hx, hy in UNO_HOLES:
    v2.circle(hx, hy, 6, sw=0.25, dash="1 0.6"); v2.cross(hx, hy, 4)
for px, py in PB_PILLARS:
    v2.circle(px, py, 7, sw=0.45); v2.circle(px, py, 3.2, sw=0.3); v2.cross(px, py, 5)
# hole-centre span frame
v2.rect(PB[0] + PB_EDGE, PB[1] - PB_EDGE, PB[2] + PB_EDGE, PB[3] - PB_EDGE, sw=0.2, c=BLUE, dash="0.6 0.8")
# LED keep-out
v2.rect(*LED_KO, sw=0.3, c="#b00020", dash="2 1")
x, y = v2.p(LED_X, ROWS[2] + 9); s1.text(x, y, "LED KEEP-OUT", 1.9, "middle", c="#b00020")
v2.rect(*SEL_KO, sw=0.3, c="#b00020", dash="2 1")
x, y = v2.p(SEL_X, SEL_KO[3] + 1.5); s1.text(x, y, "SW1 KEEP-OUT (parts <= 6)", 1.9, "middle", c="#b00020")
x, y = v2.p(PB_CX - 12, CY + 30); s1.text(x, y, "PROTOBOARD 30x33 (UPPER)", 2.4, "middle", weight="bold")
x, y = v2.p(PB_CX - 12, CY - 33); s1.text(x, y, "ARDUINO UNO R3 (BELOW, hidden)", 2.2, "middle")
for bx, by in BOSSES:
    v2.circle(bx, by, 7, sw=0.45); v2.circle(bx, by, 4.0, sw=0.3)
# reserved DC jack zone on right wall
# dims
x0, yb0 = v2.p(0, 0)
pts = [0, IX0, BAY_B[1], CHAN[0], CHAN[1], PB[0], PB[1], IX1, W]
labels_ok = {(BAY_B[1], CHAN[0]): "2", }
row_y = yb0 + 12
for a0, a1 in ((IX0, BAY_B[1]), (BAY_B[1], RIB[1]), (RIB[1], UNO_DCJ[0]), (UNO_DCJ[0], UNO[1]), (UNO[1], IX1)):
    s1.hdim(v2.p(a0, 0)[0], v2.p(a1, 0)[0], yb0 - T_WALL, yb0 - T_WALL, row_y, f(a1 - a0))
s1.hdim(v2.p(IX0, 0)[0], v2.p(IX1, 0)[0], yb0 - T_WALL, yb0 - T_WALL, yb0 + 21, f"{f(IX1 - IX0)} INSIDE")
xr = v2.p(W, 0)[0]
for b0, b1 in ((IY0, PB[2]), (PB[2], PB[3]), (PB[3], IY1)):
    s1.vdim(v2.p(0, b0)[1], v2.p(0, b1)[1], xr - T_WALL, xr - T_WALL, xr + 8, f(b1 - b0))
s1.vdim(v2.p(0, IY0)[1], v2.p(0, IY1)[1], xr - T_WALL, xr - T_WALL, xr + 15, f"{f(IY1 - IY0)} INSIDE")
xl = v2.p(0, 0)[0]
s1.vdim(v2.p(0, BAY_B[2])[1], v2.p(0, BAY_B[3])[1], xl + 2.5, xl + 2.5, xl - 8, "65 BAY *")
s1.leader(*v2.p(PB_PILLARS[2][0], PB_PILLARS[2][1]), *v2.p(70, D + 8), f"4x PILLAR Ø7, H {f(PILLAR_H)}, PILOT Ø2.5 (M3 self-tap) / Ø4 INSERT", anchor="start")
s1.leader(*v2.p(*UNO_HOLES[0]), *v2.p(W, D + 15), "4x STANDOFF Ø6, H 6.0 at Uno R3 holes", anchor="end")
s1.leader(*v2.p(BOSSES[2][0], BOSSES[2][1]), *v2.p(-3, D + 8), "4x BOSS Ø7 x 56.5, M3 HEAT-SET INSERT", anchor="start")
s1.leader(*v2.p(RIB[0] + 1, NOTCH[1]), *v2.p(-3, D + 15), "RIB 2.0 x 15 HIGH, 8x8 WIRE NOTCH", anchor="start")
s1.leader(*v2.p(PLUG[0] + 4, PLUG[2]), *v2.p(PLUG[0] + 30, -7), "9 V lead -> DC plug into Uno jack (per photo)", anchor="start")
s1.label_view(230 + W / 2, 20, "VIEW 2 - PLAN, LID REMOVED", "Battery bay LEFT under buttons  |  electronics bay RIGHT under LEDs")

# ---- coordinate table (sheet 1, bottom-left)
tx, ty = 15, 188
s1.text(tx, ty, "TABLE 1 - FEATURE COORDINATES (origin: external front-left-bottom corner, mm)", 2.8, weight="bold")
cols = [tx, tx + 28, tx + 62, tx + 96, tx + 118]
hdr = ["ITEM", "X", "Y", "SIZE", "NOTE"]
rows = [
    ("PB1/PB2/PB3", f(BTN_X), "77 / 52 / 27", "Ø16.2", "Adafruit 1439, 16 mm illum. momentary *"),
    ("SW1 selector", f(SEL_X), f(SEL_Y), "Ø6.2", "Miyama MS-500E (ON)-OFF-(ON), M6x0.75"),
    ("L1/L2/L3", f(LED_X), "77 / 52 / 27", "Ø8.2", "LED + 8 mm panel holder (model TBC) *"),
    ("Lid screws", f"{f(BOSSES[0][0])} / {f(BOSSES[1][0])}", f"{f(BOSSES[0][1])} / {f(BOSSES[2][1])}", "Ø3.4", "4x M3 x 10 countersunk into inserts"),
    ("Battery holder", f"{f(HOLDER[0])}-{f(HOLDER[1])}", f"{f(HOLDER[2])}-{f(HOLDER[3])}", "31x55x21", "on floor; VHB tape or 2x M3 *"),
    ("Protoboard", f"{f(PB[0])}-{f(PB[1])}", f"{f(PB[2])}-{f(PB[3])}", "78.74x86.36", f"underside Z {f(PB_Z0)} *"),
    ("PB pillars", f"{f(PB_PILLARS[0][0])} / {f(PB_PILLARS[1][0])}", f"{f(PB_PILLARS[0][1])} / {f(PB_PILLARS[2][1])}", f"Ø7 x {f(PILLAR_H)}", "corner holes drilled to Ø3.2"),
    ("Arduino Uno R3", f"{f(UNO[0])}-{f(UNO[1])}", f"{f(UNO[2])}-{f(UNO[3])}", "68.58x53.34", "underside Z 8.5, USB/DC jack face LEFT"),
    ("Uno standoffs", " / ".join(f(h[0]) for h in UNO_HOLES), " / ".join(f(h[1]) for h in UNO_HOLES), "Ø6 x 6.0", "4 holes, ref. Uno R3 drawing"),
]
yy = ty + 4
s1.line(tx, yy, 235, yy, 0.35)
for c_, h_ in zip(cols, hdr): s1.text(c_ + 1, yy + 3.6, h_, 2.3, weight="bold")
yy += 5
s1.line(tx, yy, 235, yy, 0.25)
for r in rows:
    for c_, val in zip(cols, r): s1.text(c_ + 1, yy + 3.6, val, 2.2)
    yy += 5
    s1.line(tx, yy, 235, yy, 0.15)
for c_ in cols[1:]: s1.line(c_, ty + 4, c_, yy, 0.15)
s1.text(tx, yy + 4.5, "* = nominal / assumed value - see Sheet 3, Table 4. Uno standoff X and Y are listed pairwise in the same order.", 2.1, italic=True)

# legend (sheet 1 bottom-right above title block)
lx, ly = 250, 192
s1.text(lx, ly, "LINE LEGEND", 2.6, weight="bold")
items = [("0.6", None, INK, "Visible outline"), ("0.25", "1.5 0.8", INK, "Hidden edge"),
         ("0.18", "6 1.2 1 1.2", BLUE, "Centre line"), ("0.25", "5 1 1 1 1 1", PHANTOM, "Zone / phantom (under lid)"),
         ("0.3", "2 1", "#b00020", "Keep-out / reserved")]
for i, (w_, d_, c_, t_) in enumerate(items):
    yy = ly + 5 + i * 5
    s1.line(lx, yy, lx + 18, yy, float(w_) + 0.1, c_, d_); s1.text(lx + 22, yy + 0.9, t_, 2.3)
s1.text(lx + 85, ly, "KEY DECISIONS (spec §1)", 2.6, weight="bold")
for i, t_ in enumerate(["LEFT: 9 V battery under button column", "RIGHT: protoboard above Uno R3, under LEDs",
                        "SW1 right of centre, between L2/L3 rows (v6)", "Uno jacks face battery (photo); no USB hole",
                        f"Envelope: {f(W)} x {f(D)} x {f(H)} (was 200x120x75)"]):
    s1.text(lx + 85, ly + 5.9 + i * 5, "- " + t_, 2.2)
sheets.append(s1)

# =============================================================== SHEET 2
s2 = Sheet(2, "SECTIONS A-A / B-B, STACK-UP, ISOMETRIC")
s2.frame()

def section_shell(vw, length, hatch_ranges):
    """Draw sectioned walls/floor/lid for a section of given length."""
    # floor and walls (hatched)
    vw.rect(0, length, 0, T_FLOOR, sw=0.5, fill="url(#hatch)")
    vw.rect(0, T_WALL, T_FLOOR, BASE_H, sw=0.5, fill="url(#hatch)")
    vw.rect(length - T_WALL, length, T_FLOOR, BASE_H, sw=0.5, fill="url(#hatch)")
    # lid with lip
    vw.rect(0, length, BASE_H, H, sw=0.5, fill="url(#hatch)")
    lip0, lip1 = T_WALL + LIP_GAP, length - T_WALL - LIP_GAP
    vw.rect(lip0, lip0 + LIP_W, BASE_H - LIP_H, BASE_H, sw=0.5, fill="url(#hatch)")
    vw.rect(lip1 - LIP_W, lip1, BASE_H - LIP_H, BASE_H, sw=0.5, fill="url(#hatch)")
    # cut away the holes in the lid
    for a0, a1 in hatch_ranges:
        vw.rect(a0, a1, BASE_H, H, sw=0.0, fill="#fff")
        vw.line(a0, BASE_H, a0, H, w=0.5); vw.line(a1, BASE_H, a1, H, w=0.5)

def button(vw, a):
    r = BTN_BODY / 2
    vw.rect(a - r, a + r, BASE_H - BTN_DEPTH + 4, BASE_H, sw=0.4, fill="#fafafa")
    vw.rect(a - 4, a + 4, BASE_H - BTN_DEPTH, BASE_H - BTN_DEPTH + 4, sw=0.4, fill="#fafafa")  # lamp/terminals
    vw.rect(a - BTN_BEZEL / 2, a + BTN_BEZEL / 2, H, H + 2.5, sw=0.4, fill="#fafafa")
    vw.rect(a - 6.5, a + 6.5, H + 2.5, H + 5.5, sw=0.4, fill="#ffe3e3")
    vw.rect(a - 9.5, a + 9.5, BASE_H - 3, BASE_H, sw=0.3, fill="#ddd")      # nut
    vw.cross(a, (BASE_H + H) / 2, 0); vw.line(a, BASE_H - BTN_DEPTH - 2, a, H + 7, c=BLUE, w=0.18, dash="6 1.2 1 1.2")

def led(vw, a):
    vw.rect(a - 4, a + 4, BASE_H - LED_DEPTH + 3, BASE_H, sw=0.4, fill="#fafafa")
    vw.rect(a - 1.25, a + 1.25, BASE_H - LED_DEPTH, BASE_H - LED_DEPTH + 3, sw=0.3)
    vw.rect(a - LED_BEZEL / 2, a + LED_BEZEL / 2, H, H + 1.5, sw=0.4, fill="#fafafa")
    vw.rect(a - 2.5, a + 2.5, H + 1.5, H + 4.5, sw=0.4, fill="#ffe3e3")
    vw.line(a, BASE_H - LED_DEPTH - 2, a, H + 6, c=BLUE, w=0.18, dash="6 1.2 1 1.2")

# ---- Section A-A (front, cut at Y = 52)
va = View(s2, 45, 112)
section_shell(va, W, [(BTN_X - BTN_CUT / 2, BTN_X + BTN_CUT / 2), (SEL_X - SEL_CUT / 2, SEL_X + SEL_CUT / 2), (LED_X - LED_CUT / 2, LED_X + LED_CUT / 2)])
# visible (behind cut) features
for px, py in PB_PILLARS[2:]:
    va.rect(px - 3.5, px + 3.5, T_FLOOR, PB_Z0, sw=0.45)
for hx, hy in UNO_HOLES:
    if hy > CY: va.rect(hx - 3, hx + 3, T_FLOOR, UNO_Z0, sw=0.45)
va.rect(BOSSES[2][0] - 3.5, BOSSES[2][0] + 3.5, T_FLOOR, BASE_H, sw=0.3, dash="1.5 0.8")
va.rect(BOSSES[3][0] - 3.5, BOSSES[3][0] + 3.5, T_FLOOR, BASE_H, sw=0.3, dash="1.5 0.8")
# rib (cut at notch)
va.rect(RIB[0], RIB[1], T_FLOOR, NOTCH[2], sw=0.45, fill="url(#hatch)")
va.rect(RIB[0], RIB[1], NOTCH[2], RIB[5], sw=0.3)
# battery holder (cut)
va.rect(HOLDER[0], HOLDER[1], HOLDER[4], HOLDER[5], sw=0.5, fill="url(#hatch2)")
for y in ROWS[1:2]: button(va, BTN_X)
# selector
va.rect(SEL_X - SEL_BODY[0] / 2, SEL_X + SEL_BODY[0] / 2, BASE_H - SEL_DEPTH + 5, BASE_H - 2, sw=0.4, fill="#fafafa")
for dx in (-2.5, 0, 2.5): va.rect(SEL_X + dx - 0.4, SEL_X + dx + 0.4, BASE_H - SEL_DEPTH, BASE_H - SEL_DEPTH + 5, sw=0.25)
va.rect(SEL_X - 3, SEL_X + 3, BASE_H - 2, H + 6, sw=0.4, fill="#fafafa")
va.rect(SEL_X - 5, SEL_X + 5, H, H + 2.5, sw=0.3, fill="#ddd")
va.line(SEL_X, H + 6, SEL_X + 3, H + 15, w=1.6, c="#444")
va.line(SEL_X, BASE_H - SEL_DEPTH - 2, SEL_X, H + 17, c=BLUE, w=0.18, dash="6 1.2 1 1.2")
led(va, LED_X)
# stack
va.rect(UNO[0], UNO[1], UNO_Z0, UNO_Z0 + UNO_T, sw=0.5, fill="#2a7f8f", op=0.85)
va.rect(UNO[0] + 4, UNO[1] - 14, UNO_Z0 + UNO_T, UNO_Z0 + UNO_T + UNO_HDR, sw=0.3, dash="1.2 0.6")
va.rect(UNO_DCJ[0], UNO_DCJ[1], UNO_Z0 + UNO_T, UNO_Z0 + UNO_T + UNO_COMP, sw=0.4)
va.rect(PB[0], PB[1], PB_Z0, PB_Z0 + PB_T, sw=0.5, fill="#c8a24a", op=0.9)
va.rect(PB[0] + 3, SEL_KO[0], PB_Z0 + PB_T, PB_Z0 + PB_T + PB_COMP_MAX, sw=0.3, c=PHANTOM, dash="5 1 1 1 1 1")
va.rect(SEL_KO[1], PB[1] - 3, PB_Z0 + PB_T, PB_Z0 + PB_T + PB_COMP_MAX, sw=0.3, c=PHANTOM, dash="5 1 1 1 1 1")
va.rect(SEL_KO[0], SEL_KO[1], PB_Z0 + PB_T, PB_Z0 + PB_T + SEL_KO_H, sw=0.3, c="#b00020", dash="2 1")
s2.vdim(va.p(0, PB_Z0 + PB_T + SEL_KO_H)[1], va.p(0, BASE_H - SEL_DEPTH)[1], va.p(SEL_KO[1], 0)[0], va.p(SEL_X + 4, 0)[0], va.p(SEL_KO[1] + 4, 0)[0], f(gap_sel_pb))
va.rect(PB[0] + 3, PB[1] - 3, PB_Z0 - 2.5, PB_Z0, sw=0.25, c=PHANTOM, dash="1 0.6")
# wire path through notch (phantom)
xs_ = [(HOLDER[1], 12), (RIB[0], 13.5), (CHAN[0] + 4, 13.5), (PLUG[0] - 4, JACK_Z), (PLUG[0], JACK_Z)]
va.rect(PLUG[0], PLUG[1], PLUG[4], PLUG[5], sw=0.35, dash="1.5 0.8")
s2.poly([va.p(a, b) for a, b in xs_], sw=0.45, c="#b00020", close=False)
# dims
xL, yB = va.p(0, 0)
s2.hdim(xL, va.p(W, 0)[0], yB, yB, yB + 10, f(W))
xR = va.p(W, 0)[0]
z_marks = [0, T_FLOOR, UNO_Z0, PB_Z0, BASE_H, H]
for i, (b0, b1) in enumerate(zip(z_marks[:-1], z_marks[1:])):
    s2.vdim(va.p(0, b0)[1], va.p(0, b1)[1], xR, xR, xR + 8, f(b1 - b0))
s2.vdim(va.p(0, 0)[1], va.p(0, H)[1], xR, xR, xR + 16, f(H))
s2.vdim(va.p(0, HOLDER[4])[1], va.p(0, HOLDER[5])[1], xL, xL, xL - 7, "21 *")
s2.vdim(va.p(0, HOLDER[5])[1], va.p(0, BASE_H - BTN_DEPTH)[1], xL, xL, xL - 7, f"{f(gap_btn_batt)} MIN")
s2.vdim(va.p(0, BASE_H - BTN_DEPTH)[1], va.p(0, BASE_H)[1], xL, xL, xL - 7, f"{f(BTN_DEPTH)} *")
s2.leader(*va.p(BTN_X + 8, BASE_H - 15), *va.p(BTN_X + 34, H + 20), "PB2 - body depth below lid 30 * (governs height)", anchor="start")
s2.leader(*va.p(HOLDER[0] + 5, 12), *va.p(-4, -16), "9 V holder (section)", anchor="start")
s2.leader(*va.p(LED_X + 3, BASE_H - 8), *va.p(LED_X + 8, H + 13), "L2 - rear depth 12 *", anchor="start")
s2.leader(*va.p(PB[1] - 10, PB_Z0 + 1), *va.p(W - 6, -22), f"Protoboard Z {f(PB_Z0)} - {f(PB_Z0 + PB_T)}", anchor="end")
s2.leader(*va.p(UNO[0] + 30, UNO_Z0 + 1), *va.p(UNO[0] + 18, -16), "Uno R3 Z 8.5 - 10.1", anchor="end")
s2.leader(*va.p(CHAN[0] + 3, 13.5), *va.p(CHAN[0] - 12, -22), "9 V lead via rib notch to DC plug (hidden, Y 33)", anchor="start", c="#b00020")
s2.label_view(45 + W / 2, 18, "SECTION A-A  (stepped, viewed from front)", "Stepped section: Y = 52 (PB2, L2), jog to Y = 39.5 through SW1")

# ---- Section B-B (side, cut at X = 128 through LED column; +Y to the right)
vb = View(s2, 265, 112)
section_shell(vb, D, [(y - LED_CUT / 2, y + LED_CUT / 2) for y in ROWS])
for y in ROWS: led(vb, y)
vb.rect(UNO[2], UNO[3], UNO_Z0, UNO_Z0 + UNO_T, sw=0.5, fill="#2a7f8f", op=0.85)
vb.rect(PB[2], PB[3], PB_Z0, PB_Z0 + PB_T, sw=0.5, fill="#c8a24a", op=0.9)
for px, py in PB_PILLARS:
    if px < LED_X: vb.rect(py - 3.5, py + 3.5, T_FLOOR, PB_Z0, sw=0.45)
for hx, hy in UNO_HOLES:
    if hx < LED_X: vb.rect(hy - 3, hy + 3, T_FLOOR, UNO_Z0, sw=0.45)
vb.rect(PB[2] + 3, PB[3] - 3, PB_Z0 + PB_T, PB_Z0 + PB_T + PB_COMP_MAX, sw=0.3, c=PHANTOM, dash="5 1 1 1 1 1")
vb.rect(ROWS[0] - 7, ROWS[2] + 7, PB_Z0 + PB_T, BASE_H - LED_DEPTH, sw=0.3, c="#b00020", dash="2 1")
vb.rect(UNO[2] + 4, UNO[3] - 4, UNO_Z0 + UNO_T, UNO_Z0 + UNO_T + UNO_HDR, sw=0.3, dash="1.2 0.6")
xL, yB = vb.p(0, 0); xR = vb.p(D, 0)[0]
s2.hdim(xL, xR, yB, yB, yB + 10, f(D))
for b0, b1 in ((0, PB[2]), (PB[2], PB[3])):
    s2.hdim(vb.p(b0, 0)[0], vb.p(b1, 0)[0], vb.p(0, PB_Z0)[1] if b0 else yB, vb.p(0, PB_Z0)[1], yB + 4, f(b1 - b0))
s2.vdim(vb.p(0, PB_Z0 + PB_T)[1], vb.p(0, PB_Z0 + PB_T + PB_COMP_MAX)[1], xR, xR, xR + 7, "12 *")
s2.vdim(vb.p(0, PB_Z0 + PB_T + PB_COMP_MAX)[1], vb.p(0, BASE_H - LED_DEPTH)[1], xR, xR, xR + 7, f"{f(gap_led_pb)}")
s2.vdim(vb.p(0, BASE_H - LED_DEPTH)[1], vb.p(0, BASE_H)[1], xR, xR, xR + 7, "12 *")
s2.vdim(vb.p(0, UNO_Z0 + UNO_T + UNO_COMP)[1], vb.p(0, PB_Z0)[1], xL, xL, xL - 7, f"{f(gap_pb_uno)} MIN")
s2.leader(*vb.p(ROWS[2] + 5, 40), *vb.p(4, H + 13), "LED keep-out: no protoboard parts here", anchor="start", c="#b00020")
s2.label_view(265 + D / 2, 18, f"SECTION B-B  (X = {f(LED_X)}, viewed from right)", "Through LED column L1-L3 and the board stack")

# ---- isometric (exploded lid)
COS, SIN = math.cos(math.radians(30)), math.sin(math.radians(30))
ISO_S, ISO_OX, ISO_OY = 0.45, 64, 250
def iso(x, y, z): return (ISO_OX + (x - y) * COS * ISO_S, ISO_OY - (z + (x + y) * SIN) * ISO_S)
def box(x0, x1, y0, y1, z0, z1, fill, op=1.0, sw=0.3, faces=("top", "front", "left")):
    F = {"top": [(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)],
         "front": [(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)],
         "left": [(x0, y0, z0), (x0, y1, z0), (x0, y1, z1), (x0, y0, z1)]}
    shade = {"top": 1.0, "front": 0.82, "left": 0.68}
    for k in faces:
        s2.add(f"<g opacity='{op}'>")
        s2.poly([iso(*p) for p in F[k]], sw, INK, mix(fill, shade[k]))
        s2.add("</g>")
def mix(hexc, k):
    r, g, b = int(hexc[1:3], 16), int(hexc[3:5], 16), int(hexc[5:7], 16)
    return "#%02x%02x%02x" % tuple(int(c * k) for c in (r, g, b))
def iso_circle(x, y, z, d, fill="#fff", sw=0.3):
    s2.poly([iso(x + d / 2 * math.cos(t), y + d / 2 * math.sin(t), z) for t in [i * math.pi / 18 for i in range(36)]], sw, INK, fill)
# back + right walls and floor
box(0, W, 0, D, 0, T_FLOOR, "#d9dde3", faces=("top",))
box(0, W, D - T_WALL, D, 0, BASE_H, "#d9dde3", faces=("front", "top"))
box(W - T_WALL, W, 0, D, 0, BASE_H, "#d9dde3", faces=("left", "top"))
for bx, by in BOSSES[1:]:
    box(bx - 3.5, bx + 3.5, by - 3.5, by + 3.5, T_FLOOR, BASE_H, "#d9dde3")
box(RIB[0], RIB[1], IY0, IY1, T_FLOOR, RIB[5], "#cfd4db")
for px, py in sorted(PB_PILLARS, key=lambda p: -(p[0] + p[1])):
    box(px - 3.5, px + 3.5, py - 3.5, py + 3.5, T_FLOOR, PB_Z0, "#cfd4db")
box(UNO[0], UNO[1], UNO[2], UNO[3], UNO_Z0, UNO_Z0 + UNO_T, "#2a7f8f")
box(PB[0], PB[1], PB[2], PB[3], PB_Z0, PB_Z0 + PB_T, "#c8a24a")
box(PLUG[0], PLUG[1], PLUG[2], PLUG[3], PLUG[4], PLUG[5], "#333333")
box(HOLDER[0], HOLDER[1], HOLDER[2], HOLDER[3], HOLDER[4], HOLDER[5], "#555b66")
# front + left walls, transparent
box(0, W, 0, T_WALL, 0, BASE_H, "#9fb3cc", op=0.28, faces=("front", "top"))
box(0, T_WALL, 0, D, 0, BASE_H, "#9fb3cc", op=0.28, faces=("left", "top"))
box(0, T_WALL, 0, D, 0, BASE_H, "#9fb3cc", op=1, sw=0.45, faces=())
s2.poly([iso(0, 0, 0), iso(W, 0, 0), iso(W, 0, BASE_H), iso(W, D, BASE_H), iso(0, D, BASE_H), iso(0, D, 0)], 0.5, INK)
s2.line(*iso(0, 0, 0), *iso(0, 0, BASE_H), 0.5); s2.line(*iso(0, 0, BASE_H), *iso(W, 0, BASE_H), 0.5); s2.line(*iso(0, 0, BASE_H), *iso(0, D, BASE_H), 0.5)
# exploded lid
LZ = BASE_H + 32
box(0, W, 0, D, LZ, LZ + T_LID, "#e8ecf2")
for y in ROWS:
    iso_circle(BTN_X, y, LZ + T_LID, BTN_CUT); iso_circle(LED_X, y, LZ + T_LID, LED_CUT)
iso_circle(SEL_X, SEL_Y, LZ + T_LID, SEL_CUT)
for bx, by in BOSSES: iso_circle(bx, by, LZ + T_LID, 3.4)
for bx, by in (BOSSES[0], BOSSES[1]):
    s2.line(*iso(bx, by, LZ), *iso(bx, by, BASE_H + 2), 0.18, BLUE, "6 1.2 1 1.2")
s2.text(*iso(W + 6, 0, LZ), "LID (exploded)", 2.3)
s2.text(*iso(W + 6, 0, 18), "BASE", 2.3)
s2.text(18, 142, "ISOMETRIC - EXPLODED LID (front-left view, not to scale)", 3.0, weight="bold")

# ---- Table 2 stack-up
tx, ty = 205, 150
s2.text(tx, ty, "TABLE 2 - VERTICAL STACK-UP (Z from outside bottom)", 2.8, weight="bold")
stack = [
    ("Floor", "0 - 2.5", "2.5 floor, 4x Ø10 x 1 foot recesses"),
    ("Uno standoffs", "2.5 - 8.5", "6.0 high, Ø6"),
    ("Uno R3 PCB", "8.5 - 10.1", "1.6 PCB"),
    ("Uno parts / headers", "10.1 - 21.0", "DC jack/USB 10.9, headers 8.5"),
    ("Clearance", f"21.0 - {f(PB_Z0)}", f"{f(gap_pb_uno)} to Uno parts, {f(gap_plug_pb)} to DC plug"),
    ("Protoboard", f"{f(PB_Z0)} - {f(PB_Z0 + PB_T)}", f"on 4 floor pillars, H {f(PILLAR_H)}"),
    ("Protoboard parts", f"{f(PB_Z0 + PB_T)} - {f(PB_Z0 + PB_T + PB_COMP_MAX)}", "max 12 * (keep-out under LEDs)"),
    ("LED rear", f"{f(BASE_H - LED_DEPTH)} - {f(BASE_H)}", f"12 *; {f(gap_led_pb)} clear to parts"),
    ("Battery holder", "2.5 - 23.5", "21 * high, on floor"),
    ("Selector rear", f"{f(BASE_H - SEL_DEPTH)} - {f(BASE_H)}", f"22 *; parts under SW1 <= {f(SEL_KO_H)}"),
    ("Button rear", "29.0 - 59.0", f"30 *; {f(gap_btn_batt)} clear to holder"),
    ("Base top / lid", "59.0 - 62.0", "3.0 lid, 1.5x3 lip, 0.3 gap"),
]
cols = [tx, tx + 38, tx + 62]
yy = ty + 3
s2.line(tx, yy, 405, yy, 0.35)
for c_, h_ in zip(cols, ("LAYER", "Z RANGE", "NOTE")): s2.text(c_ + 1, yy + 3.5, h_, 2.3, weight="bold")
yy += 4.8; s2.line(tx, yy, 405, yy, 0.25)
for r in stack:
    for c_, val in zip(cols, r): s2.text(c_ + 1, yy + 3.4, val, 2.15)
    yy += 4.6; s2.line(tx, yy, 405, yy, 0.12)
for c_ in cols[1:]: s2.line(c_, ty + 3, c_, yy, 0.15)
s2.text(tx, yy + 4.5, "Overall height is set by: holder 21 + 5.5 gap + button 30 + lid 3 + floor 2.5 = 62.", 2.2, weight="bold")
s2.text(tx, yy + 8.5, "Each 1 mm saved on the measured button depth reduces height by 1 mm.", 2.2, italic=True)
sheets.append(s2)

# =============================================================== SHEET 3
s3 = Sheet(3, "NOTES, ASSUMPTIONS REGISTER, VERIFICATION")
s3.frame()
def para(sh, x, y, title, lines, w=2.35, gap=4.2):
    sh.text(x, y, title, 3.0, weight="bold"); y += 5.5
    for ln in lines:
        sh.text(x, y, ln, w); y += gap
    return y
y = para(s3, 18, 22, "GENERAL NOTES", [
    "1.  All dimensions in mm. Third-angle projection. Model origin: external front-left-bottom corner (X right, Y back, Z up).",
    "2.  Two printed parts: BASE (tub with floor, walls, rib, bosses, pillars, standoffs) and LID (control panel). Print lid face-down.",
    "3.  Walls 2.5, floor 2.5, lid 3.0. External corners R3 (vertical edges) optional; internal fillets R1 at wall/floor joints.",
    "4.  Lid fixing: 4x M3 x 10 countersunk screws into M3 x 5.7 heat-set inserts (Ø4.0 pilot, 6 deep) in corner bosses Ø7.",
    "5.  Lid lip 1.5 wide x 3.0 deep, 0.3 clearance per side to inner wall; notch lip 8 x 8 around each corner boss.",
    "6.  Panel holes are printed at +0.2 over nominal (Ø16.2 / Ø6.2 / Ø8.2). Ream to fit after a test print of a 30 x 30 coupon.",
    "7.  SW1 anti-rotation: add a Ø2.5 x 1.5 deep key hole at 8 mm from SW1 centre once the switch's tab washer is confirmed.",
    f"8.  Protoboard on 4 floor pillars (Ø7 x {f(PILLAR_H)}) at its corner hole positions, drilled to Ø3.2; M3 self-tapping or insert.",
    "9.  Uno R3 on 4 standoffs Ø6 x 6.0 (Ø2.5 pilot for M3 self-tap / nylon M3). USB/DC jack face LEFT (photo).",
    "10. Battery service: remove 4 lid screws, fold lid over to the LEFT on a 150 mm wire service loop; holder is directly",
    "     accessible. The protoboard / Uno stack is NOT disturbed (spec §6).",
    "11. Wiring: the 9 V lead exits the bay through the 8 x 8 rib notch (Y 48-56), turns along the plug zone floor (tie anchors",
    f"     at Y 25 / 79) and enters the plug, which goes straight into the Uno DC jack at Y {f(JACK_Y)}. Deburr all edges.",
    f"12. Power per photo: 9 V holder lead ends in a DC barrel plug in the Uno jack. Keep the {f(CHAN[1] - CHAN[0])} mm zone left of the jack",
    "     free for the plug and its cable bend. No USB opening (spec §1). Fit the plug before mounting the protoboard.",
    f"13. Protoboard keep-outs: LED column (X {f(LED_KO[0])}-{f(LED_KO[1])}, Y {f(LED_KO[2])}-{f(LED_KO[3])}) parts <= 3; SW1 (X {f(SEL_KO[0])}-{f(SEL_KO[1])}, Y {f(SEL_KO[2])}-{f(SEL_KO[3])}) parts <= {f(SEL_KO_H)}.",
    f"14. Add 4x Ø10 x 1.0 deep recesses on the underside at (12,12) ({f(W-12)},12) (12,92) ({f(W-12)},92) for rubber feet.",
    "15. SW1 position follows the top layout of draft v6 (position only; no v6 dimensions used): right of centre, midway",
    "     between the L2 and L3 rows. Mount the toggle so the lever throws along Y (back = towards L2, front = towards L3).",
])

y = 22
s3.text(222, y, "TABLE 3 - CLEARANCE CHECKS (computed from model)", 3.0, weight="bold")
checks = [("Button body -> battery holder (Z)", gap_btn_batt, 5.0),
          ("LED rear -> protoboard parts (Z)", gap_led_pb, 5.0),
          ("Uno tallest part -> protoboard (Z)", gap_pb_uno, 2.5),
          ("Protoboard edge -> right wall (X)", IX1 - PB[1], 5.0),
          ("DC plug end -> rib (cable bend) (X)", gap_plug_rib, PLUG_BEND),
          ("DC plug top -> protoboard (Z)", gap_plug_pb, 2.5),
          ("Protoboard edge -> front/back wall (Y)", PB[2] - IY0, 5.0),
          ("Uno edge -> right wall (X)", IX1 - UNO[1], 3.0),
          ("Selector rear -> protoboard parts (Z)", gap_sel_pb, 5.0),
          ("Button bezel -> bezel (Y)", ROWS[1] - ROWS[0] - BTN_BEZEL, 5.0),
          ("Corner boss -> protoboard corner", min(math.hypot(bx - cx, by - cy) for bx, by in BOSSES for cx, cy in [(PB[0], PB[2]), (PB[1], PB[2]), (PB[0], PB[3]), (PB[1], PB[3])]) - 3.5, 0.5)]
yy = y + 3
cols = [222, 312, 340, 368]
s3.line(222, yy, 405, yy, 0.35)
for c_, h_ in zip(cols, ("CHECK", "ACTUAL", "MIN", "RESULT")): s3.text(c_ + 1, yy + 3.5, h_, 2.3, weight="bold")
yy += 4.8; s3.line(222, yy, 405, yy, 0.25)
for name, act, mn in checks:
    ok = act >= mn
    for c_, val in zip(cols, (name, f(round(act, 2)), f(mn), "OK" if ok else "FAIL")):
        s3.text(c_ + 1, yy + 3.4, val, 2.15, c=INK if val not in ("OK", "FAIL") else ("#1b7a33" if ok else "#b00020"), weight="bold" if val in ("OK", "FAIL") else "normal")
    yy += 4.6; s3.line(222, yy, 405, yy, 0.12)
for c_ in cols[1:]: s3.line(c_, y + 3, c_, yy, 0.15)

y = 122
s3.text(18, y, "TABLE 4 - ASSUMPTIONS REGISTER  (* values: the spec lists these as TBC/approx. - measure with calipers and update the parameters)", 3.0, weight="bold")
reg = [
    ("Protoboard outline", "78.74 x 86.36 x 1.6", "Hole span 73.66 x 81.28 (spec §4) + 2.54 edge margin each side", "Measure edge-to-edge"),
    ("Protoboard part height", "12 max above board", "Typical radial electrolytic / terminal block", "Measure tallest part"),
    ("Arduino Uno R3", "68.58 x 53.34 x 1.6", "Arduino reference design; holes (13.97,2.54) (15.24,50.80) (66.04,7.62) (66.04,35.56)", "Verify on board"),
    ("Uno part height", "10.9 (USB-B / DC jack)", "Reference design; headers 8.5", "Verify"),
    ("9 V battery holder", "31 x 55 x 21", "Spec §4 'approx. 55 x 31 x 21' - not verified", "Measure + wire exit"),
    ("Battery bay reserve", "41 x 65", "Spec §4 provisional planning reserve", "Re-check after holder"),
    ("Adafruit 1439 button", "Ø16 mount, Ø18 bezel, 30 below panel", "16 mm nominal (spec); depth incl. 2.8 mm QC terminal + wire bend ASSUMED", "CRITICAL: sets height"),
    ("Miyama MS-500E", "Ø6.2 bore, body 7.8 x 13, 22 below panel", "Spec §4 listing; depth below panel ASSUMED", "Check mfr. drawing"),
    ("LED indicator", "Ø8.2 cut-out, 12 rear depth", "Generic 5 mm LED in 8 mm panel holder - model not chosen", "Select model"),
    ("Panel thickness", "3.0 lid", "Within typical max panel thickness for M6 bushing / 16 mm button", "Check both parts"),
    ("DC plug (9 V lead)", f"{f(PLUG_L)} long, Ø{f(PLUG_D)}, +{f(PLUG_BEND)} bend", "Arrangement from user photo; size estimated - photo not used as a measurement", "Measure plug + boot"),
    ("Clearance allowance", ">= 5 (6 at electronics bay)", "Spec §6 preliminary allowance; 6 used so corner bosses clear the board", "-"),
]
cols = [18, 62, 112, 300]
yy = y + 3
s3.line(18, yy, 405, yy, 0.35)
for c_, h_ in zip(cols, ("ITEM", "VALUE USED", "BASIS / SOURCE", "ACTION")): s3.text(c_ + 1, yy + 3.5, h_, 2.3, weight="bold")
yy += 4.8; s3.line(18, yy, 405, yy, 0.25)
for r in reg:
    for c_, val in zip(cols, r):
        s3.text(c_ + 1, yy + 3.4, val, 2.15, c="#b00020" if val.startswith("CRITICAL") else INK, weight="bold" if val.startswith("CRITICAL") else "normal")
    yy += 4.6; s3.line(18, yy, 405, yy, 0.12)
for c_ in cols[1:]: s3.line(c_, y + 3, c_, yy, 0.15)

y = yy + 10
y = para(s3, 18, y, "HOW TO UPDATE AFTER MEASURING", [
    "a) Edit the parameter block at the top of cad/power_grid_box_enclosure.scad (and tools/gen_drawing.py for this drawing set).",
    "b) Overall size follows automatically: width = wall + battery bay + rib + DC plug zone (plug + bend) + Uno + 3 + wall;",
    "    depth = walls + 2 x 6 + protoboard depth; height = floor + holder + 5 + button depth + lid (re-check Table 3).",
    "c) Re-run tools/gen_drawing.py - the clearance table (Table 3) and the asserts fail if any check drops below its minimum.",
    "d) Before the full print: print the lid only (approx. 1.5 h) and trial-fit PB1-3, SW1 and L1-3.",
], gap=4.1)
y = para(s3, 222, 87, "OPEN ITEMS (spec §1, §7)", [
    "- External DC input: OPEN, not modelled. No USB opening.",
    "- Confirm button quantity (3) and LED model / quantity (3).",
    "- Confirm 2.8 x 0.5 QC receptacle fit on button blades.",
    "- Verify SW1 terminal arrangement with continuity meter.",
    "- Spec §5 says snap connector; photo shows a DC barrel plug. Drawn per photo.",
    "  A right-angle DC plug would cut about 20 mm from the width.",
], gap=4.1)
sheets.append(s3)

for sh in sheets:
    with open(os.path.join(OUT, f"PGB-ENC-001_sheet{sh.n}.svg"), "w") as fh:
        fh.write(sh.svg())
print("checks:", round(gap_btn_batt, 2), round(gap_led_pb, 2), round(gap_pb_uno, 2))
print("Uno holes:", UNO_HOLES)
print("PB:", [round(v, 2) for v in PB], "pillars:", [(round(a, 2), round(b, 2)) for a, b in PB_PILLARS])
