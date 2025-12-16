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


module design1(
    input logic clk,
    input logic rst_n,
    input logic valid,
    input logic direction,
    input logic [15:0] distance,
    output logic ready,
    output logic [15:0] zero_count
    );
    
    logic [6:0] position;
    logic [17:0] temp_pos;
    
    typedef enum logic [2:0] {idle, extract, calculate, edit, check} statetype;
    statetype state, nextstate;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (rst_n) begin
            state <= idle;
        end else begin
            state <= nextstate;
        end
    end
    
    always_comb begin
        nextstate = state;
        case (state)
            idle: begin
                if (valid) nextstate = extract;
                else nextstate = idle;
            end
            extract: begin //come back to here
                nextstate = calculate;
            end
            calculcate: begin
                nextstate = edit;
            end
            edit: begin
                if (temp_pos >= 100) begin
                    temp_pos = temp_pos - 100;
                    nextstate = edit;
                end
                if (temp_pos < 0) begin
                    temp_pos = temp_pos + 100;
                    nextstate = edit;
                end else begin
                    position = temp_pos;
                    nextstate = check;
                end
            end
            check: begin // figure out where to go after this
                if (position == 0) begin
                    zero_count = zero_count + 1;
                    //nextstate here
                end else begin
                    //another nextstate here
                end
            end
    
          endmodule
