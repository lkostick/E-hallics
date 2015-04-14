Assembler
=========================
Usage: 

	1. java -jar asmbl.jar <input file> > <output file>
	2. java -jar asmbl.jar <code_length> <input file> > <output file>

When \<code_length> is provided, the unspecified address will be filled by 0x0000.

Instruction format:

	1. Add <Rd> <Rs> <Rt>
	2. Sub <Rd> <Rs> <Rt>
	3. Xor <Rd> <Rs> <Rt>
	4. Ld <Rd> <Rs>
	5. Sw <Rd> <Rs>
	6. Lh <Rd> <Imme> or Lh <Rd> <Char>
	7. Ll <Rd> <Imme> or Ll <Rd> <Char>
	8. Shift <Rd> <Shift_Mode> <Imme>
	9. B <Cond> <Imme or Flag>
	10. JL <Imme or Flag>
	11. JR <Rd> <Set_Mode> or JR <Rd>
	12. Send <Rd> <Send_Mode> or Send <Imme> or Send <Char> or Send <String>
	13. Set <Set_Mode>
	14. Rv <Rd> <Device> <Imme>

\<Set_Mode> : idle, user, previous.

\<Send_Mode> : low, high

\<Shift_Mode> : leftlogic, rightlogic, rightarith

\<Cond> : eq, neq, gt, lt, gte, lte, ov, uncond

\<Imme> : Decimal or hex number, hex number should start with 0x

\<Flag> : Can be any combination of letter and\or digit except reserved word

\<Char> : One char enclosed by single quotes. Support two escaped characters, \t and \n

\<String> : A string enclosed by double quotes. Support four escaped characters, \t, \n, \\ and \"

\<Device> : spart. For now only support one device choice

Letters in instruction: Can be capital or lower-case letter, like add or ADD, eq or EQ

Seperate: Different areas in instructions should be seperated by space, tab or comma

Example:

	Add r0 R1 R2
	sub R3,R1,R2
	XOR R5, ra, rc
	ld r1	r2
	FLAG1:
	SW r1	r3
	lh r9 123
	ll r9 0x22
	Shift r8 LeftLogic 4
	B lte FLAG1
	jl FLAG2
	Jr rf
	jr Rc idle
	FLAG2: send ra low
	send ra high
	send 0x45
	send 'a'
	send ' ' //send space
	send '\n' //new line
	send '\t'
	send "Program end\n"
	Set previous
