`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2026 11:50:20 AM
// Design Name: 
// Module Name: data_mem
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


module data_mem(
input wire clk,
input wire [13:0] addr,
input wire [18:0] data_in,
input wire write_en,
output reg[18:0] data_out

    );


    reg [18:0] mem[0:1023];
    
    always @(posedge clk) begin
        if(write_en) 
            mem[addr]<=data_in;
          data_out <= mem[addr];
    end
    

    initial begin : init
        integer i;
        for (i=0;i<1024;i=i+1) 
            mem[i]=19'd0;
        end
            
            
endmodule