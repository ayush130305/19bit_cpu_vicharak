`timescale 1ns / 1ps

module encryption(
    input clk,
    input rst,
    input start,
    input [18:0] data_in,
    input [18:0] key,
    output [18:0] data_out,
    output reg busy,
    output reg done
    );
    
        reg [5:0] round_count;
        reg [18:0] temp_data;
        reg [18:0] out_reg;
        assign data_out = out_reg; 
        
        wire [18:0] const_val=19'h19BDE; //const is multiplied to round so each round is unique
        
always @(posedge clk or posedge rst) begin
    if(rst) begin
        round_count <= 6'd0;
        out_reg    <= 19'b0;
        busy        <= 1'b0;
        done        <= 1'b0; // Start in a ready state
        temp_data   <= 19'b0;
    end else begin
        if(start && !busy) begin
            // Initialization phase
            temp_data   <= data_in;
            round_count <= 6'd0;
            busy        <= 1'b1;
            done        <= 1'b0;
        end else if (busy) begin
            if (round_count < 33) begin
                // Computation phase
                temp_data   <= ((temp_data ^ key) + ((temp_data << 3) | (temp_data >> 16)) + (const_val + round_count));
                round_count <= round_count + 1; 
                out_reg <= temp_data; 
                 end else begin
                          // Completion phase: This triggers at the start of cycle 33
                out_reg <= temp_data; 
                busy        <= 1'b0;
                done        <= 1'b1;
            end
        end else if (!start)begin
            // Idle phase: reset done pulse but KEEP data_out stable
            done <= 1'b0;
        end
    end
  
end        

       

                
endmodule
