`timescale 1ns / 1ps

module cpu(
    input wire clk,
    input wire rst,
    
    output reg [13:0] imem_addr,
    input wire [18:0] imem_data,
    
    input [18:0] dmem_data_in,
    output reg[13:0] dmem_addr,
    output reg[18:0] dmem_data_out,
    output reg dmem_write_en
    );

localparam [4:0]
op_add = 5'b00000,
op_sub = 5'b00001,
op_mul = 5'b00010,
op_div = 5'b00011,
op_rem = 5'b00100,
op_inc = 5'b00101,
op_dec = 5'b00110,
op_and = 5'b00111,
op_or = 5'b01000,
op_xor = 5'b01001,
op_not = 5'b01010,
op_jmp = 5'b01011,
op_beq = 5'b01100,
op_bne = 5'b01101,
op_call = 5'b01110,
op_ret = 5'b01111,
op_load = 5'b10000,
op_store = 5'b10001,
op_fft = 5'b10010,
op_enc = 5'b10011,
op_decr = 5'b10100;


reg[18:0] reg_file[0:15];

reg[3:0] sp;
reg[18:0] stack [0:15];

reg [13:0] pc;

reg flag_z,flag_c;

reg flush_next;

//PIPELINING 3 STAGE
reg [18:0] ifid_instr; // fetch (holds instruction)


reg [18:0] idex_op_a;
reg [18:0] idex_op_b;
reg [4:0] idex_opcode;
reg [3:0] idex_r;
reg [3:0] idex_r1;
reg [3:0] idex_r2;
reg [13:0] idex_addr;
reg [13:0] idex_pc;

reg [18:0] exmem_result;
reg exmem_wb_en;
reg [3:0] exmem_dest;
reg exmem_mem_op;
reg exmem_is_load;
reg [18:0] exmem_store_data;
reg [18:0] exmem_mem_addr;

reg [18:0] memwb_result;
reg memwb_wb_en;
reg [3:0] memwb_dest;




//encryption

wire enc_done;
wire enc_busy;
wire [18:0] enc_data_out;
reg enc_start;


//data forwarding logic

wire [18:0] op_a=(writeback_register && (dest_index == r1)) ? alu_result : reg_file[r1];
wire [18:0] op_b=(writeback_register && (dest_index == r2)) ? alu_result : reg_file[r2];

//stalling logic for load function

wire check_load = (opcode==5'b10000) && (mem_data_in[9:6] ==R || mem_data_in[5:2]==R);
//wire instr_needing_R= (mem_data_in[9:6]==R || (mem_data_in[5:2]==R));
wire stall = check_load || enc_busy;

encryption XTEA(
    .clk(clk),
    .rst(rst),
    .start(enc_start),
    .data_in(op_a), //plain text
    .key(op_b), //key
    .data_out(enc_data_out),
    .busy(enc_busy),
    .done(enc_done)

);




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
        instr_register=19'h7FFFF;
        mem_addr <= 14'b0;
    end else if(!stall) begin
        mem_addr <= pc[13:0];
        instr_register <= mem_data_in;
        pc<=pc+1;
    end  

 end

//DECODE/EXECUTE
always @(posedge clk or posedge rst) begin
    if(rst) begin
//        pc <= 19'b0;
        sp <= 4'b0;
        alu_result <= 19'b0;
        dest_index <= 4'b0;
        instr_register<= 19'b0;
        writeback_register <= 1'b0;
        flag_z <= 1'b0;
        flag_c <= 1'b0;
        mem_write_en <= 1'b0;
        enc_start<=0;
    end else begin
//        instr_register <= mem_data_in; //takes data from RAM   
        writeback_register <= 1'b0;
        mem_write_en <= 1'b0;
        enc_start<=0;
        
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
        5'b00101, 5'b00110: begin
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
        if(op_a==op_b) begin
        pc<=addr_field;
        instr_register<=19'b0;
        end else if (!stall) pc<=pc+1;
        end
        
        5'b01101: begin //bne
        if(op_a!=op_b) begin 
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
       mem_addr <= addr_field;
       mem_data_out <= op_a;
       mem_write_en <= 1'b1;
       writeback_register<=1'b0;
       if (!stall) pc<=pc+1;
       end
       
       5'b10010: begin //encryption
       if(!enc_busy && !enc_done) begin
       enc_start <=1;
       writeback_register<=0;
       end else if(enc_done) begin
       alu_result<=enc_data_out;
       dest_index<=R;
       writeback_register<=1;
       pc<=pc+1;
       end else begin
       writeback_register<=0;
       end
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