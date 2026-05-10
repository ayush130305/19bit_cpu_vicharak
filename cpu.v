`timescale 1ns / 1ps

module cpu(
    input wire clk,
    input wire rst,
    
    output reg [13:0] imem_addr,
    input wire [18:0] imem_data,
    
    input wire [18:0] dmem_data_in,
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
reg [13:0] exmem_mem_addr;

reg [18:0] memwb_result;
reg memwb_wb_en;
reg [3:0] memwb_dest;

reg [18:0] alu_a,alu_b;
reg [4:0] alu_op;
wire [18:0] alu_result;
wire alu_carry, alu_zero;

alu main(
    .a(alu_a),
    .b(alu_b),
    .op(idex_opcode),
    .result(alu_result),
    .carry(alu_carry),
    .zero(alu_zero) 
);

//fft and xor encryption

reg fft_start;
reg [13:0] fft_src_base, fft_dst_base;
wire [13:0] fft_mem_addr;
wire [18:0] fft_mem_data_out;
wire fft_mem_write_en, fft_done;

reg xor_start, xor_enc_mode;
reg [13:0] xor_src_base, xor_dst_base;
wire [13:0] xor_mem_addr;
wire [18:0] xor_mem_data_out;
wire xor_mem_write_en, xor_done;

fft_unit u_fft(
.clk(clk), .rst(rst), .start(fft_start), .src_base(fft_src_base), .dst_base(fft_dst_base), .mem_data_in(dmem_data_in),
.mem_addr(fft_mem_addr), .mem_data_out(fft_mem_data_out), .mem_write_en(fft_mem_write_en), .done(fft_done)
);

encryption u_xor(
.clk(clk), .rst(rst), .start(xor_start),.enc_mode(xor_enc_mode), .src_base(xor_src_base), .dst_base(xor_dst_base), .mem_data_in(dmem_data_in),
.mem_addr(xor_mem_addr), .mem_data_out(xor_mem_data_out), .mem_write_en(xor_mem_write_en), .done(xor_done)
);

reg unit_active;
reg unit_sel;

//decode stage
wire [4:0] dec_opcode = ifid_instr[18:14];
wire [3:0] dec_r = ifid_instr[13:10];
wire [3:0] dec_r1 = ifid_instr[9:6];
wire [3:0] dec_r2 = ifid_instr[5:2];
wire [13:0] dec_addr_field = ifid_instr[13:0];


//data forwarding logic
reg [18:0] fwd_op_a, fwd_op_b;
always @(*) begin
fwd_op_a= reg_file[dec_r1];
fwd_op_b= reg_file[dec_r2];

//execute/memory forwarding
if(exmem_wb_en &&(exmem_dest!=4'd0)&&(exmem_dest==dec_r1))
fwd_op_a=exmem_result;
else if (memwb_wb_en &&(memwb_dest!=4'd0)&&(memwb_dest==dec_r1))
fwd_op_a=memwb_result;

if(exmem_wb_en &&(exmem_dest!=4'd0)&&(exmem_dest==dec_r2))
fwd_op_b=exmem_result;
else if (memwb_wb_en &&(memwb_dest!=4'd0)&&(memwb_dest==dec_r2))
fwd_op_b=memwb_result;

end

//alu input
always @(*) begin
alu_op=idex_opcode;
alu_a=idex_op_a;
alu_b=idex_op_b;
end

//stalling logic
wire load_use_stall= exmem_mem_op && exmem_is_load && ((exmem_dest==idex_r1)||(exmem_dest==idex_r2))&&(exmem_dest!=4'd0);
wire stall =load_use_stall || unit_active;

//execute 
wire beq_taken= (idex_opcode == op_beq) && (idex_op_a==idex_op_b);
wire bne_taken= (idex_opcode == op_bne) && (idex_op_a!=idex_op_b);
wire branch_taken = beq_taken || bne_taken;

wire ex_is_jump= (idex_opcode== op_jmp)||(idex_opcode==op_call)||(idex_opcode==op_ret);

wire flush_pipe= branch_taken || ex_is_jump;

//dmem
always @(*) begin
 if (unit_active && unit_sel==1'b0) begin
    dmem_addr=fft_mem_addr;
    dmem_data_out=fft_mem_data_out;
    dmem_write_en=fft_mem_write_en;
 end else if (unit_active && unit_sel==1'b1) begin
    dmem_addr=xor_mem_addr;
    dmem_data_out=xor_mem_data_out;
    dmem_write_en=xor_mem_write_en;
 end else begin
    dmem_addr=exmem_mem_addr;
    dmem_data_out=exmem_store_data;
    dmem_write_en=exmem_mem_op&& !exmem_is_load;
 end
end      

integer idx;

always @(posedge clk) begin
    if (rst) begin
        pc <=14'd0;
        imem_addr <= 14'd0;
        ifid_instr <= 19'd0;
        flush_next <= 1'b0;
        
        idex_op_a <= 19'd0;
        idex_op_b <= 19'd0;
        idex_opcode <= 5'd0;
        idex_r <= 4'd0;
        idex_r1 <= 4'd0;
        idex_r2 <= 4'd0;
        idex_addr <=14'd0;
        idex_pc <= 14'd0;
        
        exmem_result <= 19'd0;
        exmem_wb_en <= 1'b0;
        exmem_dest <= 4'd0;
        exmem_mem_op <= 1'b0;
        exmem_is_load <= 1'b0;
        exmem_store_data <= 19'd0;
        exmem_mem_addr <= 14'd0;
        
        memwb_result <= 19'd0;
        memwb_wb_en <= 1'b0;
        memwb_dest <= 4'd0;
        
        sp <= 4'd0;
        unit_active <= 1'b0;
        unit_sel <= 1'b0;
        fft_start <=1'b0;
        fft_src_base <=14'd0;
        fft_dst_base <= 14'd0;
        xor_start <= 1'b0;
        xor_enc_mode <= 1'b0;
        xor_src_base <= 14'd0;
        xor_dst_base <= 14'd0;
        
        for(idx=0;idx<16;idx=idx+1)
            stack[idx] <= 19'd0;
            
        end else begin
            fft_start <= 1'b0;
            xor_start <= 1'b0;
            
            if(unit_active) begin
                if((unit_sel==1'b0 && fft_done) || (unit_sel==1'b1 && xor_done)) 
                    unit_active <= 1'b0;
                    
            end else if (!stall) begin
                if(exmem_mem_op && exmem_is_load)
                memwb_result <= dmem_data_in;
                else
                memwb_result <= exmem_result;
                memwb_wb_en <= exmem_wb_en;
                memwb_dest <= exmem_dest;
                
                
                exmem_wb_en<=1'b0;
                exmem_mem_op<=1'b0;
                exmem_is_load<=1'b0;
                exmem_result<=19'd0;
                exmem_dest<=4'd0;
                exmem_store_data<=19'd0;
                exmem_mem_addr<=14'd0;
                
                case (idex_opcode)
                op_add, op_sub, op_mul, op_div, op_rem, op_and, op_or, op_xor: begin
                exmem_result<=alu_result;
                exmem_wb_en<=1'b1;
                exmem_dest<=idex_r;
                end
                
                op_inc:begin      
                exmem_result<=idex_op_a+19'd1;
                exmem_wb_en<=1'b1;
                exmem_dest<=idex_r;    
                end
                
                op_dec: begin
                exmem_result<=idex_op_a-19'd1;
                exmem_wb_en<=1'b1;
                exmem_dest<=idex_r;
                end
                
                op_not: begin
                exmem_result<= ~idex_op_a;
                exmem_wb_en<=1'b1;
                exmem_dest<=idex_r;  
                end             
                
                op_load: begin
                exmem_mem_op<=1'b1;
                exmem_is_load<=1'b1;
                exmem_mem_addr<=idex_addr;
                exmem_dest<=idex_r;
                exmem_wb_en<=1'b1;
                end
                
                op_store: begin
                exmem_mem_op<=1'b1;
                exmem_is_load<=1'b0;
                exmem_mem_addr<=idex_addr;
                exmem_store_data<=idex_op_a;
                exmem_wb_en<=1'b0;
                end
                
                op_jmp: begin
                end
                
                op_beq: begin
                end
                
                op_bne: begin
                end
                
                op_call: begin
                stack[sp]<={5'd0,idex_pc};
                sp<=sp+4'd1;
                end
                
                op_ret:begin
                end
                
                op_fft: begin
                fft_src_base<=idex_op_b[13:0];
                fft_dst_base<=idex_op_a[13:0];
                fft_start<=1'b1;
                unit_sel<=1'b0;
                unit_active<=1'b1;
                end
                
                op_enc: begin
                xor_src_base<=idex_op_b[13:0];
                xor_dst_base<=idex_op_a[13:0];
                xor_enc_mode<=1'b1;
                xor_start<=1'b1;
                unit_sel<=1'b1;
                unit_active<=1'b1; 
                end
                
                op_decr: begin
                xor_src_base<=idex_op_b[13:0];
                xor_dst_base<=idex_op_a[13:0];
                xor_enc_mode<=1'b0;
                xor_start<=1'b1;
                unit_sel<=1'b1;
                unit_active<=1'b1;                 
                end               
                
                default : begin
                end
                endcase
                
                if(flush_pipe) begin
                    if (idex_opcode == op_ret) begin
                    pc<=stack[sp-4'd1][13:0];
                    imem_addr<=stack[sp-4'd1][13:0];
                    sp<=sp-4'd1;
                end else begin
                    pc<=idex_addr;
                    imem_addr<=idex_addr;
                end
          end
          
          if(flush_pipe) begin
          ifid_instr<=19'd0;
          idex_op_a<=19'd0;
          idex_op_b<=19'd0;
          idex_opcode<=5'd0;
          idex_r<=4'd0;
          idex_r1<=4'd0;
          idex_r2<=4'd0;
          idex_addr<=14'd0;
          idex_pc<=14'd0;
          
          flush_next <=1'b1;
          end else begin
          
          if (load_use_stall) begin
          ifid_instr<=19'd0;
          idex_op_a<=19'd0;
          idex_op_b<=19'd0;
          idex_opcode<=5'd0;
          idex_r<=4'd0;
          idex_r1<=4'd0;
          idex_r2<=4'd0;
          idex_addr<=14'd0;
          idex_pc<=14'd0;  
          
          end else begin 
          idex_op_a<=fwd_op_a;
          idex_op_b<=fwd_op_b;
          idex_opcode<=dec_opcode;
          idex_r<=dec_r;
          idex_r1<=dec_r1;
          idex_r2<=dec_r2;
          idex_addr<=dec_addr_field;
          idex_pc<=pc;
          
          
          if(flush_next) begin
          ifid_instr<=19'd0;
          flush_next<=1'b0;
          
          imem_addr<= pc+14'd1;
          
          end else begin
          
          ifid_instr<=imem_data;
          pc<=pc+14'd1;
          imem_addr<=pc+14'd1;
          end
          end
          end
          
          end else begin
            if(load_use_stall && !unit_active) begin
                if(exmem_mem_op && exmem_is_load)
                    memwb_result<=dmem_data_in;
                else          
                
                memwb_result<=exmem_result;
                memwb_wb_en<=exmem_wb_en;
                memwb_dest<=exmem_dest;
                
                exmem_wb_en<=1'b0;
                exmem_mem_op<=1'b0;
                exmem_is_load<=1'b0;
                exmem_result<=19'd0;
                exmem_dest<=4'd0;
                exmem_store_data<=19'd0;
                exmem_mem_addr<=14'd0;
                
                idex_op_a<=19'd0;
                idex_op_b<=19'd0;
                idex_opcode<=5'd0;
                idex_r<=4'd0;
                idex_r1<=4'd0;
                idex_r2<=4'd0;
                idex_addr<=14'd0;
                idex_pc<=14'd0;
                end
                end
                end
                end
                
                integer widx;
                always @(posedge clk) begin
                if (rst) begin
                    for(widx=0;widx<16;widx=widx+1)
                    reg_file[widx]<=19'd0;
                    end else begin
                    if(memwb_wb_en && (memwb_dest !=4'd0))
                    reg_file[memwb_dest]<=memwb_result;
                    end
                    end
    //
          
endmodule
