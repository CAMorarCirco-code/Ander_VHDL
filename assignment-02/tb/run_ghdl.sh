#!/bin/sh
# Compile and run the Assignment 2 testbenches with GHDL.
#
# --std=08: the supplied ClockDelay.vhdl connects the `out` port of
#   genericClockDelay to its `buffer` port pllClock, which VHDL-93 forbids
#   (GHDL --std=93c rejects it, even with -frelaxed). VHDL-2008 allows it.
#   The files changed for this assignment are additionally checked as strict
#   VHDL-93 below, to match the Quartus VHDL_1993 project setting.
# pllKlok_sim.vhd replaces the generated pllKlok.vhd (needs Intel altera_mf).
set -e
cd "$(dirname "$0")"
Q=../quartus
mkdir -p build/93 build/08

echo "== VHDL-93 analysis of the files completed for this assignment"
ghdl -a --std=93c --workdir=build/93 $Q/Assignment2Package.vhdl $Q/trafficlight.vhdl $Q/Intersection.vhdl tb_genericClockDelay.vhd
ghdl -e --std=93c --workdir=build/93 tb_genericClockDelay
ghdl -r --std=93c --workdir=build/93 tb_genericClockDelay --assert-level=error

echo "== VHDL-2008 full design"
OPTS="--std=08 --workdir=build/08"
ghdl -a $OPTS $Q/Assignment2Package.vhdl $Q/trafficlight.vhdl $Q/ClockDelay.vhdl \
              $Q/Intersection.vhdl pllKlok_sim.vhd tb_genericClockDelay.vhd tb_intersection.vhd
for tb in tb_genericClockDelay tb_intersection; do
	ghdl -e $OPTS "$tb"
	ghdl -r $OPTS "$tb" --assert-level=error
done
