import java.io.*;
import java.util.*;

abstract class ASTnode {
	abstract public void translate();
}

class ProgramNode extends ASTnode {
	public ProgramNode(InstrListNode L) {
		myInstrList = L;
	}

	public void translate() {
		myInstrList.translate();
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

	public void translate() {
		Iterator it = myInstrs.iterator();
		try {
			while(it.hasNext()) {
				((InstrNode)it.next()).translate();
			}
		} catch (NoSuchElementException ex) {
			System.err.println("Empty program");
			System.exit(-1);
		}
	}

	public void FlagCheck() {
		int addr = 0;
		HashMap<String, Integer> Flags = new HashMap<String, Integer>();
		while (addr < myInstrs.size()) {
			InstrNode instr = myInstrs.get(addr);
			if (instr.isFlag() != null) {
				if (Flags.containsKey(instr.isFlag())) {
					System.err.println("Warning: Duplicated flags: "+instr.isFlag()+", ingore it. @"+instr.getLine()+":"+instr.getChar());
				}
				else
					Flags.put(instr.isFlag(), addr);
				myInstrs.remove(addr);
			}
			else
				addr++;
		}
		addr = 0;
		for (InstrNode instr: myInstrs) {
			if (instr.needFlag() != null) {
				if (!Flags.containsKey(instr.needFlag())) {
					System.err.println("Error: flag: "+instr.needFlag() + " is not found. @"+instr.getLine()+":"+instr.getChar());
					System.exit(-1);
				}
				if (!instr.SetImme(Flags.get(instr.needFlag()) - addr))
					System.err.println(" @"+instr.getLine()+":"+instr.getChar());
			}
			addr++;
		}
	}
	private List<InstrNode> myInstrs; 
}

abstract class InstrNode extends ASTnode {
	public String[] HEX = {"0","1","2","3","4","5","6","7","8","9",
						   "a","b","c","d","e","f"};
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
	}
	public void translate() {
		System.out.println(func+HEX[rd]+HEX[rs]+"0");
	}

	private String func;
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

	public void translate() {
		if (imme == -1)
			System.out.println("c"+HEX[rd]+"0"+HEX[mode]);
		else
			System.out.println("c"+HEX[imme/16]+HEX[imme%16]+HEX[2]);
	}

	private int rd, imme, mode;
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
