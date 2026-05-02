`timescale 1ns / 1ps

module ram(
input clk,
input [13:0] addr,
input [18:0] data_in,
input write_en,
output reg[18:0] data_out
    );
    
    reg [18:0] mem[0:1023];
    
    always @(posedge clk) begin
        if(write_en) begin
            mem[addr]<=data_in;
          end
          data_out <= mem[addr];
    end
    
    integer i;
    initial begin
        for (i=0;i<1024;i=i+1) begin
            mem[i]=19'b0;
            end
        end
endmodule
