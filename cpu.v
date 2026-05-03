`timescale 1ns / 1ps

module cpu(
    input clk,
    input rst,
    input [18:0] mem_data_in,
    output reg[13:0] mem_addr,
    output reg[18:0] mem_data_out,
    output reg mem_write_en
    );


reg[18:0] pc;
reg[3:0] sp;
reg[18:0] reg_file[0:15];
reg[18:0] stack [0:15];
reg flag_z,flag_c;

//PIPELINING 3 STAGE
reg [18:0] instr_register; // fetch (holds instruction)
reg [18:0] alu_result; // decode/execute (holds alu result)
reg [3:0] dest_index; // decode/execute (holds destination register index)
reg writeback_register; //write back (controls write back signal)


wire[4:0] opcode=instr_register[18:14];
wire[3:0] R=instr_register[13:10];
wire[3:0] r1=instr_register[9:6];
wire[3:0] r2=instr_register[5:2];
wire [13:0] addr_field=instr_register[13:0];

//data forwarding logic

wire [18:0] op_a=(writeback_register && (dest_index == r1)) ? alu_result : reg_file[r1];
wire [18:0] op_b=(writeback_register && (dest_index == r2)) ? alu_result : reg_file[r2];

//stalling logic for load function

wire check_load = (opcode==5'b10000);
wire instr_needing_R= (mem_data_in[9:6]==R || (mem_data_in[5:2]==R));
wire stall = check_load && instr_needing_R;



wire[18:0] alu_op;
wire alu_z,alu_c;

alu main(
    .a(op_a),
    .b(op_b),
    .op(opcode),
    .result(alu_op),
    .carry(alu_c),
    .zero(alu_z) 
);


//FETCH
always @(posedge clk or posedge rst) begin
    if (rst) begin 
        pc <= 19'b0;
        instr_register=19'b0;
        mem_addr <= 14'b0;
    end else if(!stall) begin
        mem_addr <= pc[13:0];
        instr_register <= mem_data_in;
    end else begin 
    instr_register <= 19'b0;
    end
end

//DECODE/EXECUTE
always @(posedge clk or posedge rst) begin
    if(rst) begin
//        pc <= 19'b0;
        sp <= 4'b0;
        alu_result <= 19'b0;
        dest_index <= 4'b0;
//        instr_register<= 19'b0;
        writeback_register <= 1'b0;
        flag_z <= 1'b0;
        flag_c <= 1'b0;
        mem_write_en <= 1'b0;
    end else begin
//        instr_register <= mem_data_in; //takes data from RAM   
        writeback_register <= 1'b0;
        mem_write_en <= 1'b0;
        
        case(opcode)
    //ALU (ADD,SUB,MUL,DIV,REM,AND,OR,XOR,NOT)
        5'b00000, 5'b00001, 5'b00010, 5'b00011, 5'b00100,
        5'b00111, 5'b01000, 5'b01001, 5'b01010: begin
        
        alu_result <= alu_op;
        dest_index <= R;
        writeback_register <= 1'b1;
        flag_z <= alu_z;
        flag_c <= alu_c;
//        reg_file[R]<=alu_op;
        if (!stall) pc<=pc+1;
        end
        
        //inc,dec
        5'b00100, 5'b00101: begin
        alu_result <= alu_op;
        dest_index <= R;
        writeback_register <= 1'b1;
        flag_z <= alu_z;
        pc <= pc+1;        
        end
        
        //control flow functions
        5'b01011: begin
        pc<=addr_field; //jmp
        instr_register<=19'b0 ;
        end
        
        5'b01100: begin //beq
        if(reg_file[r1]==reg_file[r2]) begin
        pc<=addr_field;
        instr_register<=19'b0;
        end else if (!stall) pc<=pc+1;
        end
        
        5'b01101: begin //bne
        if(reg_file[r1]!=reg_file[r2]) begin 
        pc<=addr_field;
        instr_register<=19'b0 ;   
        end else if (!stall) pc<=pc+1;
        end
        
        5'b01110: begin //call
        stack[sp]<=pc+1;
        sp<=sp+1;
        pc<=addr_field;
        instr_register<=19'b0 ;
        end
        
        5'b01111: begin //return
        pc<=stack[sp-1];
        sp<=sp-1;
        instr_register<=19'b0 ;
        end
        
        
        //mem access functions
        
       5'b10000: begin //load
       alu_result<=mem_data_in;
       dest_index<=R;
       writeback_register<=1'b1;
       if (!stall) pc<=pc+1;
       end
       
       5'b10001: begin //store
       alu_result<=mem_data_in;
       dest_index<=R;
       writeback_register<=1'b1;
       if (!stall) pc<=pc+1;
       end
       
        default: if (!stall) pc<=pc+1;
    
   endcase
   end
 end

// WRITE BACK
    always@ (posedge clk) begin
        if (writeback_register && !rst) begin
            reg_file[dest_index] <= alu_result;
        end
    end
    
        
//integer i;

//reg state; //for stageing pipeline

//always @(posedge clk or posedge rst) begin
//    if(rst) begin   
//    pc<=19'b0;
//    sp<=4'b0;
//    state<= 1'b0;
//    mem_write_en<=1'b0;
//    mem_addr<=14'b0;
    
//    for(i=0;i<8;i=i+1) stack[i]<=19'b0;
    
//    for(i=0;i<16;i=i+1) 
//        reg_file[i]<=19'b0;
//    end else begin  
//    if (state==1'b0) begin
    
//    mem_addr<=pc[13:0];
//    mem_write_en<=1'b0;
//    state<=1'b1;
//    end else begin
    
//    state<=1'b0;
    
    
//    case(opcode)
//    //ALU
//        5'b00000, 5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00101, 5'b00110,
//        5'b00111, 5'b01000, 5'b01001, 5'b01010: begin
        
//        reg_file[R]<=alu_op;
//        pc<=pc+1;
//        end
        
//        //control flow functions
//        5'b01011: pc<=addr_field; //jmp
        
//        5'b01100: begin //beq
//        if(reg_file[r1]==reg_file[r2]) pc<=addr_field;
//        else pc<=pc+1;
//        end
        
//        5'b01101: begin //bne
//        if(reg_file[r1]!=reg_file[r2])pc<=addr_field;
//        else pc<=pc+1;
//        end
        
//        5'b01110: begin //call
//        stack[sp]<=pc+1;
//        sp<=sp+1;
//        pc<=addr_field;
//        end
        
//        5'b01111: begin //return
//        pc<=stack[sp-1];
//        sp<=sp-1;
//        end
        
        
//        //mem access functions
        
//       5'b10000: begin //load
//       reg_file[R]<=mem_data_in;
//       pc<=pc+1;
//       end
       
//       5'b10001: begin //store
//       mem_addr<=addr_field;
//       mem_data_out<=reg_file[R];
//       mem_write_en<=1'b1;
//       pc<=pc+1;
//       end
       
//        default: pc<=pc+1;
    
//   endcase
//   end
//  end
// end   
endmodule