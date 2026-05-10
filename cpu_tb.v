`timescale 1ns / 1ps

`define test_alu
`define test_ctrl
`define test_mem
`define test_mem
`define test_fft
`define test_enc

module cpu_tb();

integer total_pass=0;
integer total_fail=0;

task result;
    input pass;
    input [255:0] msg;
    begin
        if (pass) begin
            $display("pass %s",msg);
            total_pass= total_pass+1;
        end else begin
            $display("fail %s",msg);
            total_fail=total_fail+1;
        end
    end
endtask

`ifdef test_alu
reg [18:0] alu_a,alu_b;
reg [4:0] opcode;
wire [18:0] alu_result;
wire alu_carry,alu_zero;

alu alu_tb(
.a(alu_a), .b(alu_b), .op(opcode), .result(alu_result), .carry(alu_carry), .zero(alu_zero)
);

task alu_chk;
input [18:0] exp_result;
input exp_carry;
input [255:0] name;
begin
    #1;
    result(alu_result==exp_result && alu_carry==exp_carry, name);
    if (alu_result!==exp_result || alu_carry!=exp_carry)
        $display("op=%b a=%0d b=%0d result=%0d carry=%b exp_result=%0d exp_carry=%b", opcode,alu_a,alu_b,alu_result,alu_carry,
        exp_result, exp_carry);
        end
endtask

task run_alu_tests;
    begin
        $display("\n ALU ");
        
        opcode=5'b00000; alu_a=19'd15; alu_b=19'd10; alu_chk(25,0,"ADD 15+10=25");
        opcode=5'b00000; alu_a=19'h7FFFF; alu_b=19'd1; alu_chk(19'd0,1,"ADD overflow carry");        
        opcode=5'b00001; alu_a=19'd20; alu_b=19'd8; alu_chk(12,0,"sub 20-8=12");      
        #1;    
        opcode=5'b00010; alu_a=19'd7; alu_b=19'd6; alu_chk(42,0,"mul 7*6=42");
        opcode=5'b00011; alu_a=19'd18; alu_b=19'd3; alu_chk(6,0,"div 18/3=6");
        opcode=5'b00011; alu_a=19'd10; alu_b=19'd0; alu_chk(0,0,"div by zero=0");
        opcode=5'b00100; alu_a=19'd17; alu_b=19'd5; alu_chk(2,0,"rem 17%5=2");
        opcode=5'b00101; alu_a=19'd99; alu_b=19'd0; alu_chk(100,0,"inc 99+1=100");
        opcode=5'b00110; alu_a=19'd50; alu_b=19'd0; alu_chk(49,0,"dec 50-1=49");
        
        opcode=5'b00111; alu_a=19'hAA; alu_b=19'hF0; alu_chk(19'hA0,0,"AND 0xAA & 0xF0 = 0xA0");        
        opcode=5'b01000; alu_a=19'hAA; alu_b=19'h55; alu_chk(19'hFF,0,"OR 0xAA|0x55=0xFF");
        opcode=5'b01001; alu_a=19'hFF; alu_b=19'hF0; alu_chk(19'h0F,0,"XOR 0xFF^0xF0=0x0F");
        opcode=5'b01010; alu_a=19'h0000; alu_b=0; alu_chk(19'h7FFFF,0,"NOT 0=0x7FFFF");
        
        opcode=5'b00001; alu_a=19'd5; alu_b=19'd5; #1;
        result(alu_zero===1'b1, "zero flag set when result =0");
        
        opcode=5'b00000; alu_a=19'd1; alu_b=19'd1; #1;
        result(alu_zero===1'b0, "zero flag set when result!=0");
        
        end
        endtask
`endif                

`ifdef test_ctrl

    reg ctrl_clk,ctrl_rst;
    wire [13:0] ctrl_imem_addr;
    reg [18:0] ctrl_imem_data;
    wire [13:0] ctrl_dmem_addr;
    wire [18:0] ctrl_dmem_out;
    wire ctrl_dmem_we;
    reg [18:0] ctrl_dmem_in;
    reg [18:0] ctrl_prog [0:511];
    
    always @(posedge ctrl_clk) ctrl_imem_data <= ctrl_prog[ctrl_imem_addr[8:0]];
    always @(*) ctrl_dmem_in=19'd0;
    
    cpu ctrl(
    .clk(ctrl_clk), .rst(ctrl_rst), .imem_addr(ctrl_imem_addr), .imem_data(ctrl_imem_data), .dmem_addr(ctrl_dmem_addr),
    .dmem_data_out(ctrl_dmem_out), .dmem_write_en(ctrl_dmem_we), .dmem_data_in(ctrl_dmem_in)
    );
    
    always #5 ctrl_clk=~ctrl_clk;
    
    task ctrl_wait; input integer n; integer j;
    begin for(j=0;j<n;j=j+1) @(posedge ctrl_clk); end
    endtask
    
    task run_ctrl_tests;
    integer i;
    begin 
    $display("\n control flow");
    ctrl_clk=0; ctrl_rst=1;
    for(i=0;i<512;i=i+1) ctrl_prog[i]=19'd0;
    
    ctrl_prog[0] = {5'b01011,14'd4}; 
    ctrl_prog[1] = {5'b00101, 4'd5,4'd5,4'd0,2'b00};    
    ctrl_prog[2] = {5'b00101, 4'd5,4'd5,4'd0,2'b00};
    ctrl_prog[3] = {5'b00101, 4'd5,4'd5,4'd0,2'b00};
    ctrl_prog[4] = {5'b00101, 4'd6,4'd6,4'd0,2'b00}; //inc r6    
    ctrl_prog[5] = {5'b01100, 4'd0, 4'd1, 4'd1, 2'b00};  
    ctrl_prog[6] = {5'b01011, 4'd7, 4'd7, 4'd0, 2'b00};
    ctrl_prog[7] = {5'b01011, 14'd20};    
    ctrl_prog[20] = {5'b01101, 4'd0, 4'd1, 4'd2, 2'b00};      
    ctrl_prog[21] = {5'b00101, 4'd8, 4'd8, 4'd0, 2'b00};
    ctrl_prog[22] = {5'b01101, 4'd0, 4'd1, 4'd3, 2'b00};     
    ctrl_prog[23] = {5'b00101, 4'd5, 4'd5, 4'd0, 2'b00};        
    ctrl_prog[68] = {5'b00101, 4'd9, 4'd9, 4'd0, 2'b00}; 
    ctrl_prog[69] = {5'b01011, 14'd20};
    ctrl_prog[76] = {5'b00101, 4'd10, 4'd10, 4'd0, 2'b00}; 
    ctrl_prog[77] = {5'b01110, 14'd200};                    
    ctrl_prog[78] = {5'b00101, 4'd11, 4'd11, 4'd0, 2'b00}; 
    ctrl_prog[79] = {5'b01011, 14'd500};
    ctrl_prog[200] = {5'b00101, 4'd12, 4'd12, 4'd0, 2'b00}; 
    ctrl_prog[201] = {5'b01111, 14'd0};                      
    ctrl_prog[500] = {5'b01011, 14'd500};        
    
    repeat (4) @(posedge ctrl_clk);
    ctrl_rst=0;
    @(posedge ctrl_clk); #1;
    ctrl.reg_file[1]=19'd42;
    ctrl.reg_file[2]=19'd42;
    ctrl.reg_file[3]=19'd10; 
    
    ctrl_wait(300);
    
    result(ctrl.reg_file[6]===19'd1, "jmp landed: r6=1");           
    result(ctrl.reg_file[5]===19'd0, "jmp traps skipped: r5=0");
    result(ctrl.reg_file[9]===19'd1, "beq taken: r9=1");
    result(ctrl.reg_file[7]===19'd0, "beq not taken trap skipped: r7=0");    
    result(ctrl.reg_file[8]===19'd1, "bne not taken fallthrough: r8=1");  
    result(ctrl.reg_file[10]===19'd1, "bne taken: r10=1");           
    result(ctrl.reg_file[12]===19'd1, "call subroutine ran: r12=1");
    result(ctrl.reg_file[11]===19'd1, "ret returned: r11=1");
    end
    endtask
`endif

`ifdef test_mem
    
    reg mem_clk,mem_rst;
    wire [13:0] mem_imem_addr;
    reg [18:0] mem_imem_data;
    wire [13:0] mem_dmem_addr;
    wire [18:0] mem_dmem_out;
    wire mem_dmem_we;
    reg [18:0] mem_dmem_in;
    reg [18:0] mem_prog [0:63];
    reg [18:0] mem_dmem [0:1023];
    
    always @(posedge mem_clk) mem_imem_data <= mem_prog[mem_imem_addr[5:0]];
    always @(posedge mem_clk) begin 
        if(mem_dmem_we) mem_dmem[mem_dmem_addr[9:0]] <= mem_dmem_out;
        mem_dmem_in <= mem_dmem[mem_dmem_addr[9:0]];
    end

    cpu mem(
    .clk(mem_clk), .rst(mem_rst), .imem_addr(mem_imem_addr), .imem_data(mem_imem_data), .dmem_addr(mem_dmem_addr),
    .dmem_data_out(mem_dmem_out), .dmem_write_en(mem_dmem_we), .dmem_data_in(mem_dmem_in)
    );              
    always #5 mem_clk=~mem_clk;
    
    task mem_wait; input integer n; integer j;
    begin for(j=0;j<n;j=j+1) @(posedge mem_clk); end
    endtask
    
    task run_mem_tests;
    integer i;
    begin $display("\n load, store");
    mem_clk=0;mem_rst=1;
    for(i=0;i<64;i=i+1) mem_prog[i]=19'd0;
    for(i=0;i<1024;i=i+1) mem_dmem[i]=19'd0;
    
    mem_dmem[5]=19'd777;
    mem_dmem[10]=19'd999;
    
            mem_prog[0]={5'b10001, 14'd64};
            mem_prog[1] = 19'd0; mem_prog[2] = 19'd0; mem_prog[3] = 19'd0;
            mem_prog[4] = {5'b10001, 14'd128};  
            mem_prog[5] = 19'd0; mem_prog[6] = 19'd0; mem_prog[7] = 19'd0;
            mem_prog[8] = {5'b10000, 14'd5};   
            mem_prog[9] = 19'd0; mem_prog[10] = 19'd0; mem_prog[11] = 19'd0;
            mem_prog[12] = {5'b10000, 14'd10};  
            mem_prog[13] = 19'd0; mem_prog[14] = 19'd0; mem_prog[15] = 19'd0;
            mem_prog[16] = {5'b01011, 14'd16};  

            repeat(4) @(posedge mem_clk);
            mem_rst = 0;
            @(posedge mem_clk); #1;
            mem.reg_file[1] = 19'd48879;
            mem.reg_file[2] = 19'd12345;

            mem_wait(50);

            result(mem_dmem[64]===19'd48879,  "STORE reg[1]=48879 → dmem[64]");
            result(mem_dmem[128]===19'd12345, "STORE reg[2]=12345 → dmem[128]");
            result(mem_dmem[5]===19'd777,     "dmem[5] integrity: still 777");
            result(mem_dmem[10]===19'd999,    "dmem[10] integrity: still 999");
        end
    endtask
`endif // TEST_MEM    

`ifdef test_fft

    reg         fft_clk, fft_rst, fft_start;
    reg  [13:0] fft_src_base, fft_dst_base;
    wire [13:0] fft_mem_addr;
    wire [18:0] fft_mem_dout;
    wire        fft_mem_we, fft_done;


    reg  [18:0] fft_dmem [0:1023];
    reg  [18:0] fft_mem_din;
    always @(posedge fft_clk) begin
        if (fft_mem_we) fft_dmem[fft_mem_addr[9:0]] <= fft_mem_dout;
        fft_mem_din <= fft_dmem[fft_mem_addr[9:0]];
    end

    fft_unit u_fft_tb (
        .clk(fft_clk), .rst(fft_rst), .start(fft_start),
        .src_base(fft_src_base), .dst_base(fft_dst_base),
        .mem_data_in(fft_mem_din),
        .mem_addr(fft_mem_addr), .mem_data_out(fft_mem_dout),
        .mem_write_en(fft_mem_we), .done(fft_done)
    );
    always #5 fft_clk = ~fft_clk;

    task run_fft_tests;
        integer i, timeout;
        begin
            $display("\nFFT");
            fft_clk=0; fft_rst=1; fft_start=0;
            fft_src_base=14'd10; fft_dst_base=14'd20;
            for(i=0;i<1024;i=i+1) fft_dmem[i]=19'd0;

    
            fft_dmem[10]=19'd4; fft_dmem[11]=19'd3;
            fft_dmem[12]=19'd2; fft_dmem[13]=19'd1;

            repeat(4) @(posedge fft_clk); fft_rst=0;
            @(posedge fft_clk); fft_start=1;
            @(posedge fft_clk); fft_start=0;

            timeout=0;
            while (!fft_done && timeout<200) begin
                @(posedge fft_clk); timeout=timeout+1;
            end
            @(posedge fft_clk); 

            result(fft_dmem[20]===19'd10, "FFT X0=10 (x=[4,3,2,1])");
            result(fft_dmem[21]===19'd4,  "FFT X1=4");
            result(fft_dmem[22]===19'd2,  "FFT X2=2");
            result(fft_dmem[23]===19'd0,  "FFT X3=0");

  
            for(i=0;i<1024;i=i+1) fft_dmem[i]=19'd0;
            fft_dmem[10]=19'd1; 
            @(posedge fft_clk); fft_start=1;
            @(posedge fft_clk); fft_start=0;
            timeout=0;
            while (!fft_done && timeout<200) begin
                @(posedge fft_clk); timeout=timeout+1;
            end
            @(posedge fft_clk);

            result(fft_dmem[20]===19'd1, "FFT X0=1 (x=[1,0,0,0])");
            result(fft_dmem[21]===19'd1, "FFT X1=1");
            result(fft_dmem[22]===19'd1, "FFT X2=1");
            result(fft_dmem[23]===19'd1, "FFT X3=1");
        end
    endtask
`endif 

`ifdef test_enc
   
    reg         enc_clk, enc_rst, enc_start, enc_mode;
    reg  [13:0] enc_src_base, enc_dst_base;
    wire [13:0] enc_mem_addr;
    wire [18:0] enc_mem_dout;
    wire        enc_mem_we, enc_done;

    reg  [18:0] enc_dmem [0:1023];
    reg  [18:0] enc_mem_din;
    always @(posedge enc_clk) begin
        if (enc_mem_we) enc_dmem[enc_mem_addr[9:0]] <= enc_mem_dout;
        enc_mem_din <= enc_dmem[enc_mem_addr[9:0]];
    end

    encryption u_xor_tb (
        .clk(enc_clk), .rst(enc_rst), .start(enc_start), .enc_mode(enc_mode),
        .src_base(enc_src_base), .dst_base(enc_dst_base),
        .mem_data_in(enc_mem_din),
        .mem_addr(enc_mem_addr), .mem_data_out(enc_mem_dout),
        .mem_write_en(enc_mem_we), .done(enc_done)
    );
    always #5 enc_clk = ~enc_clk;

   
    localparam [18:0] ENC_KEY0=19'h2A5F3, ENC_KEY1=19'h1C8B7,
                      ENC_KEY2=19'h3D1E6, ENC_KEY3=19'h0F4A2;

    task run_enc_tests;
        integer i, timeout;
        reg [18:0] p0, p1, p2, p3;
        begin
            $display("\n--- ENC / DEC (XOR unit direct test) ---");
            enc_clk=0; enc_rst=1; enc_start=0; enc_mode=1;
            enc_src_base=14'd50; enc_dst_base=14'd60;
            for(i=0;i<1024;i=i+1) enc_dmem[i]=19'd0;

       
            p0=19'h12345; p1=19'h0ABCD; p2=19'h07FFF; p3=19'h00001;
            enc_dmem[50]=p0; enc_dmem[51]=p1;
            enc_dmem[52]=p2; enc_dmem[53]=p3;

            repeat(4) @(posedge enc_clk); enc_rst=0;
            enc_mode=1;
            @(posedge enc_clk); enc_start=1;
            @(posedge enc_clk); enc_start=0;
            timeout=0;
            while (!enc_done && timeout<200) begin
                @(posedge enc_clk); timeout=timeout+1;
            end
            @(posedge enc_clk);

            result(enc_dmem[60]===(p0^ENC_KEY0), "ENC word0 = p0^KEY0");
            result(enc_dmem[61]===(p1^ENC_KEY1), "ENC word1 = p1^KEY1");
            result(enc_dmem[62]===(p2^ENC_KEY2), "ENC word2 = p2^KEY2");
            result(enc_dmem[63]===(p3^ENC_KEY3), "ENC word3 = p3^KEY3");

            enc_src_base=14'd60; enc_dst_base=14'd70; enc_mode=0;
            @(posedge enc_clk); enc_start=1;
            @(posedge enc_clk); enc_start=0;
            timeout=0;
            while (!enc_done && timeout<200) begin
                @(posedge enc_clk); timeout=timeout+1;
            end
            @(posedge enc_clk);

            result(enc_dmem[70]===p0, "DEC word0 recovers plaintext");
            result(enc_dmem[71]===p1, "DEC word1 recovers plaintext");
            result(enc_dmem[72]===p2, "DEC word2 recovers plaintext");
            result(enc_dmem[73]===p3, "DEC word3 recovers plaintext");

   
            for(i=80;i<84;i=i+1) enc_dmem[i]=19'd0;
            enc_src_base=14'd80; enc_dst_base=14'd90; enc_mode=1;
            @(posedge enc_clk); enc_start=1;
            @(posedge enc_clk); enc_start=0;
            timeout=0;
            while (!enc_done && timeout<200) begin
                @(posedge enc_clk); timeout=timeout+1;
            end
            @(posedge enc_clk);

            result(enc_dmem[90]===ENC_KEY0, "ENC 0^KEY0=KEY0");
            result(enc_dmem[91]===ENC_KEY1, "ENC 0^KEY1=KEY1");
            result(enc_dmem[92]===ENC_KEY2, "ENC 0^KEY2=KEY2");
            result(enc_dmem[93]===ENC_KEY3, "ENC 0^KEY3=KEY3");
        end
    endtask
`endif 

    
    initial begin

        $display(" 19-bit CPU Master Testbench");
  

`ifdef test_alu
        run_alu_tests();
`endif
`ifdef test_ctrl
        run_ctrl_tests();
`endif
`ifdef test_mem
        run_mem_tests();
`endif
`ifdef test_fft
        run_fft_tests();
`endif
`ifdef test_enc
        run_enc_tests();
`endif

        $display("");

        $display(" Total: %0d PASS  %0d FAIL", total_pass, total_fail);
        if (total_fail == 0) $display(" ALL PASS");

        $finish;
    end

endmodule
