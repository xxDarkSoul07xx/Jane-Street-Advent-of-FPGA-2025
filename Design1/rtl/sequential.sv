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

// figure out how to read files
// distance and possibly direction will be affected?
module sequential(
    input logic clk,
    input logic rst_n,
    input logic valid,
    input logic direction, // 1 is right, 0 is left
    input logic [15:0] distance, // 16 bits should be enough for how far left or right to move
    output logic ready,
    output logic [15:0] zero_count // same here 16 bits should be enough
    );
    
    logic [6:0] position; // 0-99 so we need 7 bits to represent them
    logic signed [17:0] temp_pos; // temp holder for the position (to help deal with if our position after moving the distance is >= 100 or < 0)
    logic direction_reg; // copy over the direction and distance from inputs for internal use in case original inputs change
    logic [15:0] distance_reg;
    
    typedef enum logic [2:0] {idle, extract, calculate, edit, check} statetype; // states for the fsm
    statetype state, nextstate;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // reset: state is idle, initial position on dial is 50, set zero_count to 0, and ready to 0
            state <= idle;
            position <= 7'd50;
            zero_count <= 16'd0;
            ready <= 1'b0;
        end else begin
            state <= nextstate; // if not reset, go to the next state
        end
    end
    
    always_comb begin
        nextstate = state; // by default, stay in the current state
        case (state)
            idle: begin
                if (valid) nextstate = extract;
            end
            extract: begin
                nextstate = calculate;
            end
            calculate: begin
                nextstate = edit;
            end
            edit: begin
                if (temp_pos >= 100 || temp_pos < 0)
                    nextstate = edit; // keep looping until temp_pos is between 0-99 inclusive
                else
                    nextstate = check;
            end
            check: begin
                nextstate = idle; // when done, go back to idle
            end
            default: nextstate = idle; // by default, go back to idle
        endcase
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // don't need anything since we already handled rst_n
        end else begin
            case (state)
                idle: begin
                    ready <= 1'b1; // get ready for the next data
                end
                extract: begin
                    direction_reg <= direction; // copy the inputs
                    distance_reg <= distance;
                    ready <= 1'b0;
                end
                calculate: begin
                    if (direction_reg == 1'b1) begin
                        temp_pos <= position + distance_reg; // right
                    end else begin
                            temp_pos <= position - distance_reg; // left
                    end
                end
                edit: begin
                // figure out our new locations in the case that we wrap around
                    if (temp_pos >= 100) begin
                        temp_pos <= temp_pos - 100; // wrapped from 99 to 0
                    end else if (temp_pos < 0) begin
                        temp_pos <= temp_pos + 100; // wrapped from 0 to 99
                    end else begin
                        position <= temp_pos[6:0]; // if in range, update our position
                    end
                end
                check: begin
                    if (position == 7'd0) begin // check if our position is at 0
                        zero_count <= zero_count + 16'd1; // if it is, add one to zero_count
                    end
                end
            endcase
        end
    end                         
endmodule
