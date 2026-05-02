`timescale 1ns / 1ps
module cpu_tb();
    reg clk;
    reg rst;
    wire [18:0] mem_data_bus_in;
    wire [18:0] mem_data_bus_out;
    wire [13:0] mem_addr_bus;
    wire mem_we;
    
cpu processor(
    .clk(clk),
    .rst(rst),
//    .instr(instr)
    .mem_data_in(mem_data_bus_in),
    .mem_addr(mem_addr_bus),
    .mem_data_out(mem_data_bus_out),
    .mem_write_en(mem_we)
);

ram memory(
    .clk(clk),
    .addr(mem_addr_bus),
    .data_in(mem_data_bus_out),
    .write_en(mem_we),
    .data_out(mem_data_bus_in)
);

always #5 clk=~clk;

    initial begin
 // opcode(5 bits) | r(4 bits) | r1(4bits) |r2(4bits) or address (14bits)
 
 memory.mem[0]={5'b10000,4'd1,10'b0};
 memory.mem[1]={5'b10001,4'd1,14'd100};
 memory.mem[2]={5'b01110,14'd5};
 memory.mem[5]={5'b01111,14'b0};
 memory.mem[3]={5'b01011,14'd10};
 
 clk=0;
 rst=1;
 #10 rst=0;
 
 #200;
    end

//wire[18:0]R0=uut.reg_file[0];
//wire[18:0]R1=uut.reg_file[1];
//wire[18:0]R2=uut.reg_file[2];
//wire[18:0]R3=uut.reg_file[3];
//wire[18:0]R4=uut.reg_file[4];
//wire[18:0]R5=uut.reg_file[5];
//wire[18:0]R6=uut.reg_file[6];
//wire[18:0]R7=uut.reg_file[7];
//wire[18:0]R8=uut.reg_file[8];
//wire[18:0]R9=uut.reg_file[9];
//wire[18:0]R10=uut.reg_file[10];
//wire[18:0]R11=uut.reg_file[11];

//always #5 clk=~clk;

//initial begin

//clk=0 ;rst=1 ;instr=0;
//#20 rst=0;

////inc (r1=10,r2=5)
//repeat(10) begin instr={5'b00101,4'd1,3'd1,3'd0,4'b0};#10;end
//repeat(5) begin instr={5'b00101,4'd2,3'd2,3'd0,4'b0};#10;end

////add,sub,mul,divide,remainder
//instr={5'b00000,4'd3,3'd1,3'd2,4'b0}; #10;
//instr={5'b00001,4'd4,3'd1,3'd2,4'b0}; #10;
//instr={5'b00010,4'd5,3'd1,3'd2,4'b0}; #10;
//instr={5'b00011,4'd6,3'd1,3'd2,4'b0}; #10;
//instr={5'b00100,4'd7,3'd1,3'd2,4'b0}; #10;

////dec (r1=9)
//instr={5'b00110,4'd0,3'd1,3'd0,4'b0}; #10;

////and,or,xor,nor
//instr={5'b00111,4'd8,3'd1,3'd2,4'b0}; #10;
//instr={5'b01000,4'd9,3'd1,3'd2,4'b0}; #10;
//instr={5'b01001,4'd10,3'd1,3'd2,4'b0}; #10;
//instr={5'b01010,4'd11,3'd1,3'd0,4'b0}; #10;

//#20;

//end



endmodule
