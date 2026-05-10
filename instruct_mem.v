`timescale 1ns / 1ps



module imem(
input wire clk,
input wire [13:0] addr,
output reg [18:0] data_out
);

    reg [18:0] mem [0:1023];
    always @(posedge clk) 
        data_out <= mem[addr];
        
    initial begin: init
    integer i;
    for(i=0; i<1024; i=i+1)
        mem[i] = 19'd0;
    end
    
endmodule