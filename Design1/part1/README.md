Welcome to my solution for part 1 of this problem. You can see my initial thoughts and drawings in the [Diagrams](./diagrams) folder. You can see my RTL design in SystemVerilog in the [rtl](./rtl) folder and its testbench in the [tb](./tb) folder.

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
        if (temp >= 16'd100)  temp = temp - 16'd100;   // extra one just in case
        distance_mod = temp[6:0]; // now it has to be somewhere in the range of 0-99
    end
```

By doing this, I was also able to avoid using the mod operator, which is a bit expensive in hardware since it synthesizes into a divider. This uses multiple adders, subtractors, comparators, etc. By doing it this way, I was able to cut down on resource usage. I was also able to realize that I had over-engineered the solution and could just use a busy/ready handshake instead of a 5 state FSM.

After implementing my new design in Vivado, I decided to then make the testbench. Since I had the input in my design as a file called `input.txt`, I downloaded the input from Advent of Code as a .txt file. Then, in my testbench, I parsed through it to extract the directions and distance to move the dial. However, I quickly realized that string handling in SystemVerilog is not efficient at all. I ended up needing to have a very fast clock speed to make it through all the movements in the file. The reason that it's not very efficient is because parsing strings require using system tasks like 
``` $fgets ```
These tasks operate sequentially and are relatively slow in simulation, so processing a large input file with thousands of lines made the testbench runtime noticeably long and caused it to automatically timeout. However, I was able to get around this by making my clock at 50GHz. I would like to note that this limitation is specific to the testbench and simulation environment in Vivado. On actual hardware, the design itself would not operate on strings and files. The testbench simply serves as a bridge to convert the text input into signals that the RTL can consume. There were approximately 4400 instructions, so on real hardware, if the clock was at 50MHz (20 ns per cycle), and each instruction took ~5 cycles, it would take 22000 cycles to get through everything. 22000 * 20 ns = 440 microseconds, which is under a millisecond.

## How it Works

The design maintains the dial position in the range 0–99 and updates it according to a direction (L or R) and a distance. The distance is reduced modulo 100 using a binary-decomposition method to avoid expensive division/modulo logic in hardware. The design also tracks the number of times the dial reaches zero.

The testbench reads the input file in batches (500 lines at a time) and parses each line to extract the direction and distance. The testbench reads the input file in batches of 500 lines rather than all at once because string handling in SystemVerilog is relatively slow in simulation. Parsing thousands of lines sequentially can make the simulation extremely long, especially when using `$fgets` to extract direction and distance from each line.

Processing the input in smaller batches reduces memory overhead and improves simulation responsiveness. After each batch, the testbench prints intermediate results, allowing us to monitor progress without waiting for the entire file to be processed, in addition to helping with debugging. This batching strategy ensures that even very large input files can be handled efficiently in simulation, without affecting the correctness of the design itself. Each instruction is then applied to the module sequentially. The testbench uses `$fgets` for simulation purposes.

## Metrics

This design uses the following resources:
1. 235 LUTs
2. 32 FFs
3. 44 IOs
4. 1 BUFG

## How to Run It

To run the design, you can use any SystemVerilog simulator that supports file I/O. I would recommend Vivado since this design was built in Vivado.

1. Download the `sequential.sv`, `sequential_tb.sv`, and `input.txt`
2. Open Vivado, make a new project with any board/part (won't matter for simulation), and make `sequential.sv` a design source. Make `sequential_tb.sv` and `input.txt` simulations sources.
3. Run simulation. You can look at the waveform and the log.
