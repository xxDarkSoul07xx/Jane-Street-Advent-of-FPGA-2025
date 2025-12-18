`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/16/2025 12:48:23 PM
// Design Name: 
// Module Name: design1_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sequential2_tb;
    logic clk; // declaring the signals
    logic rst_n;
    logic valid;
    logic direction;
    logic [15:0] distance;
    logic ready;
    logic [15:0] zero_count;
    logic [6:0] position;
    
    // instantiate the dut and connect the local signals in the testbench tot he dut's ports
    sequential2 dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid),
        .direction(direction),
        .distance(distance),
        .ready(ready),
        .zero_count(zero_count),
        .position(position)
    );
    
    // make the clock
    // make it a forever clock (period is 20 ps, freq = 50GHz)
    initial begin
        clk = 0;
        forever #0.01 clk = ~clk;
    end
    
    // gonna do it in batches of 500 so that we aren't overloading the memory
    initial begin
        integer fd, line_num, batch_count; // initialize the file descriptor, total lines processed, and which batch we are on
        string lines[500];  // gonna temporarily store a batch of 500 lines
        integer batch_size; // number of lines read in the current batch
        
        $display("batch processing");
        
        // reset stuff
        rst_n = 0;
        valid = 0;
        #10;
        rst_n = 1;
        #10;
        
        fd = $fopen("input.txt", "r"); // open up input.txt and if it can't be opened, let us know
        if (fd == 0) begin
            $display("can't open input.txt");
            $finish;
        end
        
        line_num = 0; // initialize our counters
        batch_count = 0;
        
        // process the input we got in batches of 500 lines each until we did it all
        while (1) begin // use while (1) to loop until we get to the end of the file
            // read a batch
            batch_size = 0;
            for (integer i = 0; i < 500; i = i + 1) begin
                if ($fgets(lines[i], fd) == 0) break;
                batch_size = batch_size + 1;
            end
            
            if (batch_size == 0) break;  // if nothing was read, end the loop because that should be the end of the file
            
            // go through the current batch
            for (integer i = 0; i < batch_size; i = i + 1) begin
                automatic string line = lines[i];
                
                // get rid of the newline characters so that the parsing works
                if (line.len() > 0 && line.getc(line.len()-1) == "\n") begin
                    line = line.substr(0, line.len()-2);
                end
                
                // reads the first character of the line and convert the rest to an integer to get the distance the dial should move
                if (line.len() > 0) begin
                    if (line.getc(0) == "R") begin
                        direction = 1;
                    end else if (line.getc(0) == "L") begin
                        direction = 0;
                    end else begin
                        continue; // if the line is invalid, just skip over it
                    end
                    distance = line.substr(1, line.len()-1).atoi();
                    
                    // send the inputs to the dut
                    @(posedge clk); // wait a clock cycle, make valid = 1, wait another clock, and make valid = 0
                    valid = 1'b1;
                    @(posedge clk);
                    valid = 1'b0;
                    wait(ready == 1'b1);
                    line_num = line_num + 1; // + 1 lines have been processed now
                end
            end
            
            batch_count = batch_count + 1; // after each batch, print which batch we are currently on, how many lines we have processed, and the current zero_count
            $display("Batch %0d: %0d lines total, pos=%0d, zeros = %0d", 
                     batch_count, line_num, position, zero_count);
        end
        
        $fclose(fd); // close the file
        $display("Batches: %0d", batch_count);
        $display("Total lines: %0d", line_num);
        $display("final position: %0d", position);
        $display("zero_count: %0d", zero_count); // show the data and the result
        $finish;
    end
    
    initial begin
        #1000000; // timeout if there's an infinite loop or some random error
        $display("timed out");
        $finish;
    end
endmodule
