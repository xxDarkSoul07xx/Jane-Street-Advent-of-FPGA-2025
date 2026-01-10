# Jane Street Advent of FPGA 2025 Submission

I chose to do problem 1: https://adventofcode.com/2025/day/1

## Project Structure
- **part1/** - Solution to Part 1 (counts zeros after rotations complete)
- **part2/** - Solution to Part 2 (counts zeros during and after rotations)

Each part contains:
- `rtl/` - SystemVerilog design files
- `tb/` - Testbench and input files
- `README.md` - Analysis, scalability discussion, how to run, etc

## Quick Stats
- Part 1: 195 LUTs, 32 FFs
- Part 2: 534 LUTs, 25 FFs
- Both designs: 3 cycles/instruction latency

The reason for the naming like Design1 and sequential is because I initially wanted to do a sequential design and then a pipelined design. After the sequential one was working, I tried to pipeline and quickly realized I don't have the experience for it, but I hope to gain enough in the future to do so.

By Anirudh Bhaskar
