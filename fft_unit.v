`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2026 02:01:07 PM
// Design Name: 
// Module Name: fft_unit
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


module fft_unit(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [13:0] src_base,
    input wire [13:0] dst_base,
    input wire [18:0] mem_data_in,
    output reg [13:0] mem_addr,
    output reg mem_write_en,
    output reg [18:0] mem_data_out,
    output reg done
    );

reg signed [18:0] x0,x1,x2,x3;
reg signed [18:0] a0,a1,a2,a3;
reg signed [18:0] X0,X1,X2,X3;

localparam [4:0]
    S_IDLE = 5'd0,
    S_RD1 = 5'd1,   
    S_RD2 = 5'd2,
    S_RD3 = 5'd3,       
    S_RD4 = 5'd4,
    S_CAPTURE = 5'd5,        
    S_STAGE1 = 5'd6,
    S_STAGE2 = 5'd7,       
    S_WR0 = 5'd8,
    S_WR1 = 5'd9,
    S_WR2 = 5'd10,
    S_WR3 = 5'd11,    
    S_DONE = 5'd12;
    
reg [4:0] state;

always @(posedge clk) begin
    if (rst) begin
        state<=S_IDLE; done<=1'b0; mem_write_en<=1'b0;
        mem_addr<=14'd0; mem_data_out<=19'd0;
        x0<=0; x1<=0; x2<=0; x3<=0;
        a0<=0; a1<=0; a2<=0; a3<=0;
        X0<=0; X1<=0; X2<=0; X3<=0;   
    end else begin
        done<=1'b0;
        mem_write_en<=1'b0;
        
        case (state)
            S_IDLE: begin
            if (start) begin mem_addr <= src_base; state<= S_RD1; end 
            end
            
            S_RD1: begin
            mem_addr<=src_base +14'd1;
            state<=S_RD2;
            end
            
            S_RD2: begin 
            x0 <= mem_data_in;
            mem_addr<=src_base +14'd2;
            state <= S_RD3;
            end            
            
            S_RD3: begin 
            x1 <= mem_data_in;
            mem_addr<=src_base +14'd3;
            state <= S_RD4;            
            end 
            
            S_RD4: begin
            x2 <= mem_data_in;
            state <= S_CAPTURE;
            end
            
            S_CAPTURE: begin
            x3 <= mem_data_in;
            state <= S_STAGE1;
            end
            
            S_STAGE1: begin
            a0<= x0+x2;
            a1<= x0-x2;
            a2<= x1+x3;
            a3<= x1-x3;
            state <= S_STAGE2;
            end
            
            S_STAGE2: begin 
            X0<= a0+a2;
            X1<= a1+a3;
            X2<= a0-a2;
            X3<= a1-a3;        
            state<= S_WR0;    
            end
            
            S_WR0: begin
            mem_addr<= dst_base; mem_data_out<=X0; mem_write_en<= 1'b1;
            state<=S_WR1;
            end
  
            S_WR1: begin
            mem_addr<= dst_base+14'd1; mem_data_out<=X1; mem_write_en<= 1'b1;
            state<=S_WR2;
            end 
            
            S_WR2: begin
            mem_addr<= dst_base+14'd2; mem_data_out<=X2; mem_write_en<= 1'b1;
            state<=S_WR3;
            end        
            
            S_WR3: begin
            mem_addr<= dst_base+14'd3; mem_data_out<=X3; mem_write_en<= 1'b1;
            state<=S_DONE;
            end                
            
            S_DONE: begin done<=1'b1; state<=S_IDLE; end
            default: state<=S_IDLE;
            endcase
            
            end
            end
            
            
 endmodule 
            
            
            
            
            
            
            
            
            
            
            
            
                                   