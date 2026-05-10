`timescale 1ns / 1ps

module alu(
input[18:0] a,
input[18:0] b,
input[4:0] op,
output reg[18:0] result,
output reg carry,
output zero

);

always @(*) begin
    result=19'b0;
    carry=1'b0;
    case(op)
    
        //arithmatic
        5'b00000: {carry,result}=a+b;
        5'b00001: {carry,result}=a-b;
        5'b00010: result=a*b;
        5'b00011: result= (b!=0)?(a/b):19'b0;
        5'b00100: result= (b!=0)?(a%b):19'b0;
        5'b00101: result=a+1;
        5'b00110: result=a-1;
        
        //logical
        5'b00111: result=a&b;
        5'b01000: result=a|b;
        5'b01001: result=a^b;
        5'b01010: result=~a;        
        
        default: result=19'b0;
        endcase
    
  end
  
  assign zero=(result==19'b0);
  
  endmodule      
        
