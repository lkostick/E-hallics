import java.util.*;
import java.io.*;

public class simulator {
    public static void main(String[] args) throws IOException {

		FileReader inFile = null;
		try {
			inFile = new FileReader(args[0]);
		} catch (FileNotFoundException ex) {
			System.err.println("File" + args[0] + " not found.");
			System.exit(-1);
		}
		BufferedReader br = new BufferedReader(inFile);

		// read instructions
		Memory = new HashMap<Integer, String>();
		Memory.put(4094, "0000");
		Memory.put(4095, "0000");
		String s;
		int addr = 0x0000;
		while ((s= br.readLine()) != null) {
			if (s.charAt(0) == '@') {
				addr = Integer.valueOf(s.substring(1),16);
			}
			else {
				Memory.put(addr, s);
				addr ++;
			}
		}
		inFile.close();


		if (args.length == 2)
			addr = Integer.valueOf(args[1].substring(2), 16);
		else
			addr = 0x1000;

		// start running
		String instr;
		int dst, src0, src1, temp;
		int outputflag = 0;
		int outputcount = 0;
		int outputsum = 0;
		String data;
		while (addr != -1) {
			instr = Memory.get(addr);
			if (instr == null) {
				System.err.println("Error @"+Integer.toString(addr, 16));
			 	break;
			}
		//	System.err.println(Integer.toString(addr,16) +" "+instr);
			switch(instr.charAt(0)){
				default: System.err.println("Unknown instruction @" + Integer.toString(addr,16));
						 System.exit(-1);
				case '0': // add;
					if (instr.charAt(1) != '0') { 
						src0 = Register[Integer.valueOf(instr.substring(2,3),16)];
						src1 = Register[Integer.valueOf(instr.substring(3,4),16)];
						if (src0 > 32767)
							src0 -= 65536;
						if (src1 > 32767)
							src1 -= 65536;
						dst = src0 + src1;
						if (dst < 0) 
							Negative = true;
						else
							Negative = false;
						if (dst == 0)
							Zero = true;
						else
							Zero =false;
						if (dst > 32767) {
							dst = 32767;
							Overflow = true;
						}
						else if (dst < -32768) {
							dst = - 32768;
							Overflow = true;
						}
						else {
							Overflow = false;
						}
						if (dst < 0) dst += 65536;
						Register[Integer.valueOf(instr.substring(1,2),16)] =dst;
					}		
					addr++;
					break;
				case '1': // sub
					if (instr.charAt(1) != '0') { 
						src0 = Register[Integer.valueOf(instr.substring(2,3),16)];
						src1 = Register[Integer.valueOf(instr.substring(3,4),16)];
						if (src0 > 32767)
							src0 -= 65536;
						if (src1 > 32767)
							src1 -= 65536;
						dst = src0 - src1;
						if (dst < 0) 
							Negative = true;
						else
							Negative = false;
						if (dst == 0)
							Zero = true;
						else
							Zero =false;
						if (dst > 32767) {
							dst = 32767;
							Overflow = true;
						}
						else if (dst < -32768) {
							dst = - 32768;
							Overflow = true;
						}
						else {
							Overflow = false;
						}
						if (dst < 0) dst += 65536;
						Register[Integer.valueOf(instr.substring(1,2),16)] =dst;
					}		
					addr++;
					break;
				case '2': //Xor
					if (instr.charAt(1) != '0') { 
							src0 = Register[Integer.valueOf(instr.substring(2,3),16)];
							src1 = Register[Integer.valueOf(instr.substring(3,4),16)];
							dst = src0^src1;
							if (dst == 0) 
								Zero = true;
							else
								Zero = false;
							Register[Integer.valueOf(instr.substring(1,2),16)]= dst;
					}	
					addr++;
					break;
				case '3': // LD
					if (instr.charAt(1) != '0') {
						if (Register[Integer.valueOf(instr.substring(2,3),16)] < 1000) 
							System.out.println(Integer.toString(addr,16) + " "+ instr+ " "+"illegal " + Register[Integer.valueOf(instr.substring(2,3),16)]);
						data = Memory.get(Register[Integer.valueOf(instr.substring(2,3),16)]);
						if (data == null) temp = 0;
						else temp = Integer.valueOf(data, 16);
						Register[Integer.valueOf(instr.substring(1,2), 16)] = temp;
					}
					addr++;
					break;
				case '4': //SW
						if (Register[Integer.valueOf(instr.substring(2,3),16)] < 1000) 
							System.out.println(Integer.toString(addr,16) + " "+ instr+ " "+"illegal");
						String store = Integer.toString(Register[Integer.valueOf(instr.substring(1,2),16)],16);
						Memory.put(Register[Integer.valueOf(instr.substring(2,3),16)], store);
						addr++;
						break;
				case '5': // LH
					if (instr.charAt(1) != '0') {
						Register[Integer.valueOf(instr.substring(1,2),16)] = Integer.valueOf(instr.substring(2),16)*256+Register[Integer.valueOf(instr.substring(1,2),16)];
					}
					addr++;
					break;
				case '6': // LL
					if (instr.charAt(1) != '0') {
						Register[Integer.valueOf(instr.substring(1,2),16)] = Integer.valueOf(instr.substring(2),16);
					}
					addr++;
					break;
				case '7': // Shift
					if (instr.charAt(1) != '0') {
						switch (instr.charAt(2)) {
							case '0': //sll
								temp = Register[Integer.valueOf(instr.substring(1,2),16)];
								for (int i = 0; i< Integer.valueOf(instr.substring(3,4),16); i++)
									temp *= 2;
								temp %= 65536;
								Register[Integer.valueOf(instr.substring(1,2),16)] = temp;
								break;
							case '1': //srl
								temp = Register[Integer.valueOf(instr.substring(1,2),16)];
								for (int i = 0; i< Integer.valueOf(instr.substring(3,4),16); i++)
									temp /= 2;
								temp %= 65536;
								Register[Integer.valueOf(instr.substring(1,2),16)] = temp;
								break;
							default: //srr
								temp = Register[Integer.valueOf(instr.substring(1,2),16)];
								int flag = temp /32768;
								for (int i = 0; i< Integer.valueOf(instr.substring(3,4),16); i++) {
									temp /= 2;
									temp += flag*32768;
								}
								temp %= 65536;
								Register[Integer.valueOf(instr.substring(1,2),16)] = temp;
								break;
						}
					}
					addr++;
					break;
				case '8': // branch
					temp = Integer.valueOf(instr,16);
					int cond = temp % 4096 / 512;
					int imme = temp % 512;
					if (imme / 256 == 1) {
						imme -=512;
					}
					switch (cond) {
						case 0: 
							if (Zero) 
								addr += imme;
							else
								addr++;
							break;
						case 1:
							if (!Negative && !Zero)
								addr += imme;
							else
								addr++;
							break;
						case 2:
							if (!Negative)
								addr += imme;
							else
								addr++;
							break;
						case 3:
							if (Negative)
								addr += imme;
							else
								addr++;
							break;
						case 4:
							if (Negative || Zero)
								addr += imme;
							else
								addr++;
							break;
						case 5:
							if (!Zero)
								addr += imme;
							else
								addr++;
							break;
						case 6:
							if (Overflow)
								addr += imme;
							else
								addr++;
							break;
						default:
							addr += imme;
							break;
					}
					break;
				case '9':
					int offset = Integer.valueOf(instr.substring(1), 16);
					Register[12] = addr + 1;
					if (offset / 2048 == 1)
						offset -= 4096;
					addr += offset;
					break;
				case 'a':
					addr = Register[Integer.valueOf(instr.substring(1,2),16)];
					break;
				case 'b':
					System.out.println("Accelerator Control instruction: " +instr);
					addr++;
					break;
				case 'c':
					int x;
					if (instr.charAt(3) == '2')
						x= Integer.valueOf(instr.substring(1,3),16);
					else if (instr.charAt(3) == '1') 
						x = (int)(Register[Integer.valueOf(instr.substring(1,2),16)]/256);
					else
						x = (int)(Register[Integer.valueOf(instr.substring(1,2),16)]%256);

					if (x == 0xfe && (outputflag == 0||outputcount == 2)) {
						outputflag = 1-outputflag;
						outputcount = 0;
						outputsum = 0;
					}
					else if (x == 0xff && (outputflag == 0 || outputcount == 2)) {
						outputflag = 2 - outputflag;
						outputcount = 0;
						outputsum = 0;
					}
					else if (outputflag == 1) {
						outputcount ++;
						if (outputcount == 1)
							outputsum = x;
						else {
							outputsum *= 256;
							outputsum += x;
						}
						if (outputcount == 2)
						System.out.print((outputsum > 32767)?(outputsum - 65536):outputsum);
					}
					else if (outputflag == 2) {
						outputcount ++;
						if (Integer.toString(x,16).length() == 0) System.out.print("00");
						if (Integer.toString(x,16).length() == 1) System.out.print("0");
						System.out.print(Integer.toString(x, 16));
					}
					else if (x == 0x0d) {
						System.out.println();
					}
					else
						System.out.print((char)x);
					addr++;
					break;
				case 'd': // set
					if (instr.charAt(1) == '4') {
						addr = -1;
					}
					else
						addr ++;
					break;
				case 'f': // addi do not update flag
					if (instr.charAt(1) != '0'){
						src1 = Integer.valueOf(instr.substring(3),16);
						if (src1>7) src1 -= 16;
						src0 = Register[Integer.valueOf(instr.substring(2,3),16)];
						if (src0 > 32767) src0 -= 65536;
						dst = src0 + src1;
						if (dst < -32768) dst = -32768;
						if (dst > 32767) dst = 32767;
						if (dst < 0) dst += 65536;
						Register[Integer.valueOf(instr.substring(1,2),16)] = dst;
					}
					addr++;
					break;
			}
			if (addr == -1) {
				System.out.println(">  Program Finished or Sleeped");
				System.out.print(">  Do you want to wake up program?");
				BufferedReader in = new BufferedReader(new InputStreamReader(System.in));
				String inputString = in.readLine();
				if (inputString.equals("yes")) {
					// Search for sleep program
					for ( int i = 0x1006; i < 0xffff; i+= 0x4000){ 
						if (Memory.get(i) != null) {
							addr = Integer.valueOf(Memory.get(i), 16);
							if (addr != 0) {
								System.out.println("wake up to " + addr);
								break;
							}
							else
								addr = -1;
						}
					}
					if ( addr == -1)
						System.out.println(">  No program is sleeping");
				}
			}
		}

		// dump register
		System.out.println("=============================\nRegister Dump");
		for (int i = 0; i<16; i++) {
			System.out.print("R"+Integer.toString(i,16) + ": 0x");
			String result = Integer.toString(Register[i],16);
		 	for (int j =4; j>result.length(); j--)
				System.out.print("0");
			System.out.println(result);
		}
    }

	static private HashMap<Integer, String> Memory = null;
	static private int[] Register = new int[16];
	static private boolean Overflow, Zero, Negative;
}
