# Assignment 2 — Traffic light controller (DE10-Lite)

HAN ESE DSDL practical work, assignment 2 ("Opdracht 2", project
`TrafficLight` / `Verkeerslicht`).

`assignment2.pdf` itself was not available in this repository. The
requirements below come from the supplied implementation context, which
summarises that PDF, and from the comments in the supplied sources.

## Status at a glance

| Level | Status |
|---|---|
| Implemented | **Yes**: `genericClockDelay` (`Assignment2Package.vhdl`) and the `Intersection` architecture |
| Static verification | **Done**: review against the requirements and the supplied sources; GHDL synthesis front-end runs without errors or latch warnings |
| Simulation verification | **Passed**: GHDL 4.1.0, own testbenches, PLL replaced by a behavioural 12 kHz model (see below) |
| Quartus compilation | **Not performed**: Quartus is not available in the development environment |
| Hardware verification | **Not performed**: not tested on a DE10-Lite board |

## Requirements

- `trafficlight.vhdl` (Pedroni's `tlc`) is complete and is not changed.
- Complete `genericClockDelay` and `Intersection`.
- Clock chain: 10 MHz `ADC_CLK_10` → supplied PLL `pllKlok` (12 kHz) →
  generic clock delay → 60 Hz clock for the traffic-light FSM.
- SW0 = standby, SW1 = test mode, a push button freezes the lights.
- LED0 and LED1 show the switches, LED2 shows freeze, and LED9 shows time
  progression: 1 Hz in normal mode, 5 Hz in test mode.
- Two seven segment displays show the two traffic lights: top segment = red,
  middle = orange, lower = green. Orange flashes in standby.

## Repository layout

```
assignment-02/
  README.md
  quartus/                                 Quartus project as supplied (baseline commit 3d14e6b)
    Intersection.vhdl                      completed (top level)
    Assignment2Package.vhdl                completed (genericClockDelay)
    ClockDelay.vhdl                        supplied, unchanged (combinedClockDelay)
    trafficlight.vhdl                      supplied, unchanged (tlc)
    pllKlok.vhd / .qip / .ppf              generated ALTPLL IP, unchanged
    TrafficLight.qpf / .qsf / .sdc         unchanged (the .sdc is empty)
    Verkeerslicht_assignment_defaults.qdf  unchanged
  tb/                                      own verification (not instructor material)
    tb_genericClockDelay.vhd
    tb_intersection.vhd
    pllKlok_sim.vhd                        simulation-only PLL model
    run_ghdl.sh
```

The sources stay next to `TrafficLight.qsf` because the `.qsf` references
them by bare filename. `DE10_LITE_Default.qsf` (Terasic's demo project) was
supplied as a reference only and is not included.

## Implementation

### `genericClockDelay`

The entity, the generic names, types and defaults
(`desiredClock : integer := 10`, `inClockFreq : natural := 100`) and the
package component declaration are unchanged.

- One output period is `N = inClockFreq / desiredClock` input periods,
  split into a low phase of `N/2` periods (rounded down) followed by a high
  phase with the rest. The output frequency is therefore exact for every
  integer `N`; an odd `N` only skews the duty cycle. For example,
  12 000/60 gives 200 periods: 100 low and 100 high.
- The divider is a **phase timer**. A down-counter (`remaining`) holds the
  input periods left in the current phase. When it reaches 1, the output
  flip-flop (`level`) toggles and the counter is loaded with the length of
  the next phase. The counter only has to reach half a period (0..100
  for 12 kHz → 60 Hz).
- The output comes straight from a flip-flop, so the derived clock has no
  glitches.
- `rst` is asynchronous and active-high. It sets the output low and starts
  a new low phase.
- Elaboration-time `assert` statements check the generics:
  - **failure** if `desiredClock <= 0` or `inClockFreq < 2*desiredClock`;
  - **warning** if `inClockFreq` is not a multiple of `desiredClock`, which
    makes the output frequency approximate.

### `Intersection`

The entity, the `SimulationMode` generic, and the existing signals,
constants and component declarations from the template are unchanged.

| Function | Implementation |
|---|---|
| Standby | `SW(0)` → `stdby` → `stbyBit` → `tlc.stby`; `LEDR(0)` |
| Test mode | `SW(1)` → `test` → `testBit` → `tlc.test`; `LEDR(1)` |
| Freeze | `KEY(0)` held down (active-low) → `stop`; `LEDR(2)` |
| 60 Hz | `clock60Hz`: `combinedClockDelay(desiredClock => 60)` on `ADC_CLK_10` → `trafficPLLClock` |
| 1 Hz / 5 Hz | `clock1Hz` / `clock5Hz`: `genericClockDelay(1, 60)` and `genericClockDelay(5, 60)` on `trafficPLLClock` → `secondsClock` / `fiveHzClock` |
| tlc clock | `frozen` is sampled from `stop` on the falling edge of `trafficPLLClock`; `trafficClock` is held at `'0'` while `frozen = '1'`, otherwise it follows `trafficPLLClock` |
| Lights | `tlc` → `vk1` (r1/y1/g1) and `vk2` (r2/y2/g2), indexed by the template's `red`/`orange`/`green` constants |
| Standby flashing | `lightMask`, a per-colour enable: in standby its orange bit follows `secondsClock` (orange 0.5 s on, 0.5 s off), otherwise all bits are `'1'` |
| HEX0 / HEX1 | The `displays` process starts from all segments off and, for each colour, drives the segment given by the `segmentOf` table (red → bit 0/top, orange → bit 6/middle, green → bit 3/bottom, active-low) from `light and lightMask`. HEX0 = light 1, HEX1 = light 2 |
| LED9 | `timeTick` = `fiveHzClock` in test mode, otherwise `secondsClock` |
| LEDs | one aggregate: `LEDR = (0 => SW(0), 1 => SW(1), 2 => stop, 9 => timeTick, others => '0')` |

Resulting patterns: red = `FE`, orange = `BF`, green = `F7`, dark = `FF`.

The supplied PLL generates only 12 kHz, so a single PLL chain is used. The
1 Hz and 5 Hz clocks are divided from the 60 Hz clock rather than each
instantiating another PLL.

### Design decisions and assumptions

These are interpretations where the requirements leave room. All of them
are easy to change.

1. **Freeze** is active while `KEY0` is held. It is not a toggle, which
   would need debouncing. `KEY1` is unused.
2. **Freeze stops only the traffic lights.** LED9 keeps blinking, so time
   progression stays visible, and standby flashing is not affected. Standby
   always overrides freeze, because `tlc.stby` is asynchronous.
3. **Freeze is implemented by gating the `tlc` clock**, because `tlc` has no
   enable input and must not be modified. The request is sampled on the
   falling clock edge, so the clock is only blocked or released while it
   is low and a press cannot produce a short clock pulse.
4. **Light 1 is shown on HEX0 and light 2 on HEX1.** The supplied port
   comments label HEX0 "linker licht" (left light) and HEX1 "rechter licht"
   (right light). On the board, HEX0 is the rightmost display.
5. **No reset button** is defined. The clock delays' `rst` inputs (and so
   the PLL `areset`) are tied to `'0'`, and the counters start from their
   power-up initial values.
6. **`SimulationMode` is not used.** Its intended purpose is not documented
   in the supplied material.

## Verification

### Tools

- **GHDL 4.1.0** (mcode), installed in the development container with
  `apt-get install ghdl`.
- **Not available:** Quartus, Questa, Aldec Active-HDL, Intel's `altera_mf`
  simulation library, and the instructor's Assignment 2 testbench.

### Simulation model of the PLL

`quartus/pllKlok.vhd` instantiates Intel's `altpll`, which GHDL cannot
simulate. `tb/pllKlok_sim.vhd` is a behavioural stand-in with the same
entity, used only in simulation and never by Quartus. It produces the PLL's
configured output (10 MHz × 3 / 2500 = 12 kHz, 50 % duty) directly from
simulation time.

**The real PLL's behaviour, including lock and its actual output
frequency, is therefore not simulated.** Everything downstream of it is the
real RTL: `combinedClockDelay`, `genericClockDelay`, `tlc` and
`Intersection`.

### `tb_genericClockDelay` (unit test)

For each configuration, the output is checked after **every** input edge
against the exact model `out = '1' iff (k mod divisor) >= divisor/2`. Each
configuration first runs for 4·divisor + 3 edges, then reset is asserted
asynchronously between clock edges, and then it runs for 3·divisor edges.

Configurations:

- 12 000 → 60 Hz (divisor 200)
- 60 → 1 Hz (60)
- 60 → 5 Hz (12)
- the generic defaults, 100 → 10 Hz (10), instantiated without a
  generic map
- an odd divisor, 21 → 3 (7)

It also checks that the output is `'0'` during reset and that an
asynchronous reset clears it before the next clock edge.

Result: **PASS** for all five configurations. This was run twice: compiled
as strict VHDL-93, and as VHDL-2008.

### `tb_intersection` (integration test, about 104 s of simulated time)

The checks below are exact unless a tolerance is given.

1. **Standby from power-up:** both displays flash orange in step, with
   0.5 s half-periods (±10 µs).
2. **Standby released:**
   - YY is steady orange for about 1 s (window 1 s − 2 ticks … 1 s).
   - It is followed by a full normal cycle: RY **5 s**, GR **45 s**,
     YR **5 s**, RG **30 s** (each ±10 µs).
   - These durations are timer values counted on the 60 Hz clock, so they
     confirm the 12 kHz → 60 Hz path.
3. **Test mode:** each state lasts **1 s**.
4. **Freeze:**
   - `KEY0` is held for 3 s, 0.3 s into a state. The displays must not
     change.
   - After release, the remaining 0.7 s of that state runs (± 2 ticks), and
     then 1 s steps resume.
5. **Standby while running**, also with test mode and freeze active:
   - flashing starts immediately;
   - the half-period stays 0.5 s;
   - freeze has no effect on the flashing.
6. **Concurrent monitors** check at every input or output change (10 460
   checks):
   - `LEDR0/1/2` equal `SW0`/`SW1`/freeze;
   - `LEDR8..3` are off;
   - unused segments and the decimal points are off;
   - at most one light is lit per display;
   - outside standby exactly one is lit, and red or green never appears in
     standby;
   - at least one light is red, or both are orange.
7. **LED9 period:** 154 checks, 1 s in normal mode and 0.2 s in test mode
   (±10 µs).

Result: **`tb_intersection: PASS (10676 checks)`**.

### Sensitivity (mutation) check

Deliberately broken copies of the design were made outside the repository
and each was run against the testbenches. **All 13 were detected:**

- red and green segments swapped
- HEX0 and HEX1 swapped
- no standby flashing
- freeze not applied
- LED9 always 1 Hz
- traffic clock 50 Hz instead of 60 Hz
- LEDR2 not driven by freeze
- an unused LED lit
- decimal point lit
- test mode read from SW2
- divider duty cycle skewed
- divider period one count too long
- synchronous instead of asynchronous reset

### Elaboration and synthesis checks (GHDL)

- `genericClockDelay` with 10 → 7 Hz fails at elaboration with the
  assertion message.
- 100 → 7 Hz gives the warning.
- A negative `desiredClock` fails at elaboration with a range error before
  the assertion is reached.
- `ghdl --synth` on `Intersection` succeeds with no warnings and no
  latches. For this run the PLL was a pass-through black box. This is
  GHDL's synthesis front-end, **not** a Quartus compilation.

### Equivalence with the previous implementation

`genericClockDelay` and `Intersection` were restructured after the first
working version (commit `6130151`). The new structure is the phase-timer
divider, the table-driven display process, the light mask for flashing and
the single LED aggregate.

To confirm the restructured version behaves identically, both versions
were simulated side by side in GHDL, with the old entities renamed. These
comparison benches were temporary and are not part of the repository.

- **Divider:** 46 ratios, all N from 2 to 41 plus 12000/60, 60/1, 60/5,
  100/10, 21/3 and the non-whole 100/7. There were 400 random asynchronous
  resets, and the outputs were compared at every change: 79 166 comparisons,
  **0 mismatches**.
- **Top level:** identical random stimulus on all 10 switches and both
  keys, with HEX0, HEX1 and LEDR compared at every change. Two seeds:
  900 s with 111 input changes, and 400 s with 145 changes. **0
  mismatches.**
- **The comparison can detect differences:** a freeze sampled one clock
  tick later produced 7 mismatches.

### How to run

```sh
assignment-02/tb/run_ghdl.sh
```

## Problems found in the supplied files (not changed)

1. **`ClockDelay.vhdl` is not valid VHDL-93.** It connects the `out` port
   `outClock` of `genericClockDelay` directly to the `buffer` port
   `pllClock`. GHDL rejects this with `--std=93c`, even with `-frelaxed`.
   VHDL-2002 and later allow it, and GHDL accepts it with `--std=08`.
   - The project defaults file sets `VHDL_INPUT_VERSION VHDL_1993`.
   - Whether Quartus accepts this in VHDL-1993 mode is **unverified**.
   - If Quartus rejects it, the options are to set the Quartus VHDL version
     to 2008 for the project, or to change `pllClock` to `out` in
     `ClockDelay.vhdl`. Either needs approval first.
   - The `combinedClockDelay` component in `Intersection.vhdl` already
     declares this port as `out`.
   - The files completed for this assignment are themselves clean VHDL-93;
     `run_ghdl.sh` checks this.
2. **Device mismatch.** `TrafficLight.qsf` targets `10M50DAF484C6GES`,
   while Assignment 1's project and Terasic's file use the DE10-Lite device
   `10M50DAF484C7G`. Quartus or the Programmer may complain when
   programming the board.
3. **Missing PLL file.** `pllKlok.qip` lists `pllKlok.cmp`, which was not
   supplied. This is probably only a missing-file warning in Quartus, and
   is unverified.
4. **Empty `TrafficLight.sdc`.** It was left empty, as instructed. Quartus
   timing analysis will report the PLL output and the derived 60 Hz, 1 Hz
   and 5 Hz register clocks as unconstrained.
5. **No I/O standards.** `TrafficLight.qsf` sets no `IO_STANDARD`; Terasic's
   reference file uses 3.3-V LVTTL.
6. **Two revisions.** `TrafficLight.qpf` lists revisions `TrafficLight` and
   `Verkeerslicht`. Only `TrafficLight.qsf` was supplied.

## Known limitations

- The real PLL (`altpll`) is not simulated; see above.
- The design has not been compiled, fitted or timing-analysed in Quartus.
  Quartus will probably warn about the gated and ripple (register-derived)
  clocks. These are inherent to the assignment's clock-delay architecture.
- `tlc` has no reset, so its state after power-up depends on how Quartus
  encodes it at power-up. In simulation it starts in RG, the first state of
  the enumeration.
- The testbenches are ours, not the instructor's Aldec testbench.

## Still requires Quartus and hardware verification

1. Compile `quartus/TrafficLight.qpf`, revision `TrafficLight`. Check
   problem 1 (VHDL-93 `buffer`/`out`) and problem 2 (device) above, and
   review the warnings.
2. Program the DE10-Lite and check:
   - LED9 blinks at 1 Hz;
   - the light sequence runs RG 30 s → RY 5 s → GR 45 s → YR 5 s;
   - HEX0 and HEX1 show red at the top, orange in the middle and green at
     the bottom.
3. SW1 on: LED1 lights, LED9 blinks at 5 Hz, and the lights change every
   second.
4. SW0 on: LED0 lights and both orange segments flash at 1 Hz.
5. Hold KEY0: LED2 lights and the lights freeze. Release: the sequence
   continues.
6. LEDs 3–8 and all other segments stay off.
