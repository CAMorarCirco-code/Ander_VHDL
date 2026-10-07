# Assignment 1 — Seven segment driver (DE10-Lite)

HAN ESE DSDL practical work, assignment 1 ("Opdracht 1"). Specification:
[`docs/assignment1.pdf`](docs/assignment1.pdf).

## Status at a glance

| Level | Status |
|---|---|
| Implemented | **Yes**: `integer_to_ssd` completed in `quartus/DE10_7SegmentDriver.vhd` |
| Static verification | **Done**: code review against the PDF, the `.qsf` pin map and the PDF waveform |
| Simulation verification | **Passed**: GHDL 4.1.0, own testbenches, 80 + 20 504 checks, 0 failures |
| Quartus compilation | **Not performed**: Quartus is not available in the development environment |
| Hardware verification | **Not performed**: not yet tested on a DE10-Lite board |

## What the assignment requires

- In `DE10_7SegmentDriver.vhd`, write a function that shows the decimal
  digits **0–9** on a DE10-Lite seven segment display, using a VHDL
  `case` statement.
- `TopLevel.vhd` is supplied, already complete, and must not be changed.
  It reads the 10 switches as a binary number (0–1023), splits it into four
  decimal digits and drives `HEX0` (rightmost) to `HEX3`. `LEDR` mirrors `SW`.
- Compile in Quartus, program the MAX 10 (`10M50DAF484C7G`) and demonstrate
  on the board.

## Repository layout

```
assignment-01/
  README.md
  docs/assignment1.pdf                       assignment specification (as supplied)
  quartus/                                   Quartus project, as supplied
    Opdracht1.qpf
    Opdracht1.qsf
    Opdracht1_assignment_defaults.qdf
    TopLevel.vhd                             supplied, unmodified
    DE10_7SegmentDriver.vhd                  supplied template, completed here
  tb/                                        own verification (not instructor material)
    tb_seven_segment_driver.vhd
    tb_toplevel.vhd
    run_ghdl.sh
```

The VHDL sources stay in `quartus/`, next to the project file. `Opdracht1.qsf`
refers to them by bare filename (`VHDL_FILE TopLevel.vhd`), so moving them
into a separate `src/` directory would mean editing the supplied `.qsf`.

`main` holds the untouched baseline (commit `af21a34`). All Assignment 1 work
is on the `assignment-01` branch.

`DE10_LITE_Default.qsf` (Terasic's demo project) was supplied as well. It
belongs to a different project and is not included.

## Implementation

Only the body of `integer_to_ssd` was written. The package declaration, the
function signature (`signal input : integer; doReverse, doInverse : boolean`)
and `reverseVector` are unchanged. The template's placeholder `assert false`
statements were removed, as the template instructs; one of them contained a
stray non-ASCII byte.

### Segment encoding

The encoding was taken from the PDF's simulation waveform. That waveform
shows `SW = 2F2` (754) with no key pressed, and displays
`HEX0..3 = 99, 92, F8, C0`, which decode to 4, 5, 7 and 0.

- bit 0 = a, bit 1 = b, … bit 6 = g, bit 7 = decimal point
- **active-low**: `'0'` lights a segment
- decimal point off (`'1'`) in normal mode

| Digit | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|---|
| Normal | C0 | F9 | A4 | B0 | 99 | 92 | 82 | F8 | 80 | 90 |

### Reverse and inverse

`TopLevel.vhd` derives these flags from the push buttons. The buttons are
active-low, so a pressed button reads `'0'`:

- `KEY(0)` pressed → `doReverse = true`
- `KEY(1)` pressed → `doInverse = true`

Interpretation (agreed decisions):

- **Reverse**: the bit order of **all 8 bits**, decimal point included, is
  mirrored using the supplied `reverseVector`. Bit 7 (dp) becomes bit 0
  (segment a), and so on. The resulting patterns are not meant to look like
  digits.
- **Inverse**: **all 8 bits** are inverted, decimal point included. The
  inverted digit patterns are the "negative" image, and the decimal point
  lights up.
- **Both**: reverse, then invert. The two operations commute, so the order
  does not matter.

| Digit | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|---|
| Reverse | 03 | 9F | 25 | 0D | 99 | 49 | 41 | 1F | 01 | 09 |
| Inverse | 3F | 06 | 5B | 4F | 66 | 6D | 7D | 07 | 7F | 6F |
| Reverse + inverse | FC | 60 | DA | F2 | 66 | B6 | BE | E0 | FE | F6 |

### Invalid inputs

The assignment specifies decimal digits 0–9 only. A comment in the template
mentions "0 to F", but hexadecimal digits are deliberately **not**
implemented. Any other integer takes the `when others` branch, which
produces `FF` (display dark). Reverse and inverse are then applied as
usual: reverse gives `FF`, inverse gives `00`, and both together give `00`.
`TopLevel` itself can only produce digits 0–9.

## Verification

### Static verification

- The interface of the package and function is unchanged. `TopLevel.vhd`
  is byte-identical to the baseline.
- The output width (8 bits, `7 downto 0`) matches the `HEX0..HEX3` ports
  and the 8 pins per display in `Opdracht1.qsf`.
- The normal-mode table matches the PDF waveform values. The inverse table
  equals the standard active-high seven segment codes (`3F 06 5B 4F 66 6D
  7D 07 7F 6F`), which cross-checks the a–g bit order.
- The PDF waveform (a low-resolution screenshot) appears to show `03` on
  displays holding a 0 while `KEY0` is pressed. That is consistent with
  reverse(C0) = 03 over all 8 bits, but the screenshot is too small to
  treat as conclusive.

### Simulation verification

The instructor's original `TestBench.vhd` (Aldec workspace) was **not
available**. The testbenches in `tb/` are our own. Their expected values are
hard-coded tables, so they do not rely on the driver's own `reverseVector`.

- **`tb_seven_segment_driver`** (80 checks)
  - digits 0–9 × {normal, reverse, inverse, reverse + inverse}
  - invalid inputs −1000, −1, 10, 11, 15, 16, 99, 1023, `integer'low` and
    `integer'high` × the same four modes
- **`tb_toplevel`** (20 504 checks), driving the unmodified `toplevel`
  entity:
  - the PDF case `SW = 0x2F2` (754) → `HEX0 = 99, HEX1 = 92, HEX2 = F8,
    HEX3 = C0`
  - 754 with every `KEY` combination
  - an exhaustive sweep of `SW = 0..1023` × all four `KEY` combinations,
    checking all four displays and `LEDR = SW`

Run with:

```sh
assignment-01/tb/run_ghdl.sh
```

The script uses `--std=93c` to match the Quartus VHDL-1993 setting, and
`-fsynopsys`, which GHDL requires because `TopLevel.vhd` uses
`ieee.std_logic_unsigned`.

**Result (GHDL 4.1.0, mcode):**

```
tb_seven_segment_driver: PASS (80 checks)
tb_toplevel: PASS (20504 checks)
```

**Sensitivity check.** Deliberately broken copies of the driver were made
outside the repository and each was run against the testbenches. Every one
of the following was detected:

- a wrong code for digit 7
- reverse removed
- inverse removed
- inverse limited to 7 bits
- `when others` changed to `00`

The last mutation is caught only by the unit testbench, as expected, because
`TopLevel` never produces a digit outside 0–9.

`ghdl --synth` also elaborated `toplevel` without errors. This is GHDL's
synthesis front-end, **not** a Quartus compilation.

## Known limitations and open points

- **Quartus not run.** The design has not been compiled or fitted with
  Quartus, and no timing or resource report exists.
- **I/O standards.** `Opdracht1.qsf` sets no `IO_STANDARD`; Terasic's
  reference file uses 3.3-V LVTTL. Check the Quartus warnings when compiling.
  The `.qsf` was intentionally left unchanged.
- **Two revisions.** `Opdracht1.qpf` lists two revisions, `Opdracht1` and
  `ZevenSegmentDemo`, but only `Opdracht1.qsf` was supplied. Open the
  `Opdracht1` revision.
- **Testbench is ours, not the instructor's.** Results from the course's
  pre-written Aldec testbench may differ, for example in waveform naming.
- **Reverse and inverse semantics** follow the agreed interpretation above.
  The specification does not define them beyond the source comments.

## Still requires physical FPGA verification

1. Compile `quartus/Opdracht1.qpf` (revision `Opdracht1`) in Quartus and
   program the DE10-Lite.
2. Set the switches to binary values and check that `HEX3..HEX0` show the
   decimal value. For example, 754 (`SW = 10 1111 0010`) should show 0754
   and 1023 should show 1023. The decimal points should be off.
3. Hold `KEY0`: displays show the bit-reversed patterns.
4. Hold `KEY1`: displays show the inverted patterns, with the decimal points
   lit.
5. Hold both buttons: displays show reversed and inverted patterns.
6. Check that the LEDs mirror the switches.
7. Demonstrate to the teacher.
