import java.io.*;
import java.util.*;

abstract class ASTnode {
}
 
class ProgramNode extends ASTnode { 
	public ProgramNode(InstrListNode L) {
		myInstrList = L;
	}

	public void translate(String flag) { 
		myInstrList.translate(flag);
	}

	public void FlagCheck() { 
		myInstrList.FlagCheck();
	}

	private InstrListNode myInstrList;
}

class InstrListNode extends ASTnode {
	public InstrListNode(List<InstrNode> S) {
		myInstrs = S;
	}

	public void translate(String flag) {
		Iterator it = myInstrs.iterator();
		int codeLength = Integer.valueOf(flag, 10);
		try {
	 		if (codeLength > 0) {
				int instrCount = 0;
				for (InstrNode instr: myInstrs) {
					if (instr.getAddr() != -1)
						instrCount = instr.getAddr();
					else
						instrCount += instr.increaseAddr();
				}
				if (instrCount > codeLength) {
					System.err.println("<Code_Length> is too small");
					System.exit(-1);
				}
	 			int n = 0;
	 	 		while(it.hasNext()) {
					InstrNode next = (InstrNode)it.next();
	 	 			if (next.getAddr() != -1) {
						if (next.getAddr() < n) {
							System.err.println("Error");
							System.exit(-1);
	 	 				}
						else {
						for (int i =n; i<next.getAddr(); i++)
							System.out.println("0000");
						n = next.getAddr();
	 	 				}
					}
	 	 			else {
						n+=next.increaseAddr();
						next.translate();
					}
				}
				for (int i = n ; i < codeLength; i++)
					System.out.println("0000");
			}
			else
				while (it.hasNext())
					((InstrNode)it.next()).translate();
		} catch (NoSuchElementException ex) {
			System.err.println("Empty program");
			System.exit(-1);
	 	} 
 	} 

 	public void FlagCheck() {
		int index = 0, addr = 0;;
		HashMap<String, Integer> Flags = new HashMap<String, Integer>();
 		while (index < myInstrs.size()) {
			InstrNode instr = myInstrs.get(index);
			// get all flags and their addres
 			if (instr.isFlag() != null) {
				if (Flags.containsKey(instr.isFlag())) {
					System.err.println("Warning: Duplicated flags: "+instr.isFlag()+", ingore it. @"+instr.getLine()+":"+instr.getChar());
 				}
				else
					Flags.put(instr.isFlag(), addr);
				myInstrs.remove(index);
			}
			else 
			{
				index++;
				if (instr.getAddr() != -1) {
					if (addr > instr.getAddr()) {
						System.err.println("No enough space @"+Integer.toString(addr, 16));
						System.exit(-1);
					}
					addr = instr.getAddr();
				}
				else addr+= instr.increaseAddr();
			}

		}
		// assign address to instruction
		addr = 0;
 		for (InstrNode instr: myInstrs) {
 			if (instr.needFlag() != null) {
				if (!Flags.containsKey(instr.needFlag())) {
					System.err.println("Error: flag: "+instr.needFlag() + " is not found. @"+instr.getLine()+":"+instr.getChar());
					System.exit(-1);
 				}
				if (instr instanceof La) {
					instr.SetImme(Flags.get(instr.needFlag()));
				}
				else if (!instr.SetImme(Flags.get(instr.needFlag()) - addr))
					System.err.println(" @"+instr.getLine()+":"+instr.getChar());
			}
			if (instr.getAddr() != -1){
				addr = instr.getAddr();
			}
			else
				addr+= instr.increaseAddr();
		}
	}
	private List<InstrNode> myInstrs; 
} 
 
abstract class InstrNode extends ASTnode {
	public String[] HEX = {"0","1","2","3","4","5","6","7","8","9",
						   "a","b","c","d","e","f"};

	abstract public void translate();
	public String isFlag(){
		return null;
 	}

	public String needFlag(){
		return null;
	}

	public boolean SetImme(int imme) {
		return true;
	}
	
	public int getLine() {
		return linenum;
	}
	public int getChar() {
		return charnum;
	}

	public int getAddr() {
		return -1;
	}

	public int increaseAddr() {
		return 1;
	}

	protected int linenum, charnum;
} 

class AriLog extends InstrNode {
	public AriLog(int line, int Char, String func, int rd, int rs, int rt) {
		this.func = func;
		this.rd = rd;
		this.rs = rs;
		this.rt = rt;
		this.linenum = line;
		this.charnum = Char;
	}

	public void translate() {
		System.out.println(func+HEX[rd]+HEX[rs]+HEX[rt]);
	}
	private String func;
	private int rd, rs,rt;
}

class LdSw extends InstrNode {
	public LdSw(int line, int Char, String func, int rd, int rs) {
		this.func = func;
		this.rd = rd;
		this.rs = rs;
		this.linenum = line;
		this.charnum = Char;
		this.mode ="0";
	}

	public LdSw(int line, int Char, String func, int rd, int rs, int mode) {
		this.func = func;
		this.rd = rd;
		this.rs = rs;
		this.linenum = line;
		this.charnum = Char;
		this.mode ="1";
	}
	public void translate() {
		System.out.println(func+HEX[rd]+HEX[rs]+mode);
	}

	private String func, mode;
	private int rd, rs;
}

class LdImme extends InstrNode {
	public LdImme(int line, int Char, String func, int rd, int imme) {
		this.func = func;
		this.rd = rd;
		this.imme = imme;
		this.linenum = line;
		this.charnum = Char;
	}
	
	public void translate(){
		System.out.println(func+HEX[rd]+HEX[imme/16]+HEX[imme%16]);
	}

	private String func;
	private int rd, imme;
}

class Shift extends InstrNode {
	public Shift(int line, int Char, int rd, int mode, int imme) {
		this.rd =rd;
		this.mode = mode;
		this.imme = imme;
		this.linenum = line;
		this.charnum = Char;
	}

	public void translate() {
		System.out.println("7"+HEX[rd]+HEX[mode]+HEX[imme]);
	}
	private int rd, mode, imme;
}

class Branch extends InstrNode {
	public Branch(int line, int Char, int cond, int imme) {
		this.cond = cond;
		this.imme = imme;
		this.flag = null;
		this.linenum = line;
		this.charnum = Char;
	}

	public Branch(int line, int Char, int cond, String flag) {
		this.cond = cond;
		this.flag = flag;
		this.imme = -1;
		this.linenum = line;
		this.charnum = Char;
	}

	public void translate() {
		if (imme == -1) {
			System.exit(-1);
		}
		System.out.println("8"+HEX[cond*2+imme/256]+HEX[imme/16%16]+HEX[imme%16]);
	}

	public String needFlag(){
		return flag;
	}

	public boolean SetImme(int imme) {
		if (imme > 255 || imme < -256) 
		{
			System.err.print("Error: unreachable flag");
			return false;
		}
		int deadloop = -1;
		if (imme == 0) {
			System.err.print("Warning: a possible dead loop");
			deadloop =0;
		}
		if (imme < 0) 
			imme +=512;
		this.imme = imme;
		if (deadloop == 0) 
			return false;
		return true;
	}

	private int cond, imme;
	private String flag;
}

class JLink extends InstrNode {
	public JLink(int line, int Char, int imme) {
		this.imme = imme;
		this.flag = null;
		this.linenum = line;
		this.charnum = Char;
	}

	public JLink(int line, int Char, String flag) {
		this.flag = flag;
		this.imme = -1;
		this.linenum = line;
		this.charnum = Char;
	}

	public void translate() {
		if (imme == -1) {
			System.exit(-1);
		}
		System.out.println("9"+HEX[imme/256]+HEX[imme/16%16] +HEX[imme%16]);
	}

	public String needFlag(){
		return flag;
	}

	public boolean SetImme(int imme) {
		if (imme >2047 || imme < -2048) {
			System.err.print("Error: unreachable flag");
			return false;
		}
		if (imme == 0) {
			System.err.print("Error: a dead loop");
			return false;
		}

		if (imme < 0)
			imme += 4096;

		this.imme = imme;
		return true;
	}

	private int imme;
	private String flag;
}

class Flag extends InstrNode {
	public Flag (int line, int Char, String flag) {
		this.flag = flag;
		this.linenum = line;
		this.charnum = Char;
	}

	public void translate(){
		System.err.println("Error");
	}

	public String isFlag(){
		return flag;
	}

	private String flag;
}

class JReg extends InstrNode {
	public JReg(int line, int Char, int rd) {
		this.rd = rd;
		this.mode = 0;
		this.linenum = line;
		this.charnum = Char;
	}

	public JReg(int line, int Char, int rd, int mode) {
		this.rd = rd;
		this.mode = mode;
		this.linenum = line;
		this.charnum = Char;
	}

	public void translate() {
		System.out.println("a" + HEX[rd] +"0" +HEX[mode]);
	}
	private int rd, mode;
}

class Send extends InstrNode {
	public Send(int line, int Char, int rd, int mode) {
		this.rd = rd;
		this.mode = mode;
		this.imme = -1;
		this.linenum = line;
		this.charnum = Char;
	}
	public Send(int line, int Char, int imme) {
		this.imme = imme;
		this.linenum = line;
		this.charnum = Char;
	}

	public Send(int line, int Char, String s) {
		this.linenum = line;
		this.charnum = Char;
		this.imme = 0;
		int i = 0;
		immeList = new ArrayList<Integer>();
		while ( i < s.length() ){
			if (s.charAt(i) == '\\') {
				i++;
				if (s.charAt(i) == 'n')
					immeList.add(13);
				else if (s.charAt(i) == 't')
					immeList.add(9);
				else
					immeList.add((int)s.charAt(i));
			}
			else 
				immeList.add((int)s.charAt(i));
			i++;
		}
	}

	public void translate() {
		if (imme == -1)
			System.out.println("c"+HEX[rd]+"0"+HEX[mode]);
		else if(immeList == null)
			System.out.println("c"+HEX[imme/16]+HEX[imme%16]+HEX[2]);
		else
			for (Integer imme : immeList)
				System.out.println("c"+HEX[imme/16] + HEX[imme%16] + HEX[2]);
	}

	public int increaseAddr() {
		if (immeList == null)
			return 1;
		return immeList.size();
	}

	private int rd, imme, mode;
	private ArrayList<Integer> immeList;
}

class Set extends InstrNode {
	public Set(int line, int Char, int mode) {
		this.mode = mode;
		this.linenum = line;
		this.charnum = Char;
 	}

 	public void translate() {
		System.out.println("d"+HEX[mode*4]+"00");
	}
	private int mode;
}  

class Ctrl extends InstrNode {
	public Ctrl(int line, int Char, int rd, int mode, int addr) {
		this.linenum = line;
		this.charnum = Char;
		this.rd = rd;
		this.mode = mode;
		this.addr = addr;
	}

	public void translate() {
		System.out.println("b"+HEX[rd]+HEX[mode*4+addr/16]+HEX[addr%16]);
	}

	private int rd, mode, addr;
}
class Rv extends InstrNode {
	public Rv(int line, int Char, int rd, int device, int addr) {
		this.linenum = line;
		this.charnum = Char;
		this.rd = rd;
		this.device = device;
		this.addr = addr;
	}

	public void translate() {
		System.out.println("e"+HEX[rd]+HEX[device*8+addr/16]+HEX[addr % 16]);
	}

	private int rd, device, addr;
}
class Addr extends InstrNode {
	public Addr(int line, int Char, int addr) {
		this.linenum = line;
		this.charnum = Char;
		this.addr = addr;
	}

	public void translate() {
		System.out.println("@"+HEX[addr/4096]+HEX[addr/256%16]+HEX[addr/16%16]+HEX[addr%16]);
	}

	public int getAddr() {
		return addr;
	}

	private int addr;
}
class La extends InstrNode {
	public La(int line, int Char, int rd, String flag) {
		this.linenum = line;
		this.charnum = Char;
		this.rd = rd;
		this.flag = flag;
		this.imme = -1;
	}
	
	public void translate() {
		if(this.imme == -1) {
			System.err.println("Error");
			System.exit(-1);
		}
		System.out.println("6"+HEX[rd]+HEX[imme %256/16]+HEX[imme % 16]); // load low first;
		System.out.println("5"+HEX[rd]+HEX[imme /4096]+HEX[imme%4096/256]);
	}
	public String needFlag() {
		return this.flag;
	}

	public boolean SetImme(int Imme) {
		this.imme = Imme;
		if (this.imme <0)
			this.imme += 65536;
		return true;
	}

	public int increaseAddr() {
		return 2;
	}
	private int rd, imme;
	private String flag;
}
class Static extends InstrNode {
	public Static(int line, int Char, String data) {
		this.linenum = line;
		this.charnum = Char;
		this.data = data;
	}
	public void translate() {
		System.out.println(data);
	}
	private String data;
}

class Addi extends InstrNode {
	public Addi(int line, int Char, int rd, int rs, int imme) {
		this.linenum = line;
		this.charnum = Char;
		this.rd = rd;
		this.rs = rs;
		this.imme = imme;
	}
	public void translate() {
		System.out.println("f"+HEX[rd]+HEX[rs]+HEX[imme]);
	}
	private int rd, rs, imme;
}
class Comment extends InstrNode {
	public Comment(int line, int Char, String comment) {
		this.linenum  = line;
		this.charnum = Char;
		this.comment = comment;
	}

	public void translate() {
	//	System.out.println(comment);
	}

	public int increaseAddr() {
		return 0;
	}

	private String comment;
}
