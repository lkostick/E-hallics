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
	private List<InstrNode> myInstrs; 
}
class InstrNode extends ASTnode {
	public InstrNode(int FUNC, int Rd, int Rs, int Rt) {
		type = 1;
		func = FUNC;
		this.Rd = Rd;
		this.Rs = Rs;
		this.Rt = Rt;
	}

	public InstrNode(int FUNC, int Rd, int Imme) {
		type = 2;
		func = FUNC;
		this.Rd = Rd;
		this.Imme = Imme;
	}

	public void translate() {
		String [] Binary_4bit = {"0","1","2","3",
								 "4","5","6","7",
								 "8","9","a","b",
								 "c","d","e","f"};
		if (type == 1) {
			System.out.println(Binary_4bit[func]+
							   Binary_4bit[Rd]+
							   Binary_4bit[Rs]+
							   Binary_4bit[Rt]);
		}
		else if (type == 2) {
			System.out.println(Binary_4bit[func]+
							   Binary_4bit[Rd]+
							   Binary_4bit[Imme / 16]+
							   Binary_4bit[Imme % 16]);
		}
	}

	private int type, func, Rd, Rs, Rt, Imme;
}
