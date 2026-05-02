Define the CPU Architecture:
   •    Choose an 19-bit architecture ( Instruction size will be 19-bit ).
   •    Define a specialized instruction set tailored to a specific application or set of applications (e.g., signal processing, cryptography).
   •    Create a detailed architectural specification, including pipeline stages, register file, ALU, and memory interfaces. 

You can use Verilog/VHDL/systemverilog. You can add some extra instructions as well, based on your convenience.

You are supposed to submit the task within 15 days.

Arithmetic Instructions    
1.    ADD r1, r2, r3
   •    Description: Add the values in registers r2 and r3, and store the result in r1.
   •    Operation: r1 = r2 + r3
2.    SUB r1, r2, r3
   •    Description: Subtract the value in register r3 from the value in register r2, and store the result in r1.
   •    Operation: r1 = r2 - r3 
3.    MUL r1, r2, r3
   •    Description: Multiply the values in registers r2 and r3, and store the result in r1.
   •    Operation: r1 = r2 * r3
4.    DIV r1, r2, r3
   •    Description: Divide the value in register r2 by the value in register r3, and store the result in r1.
   •    Operation: r1 = r2 / r3
5.    INC r1
   •    Description: Increment the value in register r1 by 1.
   •    Operation: r1 = r1 + 1
6.    DEC r1
   •    Description: Decrement the value in register r1 by 1.
   •    Operation: r1 = r1 - 1

Logical Instructions    
1.    AND r1, r2, r3
   •    Description: Perform a bitwise AND on the values in registers r2 and r3, and store the result in r1.
   •    Operation: r1 = r2 & r3
2.    OR r1, r2, r3
   •    Description: Perform a bitwise OR on the values in registers r2 and r3, and store the result in r1.
   •    Operation: r1 = r2 | r3
3.    XOR r1, r2, r3
   •    Description: Perform a bitwise XOR on the values in registers r2 and r3, and store the result in r1.
   •    Operation: r1 = r2 ^ r3
4.    NOT r1, r2
   •    Description: Perform a bitwise NOT on the value in register r2, and store the result in r1.
   •    Operation: r1 = ~r2

Control Flow Instructions    
1.    JMP addr
   •    Description: Jump to the specified address.
   •    Operation: PC = addr
2.    BEQ r1, r2, addr
   •    Description: Branch to the specified address if the values in registers r1 and r2 are equal.
   •    Operation: if (r1 == r2) PC = addr
3.    BNE r1, r2, addr
   •    Description: Branch to the specified address if the values in registers r1 and r2 are not equal.
   •    Operation: if (r1 != r2) PC = addr
4.    CALL addr
   •    Description: Call a subroutine at the specified address.
   •    Operation: stack[SP] = PC + 1; SP = SP - 1; PC = addr
5.    RET
   •    Description: Return from a subroutine.
   •    Operation: SP = SP + 1; PC = stack[SP]

Memory Access Instructions    
1.    LD r1, addr
   •    Description: Load the value from the specified memory address into register r1.
   •    Operation: r1 = memory[addr]
2.    ST addr, r1
   •    Description: Store the value in register r1 to the specified memory address.
   •    Operation: memory[addr] = r1

Custom Instructions (for specialized applications)    
1.    FFT r1, r2
   •    Description: Perform a Fast Fourier Transform on the data starting at address r2, and store the result in the location pointed to by r1.
   •    Operation: FFT(memory[r2], result); memory[r1] = result
2.    ENC r1, r2
   •    Description: Encrypt the data starting at address r2 using a predefined encryption algorithm, and store the result in the location pointed to by r1.
   •    Operation: encrypted_data = Encrypt(memory[r2]); memory[r1] = encrypted_data
3.    DEC r1, r2
   •    Description: Decrypt the data starting at address r2 using a predefined decryption algorithm, and store the result in the location pointed to by r1.
   •    Operation: decrypted_data = Decrypt(memory[r2]); memory[r1] = decrypted_data
