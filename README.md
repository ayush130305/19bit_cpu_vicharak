# 19-Bit Harvard CPU — Verilog

A 19-bit CPU built in Verilog with a 5-stage pipeline and Harvard architecture (separate instruction and data memory). Built and tested on Vivado 2024.2 and simulation ran on edaplayground website.
Simulation: https://edaplayground.com/x/tSTt

---

## What's in this project

| File | What it does |
|---|---|
| `cpu.v` | The main CPU — pipeline, hazard handling, everything |
| `alu.v` | Does all the math and logic operations |
| `instruct_mem.v` | Instruction memory (ROM) — stores the program |
| `data_mem.v` | Data memory (RAM) — read/write storage |
| `fft_unit.v` | 4-point FFT accelerator |
| `encryption.v` | XOR encrypt/decrypt unit |
| `cpu_tb.v` | Testbench — verifies everything works |

---

## Instruction set

21 instructions total across arithmetic, logic, control flow, and memory.

**Arithmetic:** ADD, SUB, MUL, DIV, REM, INC, DEC  
**Logic:** AND, OR, XOR, NOT  
**Control:** JMP, BEQ, BNE, CALL, RET  
**Memory:** LOAD, STORE  
**Special:** FFT, ENC, DECR  

---

## Instruction encoding

Every instruction is 19 bits wide:

```
[18:14] opcode (5 bits)
[13:10] destination register R
[9:6]   source register r1
[5:2]   source register r2
[1:0]   unused
```

For LOAD, STORE, JMP, BEQ, BNE, CALL — bits [13:0] are used as a 14-bit address field instead.

---

## Pipeline

5 stages: **Fetch → Decode → Execute → Memory → Writeback**

Hazards handled:
- **RAW hazards** — forwarding from EX/MEM and MEM/WB stages
- **Load-use hazard** — 1-cycle stall inserted automatically
- **Branch/jump** — 2-cycle flush with a `flush_next` flag to catch the stale ROM word

---

## Special units

**FFT unit** — reads 4 samples from data memory, computes a 4-point DIT butterfly FFT, writes 4 results back. CPU stalls until done.

**Encryption unit** — XOR cipher with a fixed 4-word key. Works for both encrypt and decrypt (XOR is symmetric). CPU stalls until done.

Keys used:
```
KEY0 = 0x2A5F3
KEY1 = 0x1C8B7
KEY2 = 0x3D1E6
KEY3 = 0x0F4A2
```

---

## Testbench sections

```verilog
`define test_alu    // arithmetic and logic unit tests
`define test_ctrl   // JMP, BEQ, BNE, CALL, RET
`define test_mem    // LOAD and STORE
`define test_fft    // FFT unit
`define test_enc    // encrypt and decrypt
```

Comment out any line to skip that section.

---

## Testbench output

All 47 tests pass across all 5 sections:

```
 19-bit CPU Master Testbench

 ALU
pass                     ADD 15+10=25
pass               ADD overflow carry
pass                      sub 20-8=12
pass                       mul 7*6=42
pass                       div 18/3=6
pass                    div by zero=0
pass                       rem 17%5=2
pass                     inc 99+1=100
pass                      dec 50-1=49
pass           AND 0xAA & 0xF0 = 0xA0
pass                OR 0xAA|0x55=0xFF
pass               XOR 0xFF^0xF0=0x0F
pass                    NOT 0=0x7FFFF
pass     zero flag set when result =0
pass     zero flag set when result!=0

 control flow
pass                 jmp landed: r6=1
pass          jmp traps skipped: r5=0
pass                  beq taken: r9=1
pass beq not taken trap skipped: r7=0
pass  bne not taken fallthrough: r8=1
pass                 bne taken: r10=1
pass       call subroutine ran: r12=1
pass              ret returned: r11=1

 load, store
pass   STORE reg[1]=48879 → dmem[64]
pass  STORE reg[2]=12345 → dmem[128]
pass     dmem[5] integrity: still 777
pass    dmem[10] integrity: still 999

 FFT
pass          FFT X0=10 (x=[4,3,2,1])
pass                         FFT X1=4
pass                         FFT X2=2
pass                         FFT X3=0
pass           FFT X0=1 (x=[1,0,0,0])
pass                         FFT X1=1
pass                         FFT X2=1
pass                         FFT X3=1

 ENC / DEC
pass              ENC word0 = p0^KEY0
pass              ENC word1 = p1^KEY1
pass              ENC word2 = p2^KEY2
pass              ENC word3 = p3^KEY3
pass     DEC word0 recovers plaintext
pass     DEC word1 recovers plaintext
pass     DEC word2 recovers plaintext
pass     DEC word3 recovers plaintext
pass                  ENC 0^KEY0=KEY0
pass                  ENC 0^KEY1=KEY1
pass                  ENC 0^KEY2=KEY2
pass                  ENC 0^KEY3=KEY3

 Total: 47 PASS  0 FAIL
 ALL PASS
```
