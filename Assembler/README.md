Assembler
=========================
Support by jlex and java cup

Instruction syntax:
  1. Different areas should be seperated by comma, space or tab
  2. Register should be a letter R(or r) follow a hex number, like  R1, Ra, rf
  3. Instruciton name can be captital letters or lower-case letters, like add, Add, aDD
  4. Immediate in instruction can be hex number or decimal number
  5. Hex number should follow 0x, like 0xa, 0x1b
  6. Shift has three modes: leftlogic, rightlogic, rightarith
  7. Shift syntax: SHIFT \<Rd> \<mode> \<shamt>
