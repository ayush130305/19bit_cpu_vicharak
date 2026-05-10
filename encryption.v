`timescale 1ns / 1ps

module encryption(
    input wire clk,
    input wire rst,
    input wire start,
    input wire enc_mode,
    input wire [13:0] src_base,
    input wire [13:0] dst_base,
    input wire [18:0] mem_data_in,
    output reg [13:0] mem_addr,
    output reg mem_write_en,
    output reg [18:0] mem_data_out,
    output reg done
    );
    
    localparam [18:0] KEY0=19'h2A5F3, KEY1= 19'h1C8B7, KEY2=19'h3D1E6, KEY3=19'h0F4A2;
    
    localparam [3:0] 
        S_IDLE = 4'd0,
        S_LD0 = 4'd1,
        S_PROC0 = 4'd2,
        S_LD1 = 4'd3,
        S_WAIT1 = 4'd4,
        S_PROC1 = 4'd5,
        S_LD2 = 4'd6,
        S_WAIT2 = 4'd7,
        S_PROC2 = 4'd8,
        S_LD3 = 4'd9,
        S_WAIT3 = 4'd10,
        S_PROC3 = 4'd11,
        S_DONE = 4'd12;   
        
        reg [3:0] state;
        
        always @(posedge clk) begin
            if(rst) begin   
                state<=S_IDLE; done<=1'b0; mem_write_en<=1'b0;
                mem_addr<=14'd0; mem_data_out<=19'd0;
                end else begin
                done<=1'b0;
                mem_write_en<=1'b0;
                case (state)
                S_IDLE: begin
                if(start) begin mem_addr<=src_base;state<=S_LD0; end
                end
                S_LD0: begin
                state<= S_PROC0;
                end
                S_PROC0: begin
                mem_addr<=dst_base;
                mem_data_out<=mem_data_in ^ KEY0;
                mem_write_en<=1'b1;
                state<= S_LD1;
                end
                S_LD1: begin
                mem_addr<=src_base + 14'd1;
                state<=S_WAIT1;
                end
                S_WAIT1: begin state<= S_PROC1; end
                
                S_PROC1: begin
                mem_addr<=dst_base+14'd1;
                mem_data_out<=mem_data_in ^ KEY1;
                mem_write_en<=1'b1;
                state<= S_LD2;
                end
                S_LD2: begin
                mem_addr<=src_base + 14'd2;
                state<=S_WAIT2;
                end
                S_WAIT2: begin state<= S_PROC2; end                
                S_PROC2: begin
                mem_addr<=dst_base+14'd2;
                mem_data_out<=mem_data_in ^ KEY2;
                mem_write_en<=1'b1;
                state<= S_LD3;
                end
                S_LD3: begin
                mem_addr<=src_base + 14'd3;
                state<=S_WAIT3;
                end
                S_WAIT3: begin state<= S_PROC3; end
                S_PROC3: begin
                mem_addr<=dst_base+14'd3;
                mem_data_out<=mem_data_in ^ KEY3;
                mem_write_en<=1'b1;
                state<= S_DONE;
                end
                S_DONE: begin done<=1'b1; state<=S_IDLE; end 
                default: state<=S_IDLE;
                endcase
                end
                end
                         //                                    
endmodule
