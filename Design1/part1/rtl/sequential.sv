`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/15/2025 08:24:12 PM
// Design Name: 
// Module Name: design1
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

module sequential(
    input logic clk,
    input logic rst_n,
    input logic valid, // a signal to let us know that a new movement request is ready
    input logic direction, // 1 is right, 0 is left
    input logic [15:0] distance, // 16 bits should be enough for how far left or right to move
    output logic ready, // lets us know that we can accept a new move
    output logic [15:0] zero_count, // same here 16 bits should be enough
    output logic [6:0] position // for where the dial is currently at
    );
    
    logic [6:0] new_pos;  // the possible next position
    logic [6:0] distance_mod; // distance % 100 to make it 0-99
    logic busy; // 1 is that a move is processing, 0 is we are idle
    
    // Declare variables at module level
    logic [15:0] temp; // for distance calculation
    logic [7:0] temp_sum; // for position calculation
    
    // do distance mod 100
    always_comb begin
        temp = distance; // No local declaration needed
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
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            position <= 7'd50; // start the dial at 50
            zero_count <= 16'd0; // initialize our result and set it to 0
            ready <= 1'b1; // we are ready and not busy (because we just started)
            busy <= 1'b0;
        end else begin
            if (busy) begin // if we are busy, position = new_pos and check if it's 0
                position <= new_pos;
                if (new_pos == 7'd0) begin
                    zero_count <= zero_count + 16'd1;
                end
                busy <= 1'b0; // now we are not busy and ready again
                ready <= 1'b1;
            end else if (valid && ready) begin
                if (direction) begin // we can say if (direction) because R was 1 and L was 0
                    // if it is R: (position + distance_mod) % 100
                    temp_sum = position + distance_mod;
                    if (temp_sum >= 8'd100) begin
                        new_pos = temp_sum - 8'd100; // if we are out of range, subtract 100
                    end else begin
                        new_pos = temp_sum[6:0]; // if in range, set our new_pos to the temp_sum
                    end
                end else begin
                    // if it is L: (position - distance_mod) % 100
                    if (position >= distance_mod) begin
                        new_pos = position - distance_mod; // no wrapping around so just do the calculation
                    end else begin
                        new_pos = 7'd100 - (distance_mod - position); // for if wrapping around is needed
                    end
                end
                busy <= 1'b1; // set busy to 1 and ready to 0 at the end because we are executing a move and don't want to accept another one yet
                ready <= 1'b0;
            end
        end
    end
endmodule
