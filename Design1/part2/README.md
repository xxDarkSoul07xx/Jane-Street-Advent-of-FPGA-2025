Welcome to my solution for part 2 of this problem. You can see my RTL design in SystemVerilog in the [rtl](./rtl) folder and its testbench (along with `input.txt`) in the [tb](./tb) folder. Much of this is pretty similar to the README in part 1, but there's a couple of things here and there, so if you're interested, you can go ahead and keep reading.

## The Journey to the Working Solution
After getting part 1 correct on December 16, I decided to start part 2 on December 17. 

I read the problem and immediately thought about how I could modify my part 1 solution for part 2. I again initially went to trying to break down the problem using an FSM, but I couldn't get it to work. Instead, I thought about how I could compare the distance to move and where our current position is on the dial. This is when I realized that I could try to figure out when I would cross zero during rotations (zero after rotations was already computed in part 1). I realized that when moving right, once I accounted for the starting position, the zeros would occur at regular intervals. The formula ended up being the following:

If the dial is at position x and is moving right by y, the first zero occurs at (100 - x) steps, and then every 100 after that. This then became floor((x + y) / 100) zeros because I had to account for when x was 0.

For moving left, I realized that I had to think differently, and through trial and error, I ended up realizing that if the dial is at position x, it must reach zero after x steps, and then every 100 after that. This ended up as two conditions:

if y < p: no zeros
otherwise: 1 + floor((y - x) / 100)

After implementing this formula, I got the wrong answer. When I was debugging, I was able to uncover that my clock frequency was too slow. I was messing around with clock frequencies. I forgot to reset it back to the 50 GHz. I also found out that whenever a rotation started at 0, I was accidentally counting that as a crossover. After fixing these, I was able to get the correct answer.

## Scalability and Considerations

### Current Design

1. Throughput: 1 instruction/rotation per 3 cycles (same as part 1)
2. Maximum distance: 16 bits (0-65,535)
3. Position range: 0-99 (7 bits needed)
4. Zero counter: 16 bits (max 65,535 zero crossings)
5. Memory: instructions are streamed live, no external memory

### If Scaled to 10x Inputs (~44,240 Rotations)

1. Throughput: The current design finishes at about 265 microseconds at 50 MHz. For 44,240 rotations, 265 microseconds * 10 = 2.65 ms, which is still pretty fast in the real world.
2. Zero counter: 16 bits is still enough. Assuming the rate of crossovers was still the same, there would be answer * 10 (will be updated after the contest ends, because I don't want to leak the answer) so 16 is more than enough.
3. Resources Scaling: The LUT count would scale linearly with control logic, so given that the current design takes 577 LUTs, multiplying 577 * 1.1 = about 635 LUTs, which isn't a big increase.

### If Scaled to 100x Inputs (~4.4 Million Rotations)
1. Throughput: We last calculated that at 10x inputs, it would take 2.65 ms. If we multiplied that by 10 again to get 100x inputs (2.65 ms * 10), we would get 26.5 ms, which is still an acceptable time.
2. Zero counter: 16 bits would definitely not be enough. It would have to be 32 bits (again, assuming that the rate of crossovers was the same).
3. Memory issue here: Processing so many rotations/instructions isn't realistic here, so we would probably end up having to use a BRAM buffer to store thousands of rotations.
4. Resource Estimate: The counters would widen a lot, so LUT count would go up, and like I said, we would need a BRAM due to the sheer number of instructions.

### The Bottleneck Here

Here, the critical path would be different from part 1. In part 1, it was the binary decomposition method. However, in part 2, the critical path would be the division operation (`distance / 100`) because it would synthesize into more complex hardware, as compared to the binary decomposition, which uses a bunch of subtraction chains. If the inputs were scaled by a massive amount like 1000x, the division would probably need to be pipelined, or we could use an approximation method if an approximate answer were allowed.

The file I/O is simulation-only right now. In a real system, it would need UART or PCIe.

### Possible Improvements in the Case of Extreme Input Growth

If I had more knowledge/time to learn (I'm doing this over winter break as a first year student), here are the things I'd try to do:

1. Pipeline the division logic: Currently, the division operations are the critical path (`distance / 100`). To pipeline, some ideas I have are to maybe break the division into multiple clock cycles, or like in part 1, try to get one instruction per cycle.
2. Try to use a prefix sum: While researching ways to try and optimize performance, I came across the idea of a prefix sum. I think that in order to implement it here, I would have to somehow compute all the position updates in parallel and then apply this to the dial. It would allow the operation to be done in O(log N) cycles.
3. Memory: I might try to store the `distance % 100` in a lookup table (100x7-bit ROM). This would trade logic for memory, but FPGAs these days usually have enough BRAM sources. With the 100x7 bit ROM, it would use only 700 bits, so it would be a very practical tradeoff.
4. Parametrize: I would make the dial range parametrizable (you could just change the width of the `position` register, but I'm not going to change it because the current setup works for the problem.
5. Another thing I thought about specifically for part 2 is approximating the division for the crossovers. Currently, it's `distance / 100`, but if we did something like (distance * 41) >> 12, we'd get distance * 0.0100098, which is a 0.0098% error. If we were allowed to have a range that is at least close enough for this problem, this method would be good.

## The Resource Usage Breakdown

According to synthesis, the design uses 577 LUTs, 25 FFs, 44 IOs, and one BUFG. If I had to approximate where the logic goes, I would probably put 40% to the division logic, 30% to the binary decomposition, 15% for the position calculation and wrap-around, 10% for the state machine and handshake, and 5% for the counters and registers. The key insight about this design is that the division absolutely dominates the logic. This is pretty clear because the binary decomposition from part 1 is now a smaller portion of the total (and also because of how many more LUTs are used).

## Real World Considerations

In the current interface, there is a `valid`/`ready` handshake. In the real world, the module wouldn't read a file called `input.txt` - it's just for simulation. It would probably need an actual interface like UART + parser (ASCII instructions come in, and use a separate parser FSM feeds the module) or AXI-Lite slave (CPU would write the parsed [direction, distance] pairs. Obviously this means, that the module is only realistic for verification in a simulation environment (which I believe should be fine since the blog post said that we just need to have realistic I/O and aren't required to synthesize onto an actual FPGA). Of course, the opportunity to synthesize onto an actual FPGA would be great.

Additionally, the division operations would end up consuming a lot of power due to how many resources they use.

## Tradeoffs for Performance vs Power

1. Currently, at 50 MHz: 265 microseconds total execution
2. At 1 MHz (if power needed to be conserved): 13.25 ms total, which is fine for human interaction and saves a ton of power
3. At 100 MHz (if performance was the priority): 133 microseconds total (pipelining would probably be needed here)

The clock speed doesn't affect whether the module outputs the right answer. It only affects the throughput. Obviously running at a slower clock rate would save power, but we wanted performance, it could be pipelined and use a faster clock rate.

Since there is more combinational logic, this design would also end up using more power (static, which means more transistors and dynamic power, which means more switching activity).

## Testing and Verification

The current testbench clearly has limitations. It's a very basic testbench. There's no type of randomization or anything like that. Here are a couple things I'd recommend if the scenario were that this woul dbe used in actual production:

1. Randomization: use random positions, distances, and directions. Run this for like 100k cycles, and then do some analysis.
2. Formal verification: use some formal methodologies

## Alternative Design Ideas

The first alternative design I can think of is to use the BRAM. It would trade logic for memory. The second alternative design I can think of would maybe be trying to combine hardware and software. With Advent of Code and Advent of FPGA having the same questions, I don't see why for example, software could parse the `input.txt` (like I said SystemVerilog is not good for parsing strings), and then have the hardware to do the position and crossover calculations.

## Things I Learned and Limitations

Like I said somewhere in this README, I'm a first year student and still learning advanced concepts. While I have been able to apply the conceptual knowledge to improve this design, I don't have the coursework or experience to implement them confidently (or even correctly). This design itself took much longer than I would have liked, but it was pretty fun to do. This submission represents my current abilities applied creatively (over many, many hours) to solve the problem, and I'm really excited to learn more.

Making this solution for part 2 has taught me a lot more about the cost of basic operations that to be honest, I took for granted when coding in Python or C++. Unlike in software, it seems I'll have to be very mindful in very complex designs so that I don't use up a boatload of resources. Also, it's given me a little bit of experience with modeling problems as math equations, which I found pretty cool.

Some areas that I hope to learn more about are pipelining (obviously), parallel hardware, verification methods like UVM, physical implementation (place and route), and power optimization, as well as clock domain crossing (like pipelining, I understand what it is - just not how to correctly implement it).

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
