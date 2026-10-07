#!/bin/sh
# Compile and run the Assignment 1 testbenches with GHDL.
# --std=93c matches the Quartus VHDL-1993 setting; -fsynopsys is needed
# because TopLevel.vhd uses the non-standard ieee.std_logic_unsigned.
set -e
cd "$(dirname "$0")"
WORK=build
OPTS="--std=93c -fsynopsys --workdir=$WORK"
mkdir -p "$WORK"
ghdl -a $OPTS ../quartus/DE10_7SegmentDriver.vhd
ghdl -a $OPTS ../quartus/TopLevel.vhd
ghdl -a $OPTS tb_seven_segment_driver.vhd
ghdl -a $OPTS tb_toplevel.vhd
for tb in tb_seven_segment_driver tb_toplevel; do
	ghdl -e $OPTS "$tb"
	ghdl -r $OPTS "$tb" --assert-level=error
done
