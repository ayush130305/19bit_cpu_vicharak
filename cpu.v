`timescale 1ns / 1ps

module cpu(
    input clk,
    input rst,
    input [18:0] instr
    );


reg[18:0] pc;
reg[18:0] reg_file[0:15];

wire[4:0] opcode=instr[18:14];
wire[3:0] R=instr[13:10];
wire[2:0] r1=instr[9:7];
wire[2:0] r2=instr[6:4];

wire[18:0] alu_op;
wire alu_z,alu_c;

alu main(
    .a(reg_file[r1]),
    .b(reg_file[r2]),
    .op(opcode),
    .result(alu_op),
    .carry(alu_c),
    .zero(alu_z) 
);

integer i;

always @(posedge clk or posedge rst) begin
    if(rst) begin   pc<=10'b0;
    
    for(i=0;i<16;i=i+1) begin
        reg_file[i]<=19'b0;
    end
end else begin  
    case(opcode)
    //ALU
        5'b00000, 5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101, 5'b00110,
        5'b00111, 5'b01000, 5'b01001, 5'b01010: begin
        
        reg_file[R]<=alu_op;
        pc<=pc+1;
        end
        
        default: pc<=pc+1;
    
   endcase
  end
 end   
endmodule