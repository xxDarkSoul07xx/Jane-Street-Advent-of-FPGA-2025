Welcome to my solution for part 2 of this problem. You can see my RTL design in SystemVerilog in the [rtl](./rtl) folder and its testbench (along with `input.txt`) in the [tb](./tb) folder.

## The Journey to the Working Solution
After getting part 1 correct on December 16, I decided to start part 2 on December 17. 

I read the problem and immediately thought about how I could modify my part 1 solution for part 2. I again initially went to trying to break down the problem using an FSM, but I couldn't get it to work. Instead, I thought about how I could compare the distance to move and where our current position is on the dial. This is when I realized that I could try to figure out when I would cross zero during rotations (zero after rotations was already computed in part 1). I realized that when moving right, once I accounted for the starting position, the zeros would occur at regular intervals. The formula ended up being the following:

If the dial is at position x and is moving right by y, the first zero occurs at (100 - x) steps, and then every 100 after that. This then became floor((x + y) / 100) zeros because I had to account for when x was 0.

For moving left, I realized that I had to think differently, and through trial and error, I ended up realizing that if the dial is at position x, it must reach zero after x steps, and then every 100 after that. This ended up as two conditions:

if y < p: no zeros
otherwise: 1 + floor((y - x) / 100)

After implementing this formula, I got 5057, but it was wrong. When I was debugging, I was able to uncover that my clock frequency was too slow. I was messing around with clock frequencies, I forgot to reset it back to the 50 GHz. After doing so, I was able to get the correct answer.

## How it Works
The design maintains the dial position in the range 0–99 and updates it according to a direction (L or R) and a distance. The distance is reduced modulo 100 using a binary-decomposition method to avoid expensive division/modulo logic in hardware. Unlike in part 1, this design counts when the dial lands on 0 during and after a rotation.

The testbench reads the input file in batches (500 lines at a time) and parses each line to extract the direction and distance. The testbench reads the input file in batches of 500 lines rather than all at once because string handling in SystemVerilog is relatively slow in simulation. Parsing thousands of lines sequentially can make the simulation extremely long, especially when using `$fgets` to extract direction and distance from each line.

Processing the input in smaller batches reduces memory overhead and improves simulation responsiveness. After each batch, the testbench prints intermediate results, allowing us to monitor progress without waiting for the entire file to be processed, in addition to helping with debugging. This batching strategy ensures that even very large input files can be handled efficiently in simulation, without affecting the correctness of the design itself. Each instruction is then applied to the module sequentially. The testbench uses `$fgets` for simulation purposes. I would like to note here also just like in part 1 (explanation copy-pasted from the part 1 README, which can be accessed at [Part 1 README](../part1/README.md)):

"I quickly realized that string handling in SystemVerilog is not efficient at all. I ended up needing to have a very fast clock speed to make it through all the movements in the file. The reason that it's not very efficient is because parsing strings require using system tasks like $fgets These tasks operate sequentially and are relatively slow in simulation, so processing a large input file with thousands of lines made the testbench runtime noticeably long and caused it to automatically timeout. However, I was able to get around this by making my clock at 50GHz. I would like to note that this limitation is specific to the testbench and simulation environment in Vivado. On actual hardware, the design itself would not operate on strings and files. The testbench simply serves as a bridge to convert the text input into signals that the RTL can consume."

There were approximately 4400 instructions, so on real hardware, if the clock was at 50MHz (20 ns per cycle), part 2 would complete in about 265 microseconds using more logic resources than in part 1. This is because in part 2, we are computing the zero crossings combinatorially, which computes zero crossings while maintaining the same 3-cycle throughput as Part 1. The calcuation is as follows (same as part 1):


Each instruction takes 3 clock cycles:
1. Cycle 1: Assert valid to start the operation
2. Cycle 2: Design computes and returns ready
3. Cycle 3: Next instruction can begin after the required @(posedge clk) following the wait(ready)

With 4424 instructions at 50MHz (20ns/cycle):
4424 × 3 × 20ns = 265.44 microseconds

## Metrics
This design uses the following resources:

1. 577 LUTs (more than doubled since part 1 due to the formulas I used, which require more combinational logic)
2. 25 FFs (less state storage)
3. 44 IOs
4. 1 BUFG

## How to Run It
To run the design, you can use any SystemVerilog simulator that supports file I/O. I would recommend Vivado since this design was built in Vivado.

1. Download the `sequential2.sv`, `sequential2_tb.sv`, and `input.txt`
2. Open Vivado, make a new project with any board/part (won't matter for simulation), and make `sequential2.sv` a design source. Make `sequential2_tb.sv` and `input.txt` simulation sources.
3. Run simulation. You can look at the waveform and the log. The result will be displayed in the `zero_count`.
