Welcome to my solution for part 1 of this problem. You can see my initial thoughts and drawings in the [Diagrams](./diagrams) folder. You can see my RTL design in SystemVerilog in the [rtl](./rtl) folder and its testbench (along with `input.txt`) in the [tb](./tb) folder.

## The Journey to the Working Solution

When I initially read the problem on December 1, I thought about trying to use an FSM to try and break down the problem. I wanted to have 5 states: one for being idle, one for extracting the instruction, one for figuring out our new dial position, one for editing it (incase of crossovers), and then one for checking if the dial position is at 0. However, I had to wait to start coding because it was finals week.

After finals week, I decided to code up my solution on December 15. I then decided to do the testbench for it on December 16. However, on December 16, I thought of a different way similar to how one could convert a number to binary. When converting a number to binary, one way is to try and find the largest power of two less than the number we are trying to convert and then keep subtracting. For example, if we had 750, the largest power of 2 would be 512. Subtracting, we would get 238. We would continue on like that. In my design, I applied the same idea to compute the distance % 100, but instead of subtracting by powers of two, I subtracted powers of two multiplied by 100:

```systemverilog
    // do distance mod 100
    // do a mod 100 manually; formula we are gonna use here: distance % 100 = distance - 100*(distance/100)
    always_comb begin
        logic [15:0] temp = distance; // copy the distance input in case something changes and also so we can do stuff with it
        if (temp >= 16'd6400) temp = temp - 16'd6400;  // 64*100 ; binary decomposition
        if (temp >= 16'd3200) temp = temp - 16'd3200;  // 32*100  
        if (temp >= 16'd1600) temp = temp - 16'd1600;  // 16*100
        if (temp >= 16'd800)  temp = temp - 16'd800;   // 8*100
        if (temp >= 16'd400)  temp = temp - 16'd400;   // 4*100
        if (temp >= 16'd200)  temp = temp - 16'd200;   // 2*100
        if (temp >= 16'd100)  temp = temp - 16'd100;   // 1*100
        distance_mod = temp[6:0]; // now it has to be somewhere in the range of 0-99
    end
```

By doing this, I was also able to avoid using the mod operator, which is a bit expensive in hardware since it synthesizes into a divider. This uses multiple adders, subtractors, comparators, etc. By doing it this way, I was able to cut down on resource usage. I was also able to realize that I had over-engineered the solution and could just use a busy/ready handshake instead of a 5 state FSM.

After implementing my new design in Vivado, I decided to then make the testbench. Since I had the input in my design as a file called `input.txt`, I downloaded the input from Advent of Code as a .txt file. Then, in my testbench, I parsed through it to extract the directions and distance to move the dial. However, I quickly realized that string handling in SystemVerilog is not efficient at all. I ended up needing to have a very fast clock speed to make it through all the movements in the file. The reason that it's not very efficient is because parsing strings require using system tasks like 
``` $fgets ```
These tasks operate sequentially and are relatively slow in simulation, so processing a large input file with thousands of lines made the testbench runtime noticeably long and caused it to automatically timeout. However, I was able to get around this by making my clock at 50GHz. I would like to note that this limitation is specific to the testbench and simulation environment in Vivado. On actual hardware, the design itself would not operate on strings and files. The testbench simply serves as a bridge to convert the text input into signals that the RTL can consume. Here is the timing calculation on actual hardware:

Each instruction takes 3 clock cycles:
1. Cycle 1: Assert valid to start the operation
2. Cycle 2: Design computes and returns ready
3. Cycle 3: Next instruction can begin after the required @(posedge clk) following the wait(ready)

With 4424 instructions at 50MHz (20ns/cycle):
4424 × 3 × 20ns = 265.44 microseconds

## Scalability and Considerations

### Current Design

1. Throughput: 1 instruction/rotation per 3 cycles
2. Maximum distance: 16 bits (0-65,535)
3. Position range: 0-99 (7 bits needed)
4. Zero counter: 16 bits (max 65,535 zero crossings)
5. Memory: instructions are streamed live, no external memory

### If Scaled to 10x Inputs (~44,240 Rotations)

1. Throughput: The current design finishes at about 265 microseconds at 50 MHz. For 44,240 rotations, 265 microseconds * 10 = 2.65 ms, which is still pretty fast in the real world.
2. Zero counter: 16 bits is still enough. Assuming the rate of crossovers was still the same, there would be answer * 10, which is representable with 14 bits, meaning that 16 is more than enough.
3. Resources Scaling: Runtime would increase linearly with more instructions, but the logic area would remain nearly constant. Whether we are processing 10 rotations or 10,000 rotations, the same binary decomposition logic, position update logic, and control FSM would be reused each cycle.

### If Scaled to 100x Inputs (~4.4 Million Rotations)
1. Throughput: We last calculated that at 10x inputs, it would take 2.65 ms. If we multiplied that by 10 again to get 100x inputs (2.65 ms * 10), we would get 26.5 ms, which is still an acceptable time.
2. Zero counter: 16 bits would definitely not be enough. It would have to be 32 bits (again, assuming that the rate of crossovers was the same).
3. Memory issue here: Processing so many rotations/instructions isn't realistic here, so we would probably end up having to use a BRAM buffer to store thousands of rotations.
4. Resource Estimate: The counters would widen a lot, so LUT count would go up, and like I said, we would need a BRAM due to the sheer number of instructions.

### The Bottleneck Here

The critical path here would be the binary decomposition, since it would be the longest combinational path. At 1000x inputs, the clock frequency (sped up by quite a bit for simulation purposes) would have to be reduced, but that would mean that pipelining would be needed.

The file I/O is simulation-only right now. In a real system, it would need UART or PCIe.

### Possible Improvements in the Case of Extreme Input Growth

If I had more knowledge/time to learn (I'm doing this over winter break as a first year student), here are the things I'd try to do:

1. Pipeline the state machine: I'd try to make it so that we could get 1 rotation/instruction per cycle. I'd have to add registers after the binary decomposition. Unfortunately, like I said, I'm a first year, and to be honest, I don't have the knowledge or experience to implement a pipelined version correctly. I understand the concept, but implementation is another challenge (theory vs real world experience).
2. Try to use a prefix sum: While researching ways to try and optimize performance, I came across the idea of a prefix sum. I think that in order to implement it here, I would have to somehow compute all the position updates in parallel and then apply this to the dial. It would allow the operation to be done in O(log N) cycles.
3. Memory: I might try to store all possible `(position + distance_mod) % 100` results in a lookup table (100×100×7-bit ROM = 70,000 bits). This would trade logic for memory, but FPGAs these days usually have enough BRAM resources. With the 100×100×7-bit ROM, it would use only 70,000 bits, so it would be a practical tradeoff.
4. Parametrize: I would make the dial range parametrizable (you could just change the width of the `position` register, but I'm not going to change it because the current setup works for the problem.

## The Resource Usage Breakdown

According to the synthesis report, the design uses 195 LUTs, 32 FFs, 44 IOs, and one BUFG. If I had to approximate where the logic goes, I would probably put 45% to the binary decomposition, 25% to update the position and the wrap-around logic, 15% to the state machine and busy/ready handshake, and the last 15% to the counters and registers. The key insight about this design is that it's pretty logic heavy and not memory heavy. The main bottleneck is the decomposition. Like I said before, in a larger design, it would probably have to be pipelined or use a small ROM lookup.

## Real World Considerations

In the current interface, there is a `valid`/`ready` handshake. In the real world, the module wouldn't read a file called `input.txt` - it's just for simulation. It would probably need an actual interface like UART + parser (ASCII instructions come in, and use a separate parser FSM feeds the module) or AXI-Lite slave (CPU would write the parsed [direction, distance] pairs. Obviously this means, that the module is only realistic for verification in a simulation environment (which I believe should be fine since the blog post said that we just need to have realistic I/O and aren't required to synthesize onto an actual FPGA). Of course, the opportunity to synthesize onto an actual FPGA would be great.

## Tradeoffs for Performance vs Power

1. Currently, at 50 MHz: 265 microseconds total execution
2. At 1 MHz (if power needed to be conserved): 13.25 ms total, which is fine for human interaction and saves a ton of power
3. At 100 MHz (if performance was the priority): 133 microseconds total (pipelining would probably be needed here)

The clock speed doesn't affect whether the module outputs the right answer. It only affects the throughput. Obviously running at a slower clock rate would save power, but we wanted performance, it could be pipelined and use a faster clock rate.

## Testing and Verification

The current testbench clearly has limitations. It's a very basic testbench. There's no type of randomization or anything like that. Here are a couple things I'd recommend if the scenario were that this woul dbe used in actual production:

1. Randomization: use random positions, distances, and directions. Run this for like 100k cycles, and then do some analysis.
2. Formal verification: use some formal methodologies

## Alternative Design Ideas

The first alternative design I can think of is to use the BRAM. It would trade logic for memory. The second alternative design I can think of would maybe be trying to combine hardware and software. With Advent of Code and Advent of FPGA having the same questions, I don't see why for example, software could parse the `input.txt` (like I said SystemVerilog is not good for parsing strings), and then have the hardware to do the position and crossover calculations.

## Things I Learned and Limitations

Like I said somewhere in this README, I'm a first year student and still learning advanced concepts. While I have been able to apply enough conceptual knowledge to make this design and solve the problem, I don't have the coursework or experience to implement more advanced topics confidently (or even correctly). This design itself took much longer than I would have liked, but it was pretty fun to do. This submission represents my current abilities applied creatively (over many, many hours) to solve the problem, and I'm really excited to learn more.

Some areas that I hope to learn more about are pipelining (obviously), parallel hardware, verification methods like UVM, physical implementation (place and route), and power optimization, as well as clock domain crossing (like pipelining, I understand what it is - just not how to correctly implement it).

## How it Works

The design maintains the dial position in the range 0–99 and updates it according to a direction (L or R) and a distance. The distance is reduced modulo 100 using a binary-decomposition method to avoid expensive division/modulo logic in hardware. The design also tracks the number of times the dial reaches zero.

The testbench reads the input file in batches (500 lines at a time) and parses each line to extract the direction and distance. The testbench reads the input file in batches of 500 lines rather than all at once because string handling in SystemVerilog is relatively slow in simulation. Parsing thousands of lines sequentially can make the simulation extremely long, especially when using `$fgets` to extract direction and distance from each line.

Processing the input in smaller batches reduces memory overhead and improves simulation responsiveness. After each batch, the testbench prints intermediate results, allowing us to monitor progress without waiting for the entire file to be processed, in addition to helping with debugging. This batching strategy ensures that even very large input files can be handled efficiently in simulation, without affecting the correctness of the design itself. Each instruction is then applied to the module sequentially. The testbench uses `$fgets` for simulation purposes.

## Metrics

This design uses the following resources:
1. 195 LUTs
2. 32 FFs
3. 44 IOs
4. 1 BUFG

## How to Run It

To run the design, you can use any SystemVerilog simulator that supports file I/O. I would recommend Vivado since this design was built in Vivado.

1. Download the `sequential.sv`, `sequential_tb.sv`, and `input.txt`
2. Open Vivado, make a new project with any board/part (won't matter for simulation), and make `sequential.sv` a design source. Make `sequential_tb.sv` and `input.txt` simulation sources.
3. Run simulation. You can look at the waveform and the log. The result will be displayed as `zero_count`.
