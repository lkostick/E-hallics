import java.io.*;
import java.util.*;

abstract class ASTnode { 
    // every subclass must provide an unparse operation
    abstract public void unparse(PrintWriter p, int indent);

    // this method can be used by the unparse methods to do indenting
    protected void doIndent(PrintWriter p, int indent) {
        for (int k=0; k<indent; k++) p.print(" ");
    }
}

// **********************************************************************
// ProgramNode,  DeclListNode, FormalsListNode, FnBodyNode,
// StmtListNode, ExpListNode
// **********************************************************************

class ProgramNode extends ASTnode {
    public ProgramNode(DeclListNode L) {
        myDeclList = L;
    }

    /**
     * nameAnalysis
     * Creates an empty symbol table for the outermost scope, then processes
     * all of the globals, struct defintions, and functions in the program.
     */
    public void nameAnalysis() {
        SymTable symTab = new SymTable();
        myDeclList.nameAnalysis(symTab, 0);

		// Check for main()
		SemSym MAIN= symTab.lookupLocal("main");
		if (MAIN == null || !MAIN.getType().isFnType()) {
			ErrMsg.fatal(0,0,"No main function.");
		}
    }

	public void codeGen(PrintWriter outFile) {
		Codegen.p = outFile;
		Codegen.strLiteral = new HashMap<String, String>();
		Codegen.strLabel = new LinkedList<String>();
		Codegen.labelSize = new HashMap<String, Integer>();
		int start_position = 0x1000;
		Codegen.generateWithComment("@"+Integer.toString(start_position,16), "Program Store Position");
		Codegen.generateWithComment("","Set SP and FP pointer");
		Codegen.generateWithComment("ll","", Codegen.SP, "0");
		Codegen.generateWithComment("lh", "", Codegen.SP, "0x"+Integer.toString(0x40+start_position/256,16));
		Codegen.generateWithComment("add", "", Codegen.FP, Codegen.SP, "R0");
		Codegen.generateWithComment("la", "Get Main Position", Codegen.T0, "main");
		Codegen.generateWithComment("jr", "Start Program", Codegen.T0);
		myDeclList.codeGen();
		Codegen.generateWithComment("", "Static Data");
		int addr = start_position + 0x2000;
		for (String label : Codegen.strLabel) {
			Codegen.generateWithComment("@"+Integer.toString(addr, 16),"");
			Codegen.genLabel(label);
			addr += Codegen.labelSize.get(label);	
		}
		Codegen.generateWithComment("@"+Integer.toString(addr, 16),"");
	}
    
    /**
     * typeCheck
     */
    public void typeCheck() {
        myDeclList.typeCheck();
    }
    
    public void unparse(PrintWriter p, int indent) {
        myDeclList.unparse(p, indent);
    }

    // 1 kid
    private DeclListNode myDeclList;
}

class DeclListNode extends ASTnode {
    public DeclListNode(List<DeclNode> S) {
        myDecls = S;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, process all of the decls in the list.
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        return nameAnalysis(symTab, symTab, offset);
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab and a global symbol table globalTab
     * (for processing struct names in variable decls), process all of the 
     * decls in the list.
     */    
    public int nameAnalysis(SymTable symTab, SymTable globalTab, int offset) {
        for (DeclNode node : myDecls) {
            if (node instanceof VarDeclNode) {
                SemSym sym = ((VarDeclNode)node).nameAnalysis(symTab, globalTab);
				sym.setLevel(symTab.getLevel());
				sym.setOffset(offset);
				offset -= ((VarDeclNode)node).getSize();
            } else {
                node.nameAnalysis(symTab);
            }
		}
		return -offset;
    }    
   	
    /**
     * typeCheck
     */
    public void typeCheck() {
        for (DeclNode node : myDecls) {
            node.typeCheck();
        }
    }

	/**
	 * codeGen
	 */
	public void codeGen() {
		for (DeclNode node: myDecls) {
			node.codeGen();
		}
	}
    
    public void unparse(PrintWriter p, int indent) {
        Iterator it = myDecls.iterator();
        try {
            while (it.hasNext()) {
                ((DeclNode)it.next()).unparse(p, indent);
            }
        } catch (NoSuchElementException ex) {
            System.err.println("unexpected NoSuchElementException in DeclListNode.print");
            System.exit(-1);
        }
    }

    // list of kids (DeclNodes)
    private List<DeclNode> myDecls;
}

class FormalsListNode extends ASTnode {
    public FormalsListNode(List<FormalDeclNode> S) {
        myFormals = S;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * for each formal decl in the list
     *     process the formal decl
     *     if there was no error, add type of formal decl to list
     */
    public List<Type> nameAnalysis(SymTable symTab) {
		int offset = 0;
        List<Type> typeList = new LinkedList<Type>();
        for (FormalDeclNode node : myFormals) {
            SemSym sym = node.nameAnalysis(symTab);
            if (sym != null) {
                typeList.add(sym.getType());
            }
			sym.setLevel(symTab.getLevel());
			sym.setOffset(offset);
			offset -= 1;
        }
        return typeList;
    }    
    
    /**
     * Return the number of formals in this list.
     */
    public int length() {
        return myFormals.size();
    }
    
    public void unparse(PrintWriter p, int indent) {
        Iterator<FormalDeclNode> it = myFormals.iterator();
        if (it.hasNext()) { // if there is at least one element
            it.next().unparse(p, indent);
            while (it.hasNext()) {  // print the rest of the list
                p.print(", ");
                it.next().unparse(p, indent);
            }
        } 
    }

    // list of kids (FormalDeclNodes)
    private List<FormalDeclNode> myFormals;
}

class FnBodyNode extends ASTnode {
    public FnBodyNode(DeclListNode declList, StmtListNode stmtList) {
        myDeclList = declList;
        myStmtList = stmtList;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * - process the declaration list
     * - process the statement list
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        int size = myDeclList.nameAnalysis(symTab, offset - 2);
        size = myStmtList.nameAnalysis(symTab, size);
		return size;
    }    
 
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        myStmtList.typeCheck(retType);
    }    
          
    public void unparse(PrintWriter p, int indent) {
        myDeclList.unparse(p, indent);
        myStmtList.unparse(p, indent);
    }

	public void codeGen(int parameter, int localVariable, String fnName) {
		Codegen.genPush(Codegen.RA);
		Codegen.genPush(Codegen.FP);
		Codegen.generateWithComment("ll", "", Codegen.T0, Integer.toString((parameter + 2) % 256));
		if (parameter + 2 > 256) {
			Codegen.generateWithComment("lh", "", Codegen.T0, Integer.toString((parameter + 2) / 256));
		}
		Codegen.generateWithComment("add", "", Codegen.FP, Codegen.SP, Codegen.T0);
		// Change SP if it has local variables
		if (localVariable != 0) {
			Codegen.generateWithComment("ll", "", Codegen.T0, Integer.toString(localVariable % 256));
			if (localVariable > 256) {
				Codegen.generateWithComment("lh", "", Codegen.T0, Integer.toString(localVariable / 256));
			}
			Codegen.generateWithComment("sub", "",  Codegen.SP, Codegen.SP, Codegen.T0);
		}

		// generate function body
		myStmtList.codeGen(fnName);

		// generate exit
		Codegen.genLabel("_"+fnName+"_Exit", "FUNCTION EXIT");
		Codegen.generateWithComment("ll", "", Codegen.T0, Integer.toString(parameter % 256));
		if (parameter > 256) {
			Codegen.generateWithComment("lh", "", Codegen.T0, Integer.toString(parameter / 256));
		}
		Codegen.generateWithComment("sub", "",  Codegen.T1, Codegen.FP, Codegen.T0);
		Codegen.generateWithComment("ld", "load return address", Codegen.RA, Codegen.T1);
		Codegen.generateWithComment("add", "save control link", Codegen.T1, Codegen.FP, "R0");
		Codegen.generateWithComment("ll", "", Codegen.T2, "1");
		Codegen.generateWithComment("lh", "", Codegen.T2, "0");
		Codegen.generateWithComment("add", "", Codegen.T0, Codegen.T0, Codegen.T2);
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.FP, Codegen.T0);
		Codegen.generateWithComment("ld", "restore FP", Codegen.FP, Codegen.T0);
		Codegen.generateWithComment("add", "restore SP", Codegen.SP, Codegen.T1, "R0");
		if (fnName.equals("main")) {
			Codegen.generateWithComment("set", "only do this for main", "idle");
		}
		else {
			Codegen.generateWithComment("jr", "return", Codegen.RA);
		}
	}

    // 2 kids
    private DeclListNode myDeclList;
    private StmtListNode myStmtList;
}

class StmtListNode extends ASTnode {
    public StmtListNode(List<StmtNode> S) {
        myStmts = S;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, process each statement in the list.
     */
    public int nameAnalysis(SymTable symTab, int offset) {
		int size = offset;
        for (StmtNode node : myStmts) {
            size = node.nameAnalysis(symTab, size);
        }
		return size;
    }    
    
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        for(StmtNode node : myStmts) {
            node.typeCheck(retType);
        }
    }
    

	public void codeGen(String fnName) {
		for (StmtNode node: myStmts)
			node.codeGen(fnName);
	}

    public void unparse(PrintWriter p, int indent) {
        Iterator<StmtNode> it = myStmts.iterator();
        while (it.hasNext()) {
            it.next().unparse(p, indent);
        }
    }

    // list of kids (StmtNodes)
    private List<StmtNode> myStmts;
}

class ExpListNode extends ASTnode {
    public ExpListNode(List<ExpNode> S) {
        myExps = S;
    }
    
    public int size() {
        return myExps.size();
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, process each exp in the list.
     */
    public void nameAnalysis(SymTable symTab) {
        for (ExpNode node : myExps) {
            node.nameAnalysis(symTab);
        }
    }
    
    /**
     * typeCheck
     */
    public void typeCheck(List<Type> typeList) {
        int k = 0;
        try {
            for (ExpNode node : myExps) {
                Type actualType = node.typeCheck();     // actual type of arg
                
                if (!actualType.isErrorType()) {        // if this is not an error
                    Type formalType = typeList.get(k);  // get the formal type
                    if (!formalType.equals(actualType)) {
                        ErrMsg.fatal(node.lineNum(), node.charNum(),
                                     "Type of actual does not match type of formal");
                    }
                }
                k++;
            }
        } catch (NoSuchElementException e) {
            System.err.println("unexpected NoSuchElementException in ExpListNode.typeCheck");
            System.exit(-1);
        }
    }

	public void codeGen() {
		for(ExpNode node : myExps) {
			node.codeGen();
		}
	}
    
    public void unparse(PrintWriter p, int indent) {
        Iterator<ExpNode> it = myExps.iterator();
        if (it.hasNext()) { // if there is at least one element
            it.next().unparse(p, indent);
            while (it.hasNext()) {  // print the rest of the list
                p.print(", ");
                it.next().unparse(p, indent);
            }
        } 
    }

    // list of kids (ExpNodes)
    private List<ExpNode> myExps;
}

// **********************************************************************
// DeclNode and its subclasses
// **********************************************************************

abstract class DeclNode extends ASTnode {
    /**
     * Note: a formal decl needs to return a sym
     */
    abstract public SemSym nameAnalysis(SymTable symTab);

	abstract public void codeGen();

    // default version of typeCheck for non-function decls
    public void typeCheck() { }
}

class VarDeclNode extends DeclNode {
    public VarDeclNode(TypeNode type, IdNode id, int size) {
        myType = type;
        myId = id;
        mySize = size;
    }

    /**
     * nameAnalysis (overloaded)
     * Given a symbol table symTab, do:
     * if this name is declared void, then error
     * else if the declaration is of a struct type, 
     *     lookup type name (globally)
     *     if type name doesn't exist, then error
     * if no errors so far,
     *     if name has already been declared in this scope, then error
     *     else add name to local symbol table     
     *
     * symTab is local symbol table (say, for struct field decls)
     * globalTab is global symbol table (for struct type names)
     * symTab and globalTab can be the same
     */
    public SemSym nameAnalysis(SymTable symTab) {
        return nameAnalysis(symTab, symTab);
    }
   	
	public int getSize() {
		if (mySize == NOT_STRUCT )
			return 1;
		else
			return mySize;
	}

    public SemSym nameAnalysis(SymTable symTab, SymTable globalTab) {
        boolean badDecl = false;
        String name = myId.name();
        SemSym sym = null;
        IdNode structId = null;

        if (myType instanceof VoidNode) {  // check for void type
            ErrMsg.fatal(myId.lineNum(), myId.charNum(), 
                         "Non-function declared void");
            badDecl = true;        
        }
        
        else if (myType instanceof StructNode) {
            structId = ((StructNode)myType).idNode();
            sym = globalTab.lookupGlobal(structId.name());
            
            // if the name for the struct type is not found, 
            // or is not a struct type
            if (sym == null || !(sym instanceof StructDefSym)) {
                ErrMsg.fatal(structId.lineNum(), structId.charNum(), 
                             "Invalid name of struct type");
                badDecl = true;
            }
            else {
                structId.link(sym);
            }
        }
        
        if (symTab.lookupLocal(name) != null) {
            ErrMsg.fatal(myId.lineNum(), myId.charNum(), 
                         "Multiply declared identifier");
            badDecl = true;            
        }
        
        if (!badDecl) {  // insert into symbol table
            try {
                if (myType instanceof StructNode) {
                    sym = new StructSym(structId);
					mySize = globalTab.lookupGlobal(structId.name()).getOffset();
                }
                else {
                    sym = new SemSym(myType.type());
                }
                symTab.addDecl(name, sym);
                myId.link(sym);
            } catch (DuplicateSymException ex) {
                System.err.println("Unexpected DuplicateSymException " +
                                   " in VarDeclNode.nameAnalysis");
                System.exit(-1);
            } catch (EmptySymTableException ex) {
                System.err.println("Unexpected EmptySymTableException " +
                                   " in VarDeclNode.nameAnalysis");
                System.exit(-1);
            }
        }
        
        return sym;
    }    
    
	public void codeGen() {
		if (myId.sym().getLevel() == 0) { // global variable
			String label = "_"+myId.name();
			Codegen.strLabel.add(label);
			Codegen.labelSize.put(label, (mySize == -1)? 1: mySize);
		}
	}
    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        myType.unparse(p, 0);
        p.print(" ");
        p.print(myId.name());
        p.println(";");
    }

    // 3 kids
    private TypeNode myType;
    private IdNode myId;
    private int mySize;  // use value NOT_STRUCT if this is not a struct type

    public static int NOT_STRUCT = -1;
}

class FnDeclNode extends DeclNode {
    public FnDeclNode(TypeNode type,
                      IdNode id,
                      FormalsListNode formalList,
                      FnBodyNode body) {
        myType = type;
        myId = id;
        myFormalsList = formalList;
        myBody = body;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * if this name has already been declared in this scope, then error
     * else add name to local symbol table
     * in any case, do the following:
     *     enter new scope
     *     process the formals
     *     if this function is not multiply declared,
     *         update symbol table entry with types of formals
     *     process the body of the function
     *     exit scope
     */
    public SemSym nameAnalysis(SymTable symTab) {
        String name = myId.name();
        FnSym sym = null;
        
        if (symTab.lookupLocal(name) != null) {
            ErrMsg.fatal(myId.lineNum(), myId.charNum(),
                         "Multiply declared identifier");
        }
        
        else { // add function name to local symbol table
            try {
                sym = new FnSym(myType.type(), myFormalsList.length());
                symTab.addDecl(name, sym);
                myId.link(sym);
            } catch (DuplicateSymException ex) {
                System.err.println("Unexpected DuplicateSymException " +
                                   " in FnDeclNode.nameAnalysis");
                System.exit(-1);
            } catch (EmptySymTableException ex) {
                System.err.println("Unexpected EmptySymTableException " +
                                   " in FnDeclNode.nameAnalysis");
                System.exit(-1);
            }
        }
        
        symTab.addScope();  // add a new scope for locals and params
        
        // process the formals
        List<Type> typeList = myFormalsList.nameAnalysis(symTab);
        if (sym != null) {
            sym.addFormals(typeList);
        }
		// For FnNode, level store the size of formal, offset store the size of local variable
		sym.setLevel(typeList.size());
        
        int size = myBody.nameAnalysis(symTab, -sym.getLevel()) - sym.getLevel() - 2; // process the function body
        sym.setOffset(size);
        try {
            symTab.removeScope();  // exit scope
        } catch (EmptySymTableException ex) {
            System.err.println("Unexpected EmptySymTableException " +
                               " in FnDeclNode.nameAnalysis");
            System.exit(-1);
        }
        return null;
    } 
       
    /**
     * typeCheck
     */
    public void typeCheck() {
        myBody.typeCheck(myType.type());
    }
        
	public void codeGen() {
		if (myId.name().equals("main")) {//generate for main()
			Codegen.genLabel("main","METHOD ENTRY");
		}
		else {
			Codegen.genLabel("_"+myId.name(),"METHOD ENTRY");
		}
		myBody.codeGen(myId.sym().getLevel(), myId.sym().getOffset(), myId.name());
	}

    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        myType.unparse(p, 0);
        p.print(" ");
        p.print(myId.name());
        p.print("(");
        myFormalsList.unparse(p, 0);
        p.println(") {");
        myBody.unparse(p, indent+4);
        p.println("}\n");
    }

    // 4 kids
    private TypeNode myType;
    private IdNode myId;
    private FormalsListNode myFormalsList;
    private FnBodyNode myBody;
}

class FormalDeclNode extends DeclNode {
    public FormalDeclNode(TypeNode type, IdNode id) {
        myType = type;
        myId = id;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * if this formal is declared void, then error
     * else if this formal is already in the local symble table,
     *     then issue multiply declared error message and return null
     * else add a new entry to the symbol table and return that Sym
     */
    public SemSym nameAnalysis(SymTable symTab) {
        String name = myId.name();
        boolean badDecl = false;
        SemSym sym = null;
        
        if (myType instanceof VoidNode) {
            ErrMsg.fatal(myId.lineNum(), myId.charNum(), 
                         "Non-function declared void");
            badDecl = true;        
        }
        
        if (symTab.lookupLocal(name) != null) {
            ErrMsg.fatal(myId.lineNum(), myId.charNum(), 
                         "Multiply declared identifier");
            badDecl = true;
        }
        
        if (!badDecl) {  // insert into symbol table
            try {
                sym = new SemSym(myType.type());
                symTab.addDecl(name, sym);
                myId.link(sym);
            } catch (DuplicateSymException ex) {
                System.err.println("Unexpected DuplicateSymException " +
                                   " in VarDeclNode.nameAnalysis");
                System.exit(-1);
            } catch (EmptySymTableException ex) {
                System.err.println("Unexpected EmptySymTableException " +
                                   " in VarDeclNode.nameAnalysis");
                System.exit(-1);
            }
        }
        
        return sym;
    }    
    
    public void unparse(PrintWriter p, int indent) {
        myType.unparse(p, 0);
        p.print(" ");
        p.print(myId.name());
    }

	public void codeGen() {
	}

    // 2 kids
    private TypeNode myType;
    private IdNode myId;
}

class StructDeclNode extends DeclNode {
    public StructDeclNode(IdNode id, DeclListNode declList) {
        myId = id;
        myDeclList = declList;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * if this name is already in the symbol table,
     *     then multiply declared error (don't add to symbol table)
     * create a new symbol table for this struct definition
     * process the decl list
     * if no errors
     *     add a new entry to symbol table for this struct
     */
    public SemSym nameAnalysis(SymTable symTab) {
        String name = myId.name();
        boolean badDecl = false;
        
        if (symTab.lookupLocal(name) != null) {
            ErrMsg.fatal(myId.lineNum(), myId.charNum(), 
                         "Multiply declared identifier");
            badDecl = true;            
        }

        SymTable structSymTab = new SymTable();
        
        // process the fields of the struct
        int offset = myDeclList.nameAnalysis(structSymTab, symTab, 0);
        
        if (!badDecl) {
            try {   // add entry to symbol table
                StructDefSym sym = new StructDefSym(structSymTab);
				sym.setOffset(offset);
                symTab.addDecl(name, sym);
                myId.link(sym);
            } catch (DuplicateSymException ex) {
                System.err.println("Unexpected DuplicateSymException " +
                                   " in StructDeclNode.nameAnalysis");
                System.exit(-1);
            } catch (EmptySymTableException ex) {
                System.err.println("Unexpected EmptySymTableException " +
                                   " in StructDeclNode.nameAnalysis");
                System.exit(-1);
            }
        }
        
        return null;
    }    
    
    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        p.print("struct ");
        p.print(myId.name());
        p.println("{");
        myDeclList.unparse(p, indent+4);
        doIndent(p, indent);
        p.println("};\n");

    }

	public void codeGen() {
	}

    // 2 kids
    private IdNode myId;
    private DeclListNode myDeclList;
}

// **********************************************************************
// TypeNode and its Subclasses
// **********************************************************************

abstract class TypeNode extends ASTnode {
    /* all subclasses must provide a type method */
    abstract public Type type();
}

class IntNode extends TypeNode {
    public IntNode() {
    }

    /**
     * type
     */
    public Type type() {
        return new IntType();
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("int");
    }
}

class BoolNode extends TypeNode {
    public BoolNode() {
    }

    /**
     * type
     */
    public Type type() {
        return new BoolType();
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("bool");
    }
}

class VoidNode extends TypeNode {
    public VoidNode() {
    }
    
    /**
     * type
     */
    public Type type() {
        return new VoidType();
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("void");
    }
}

class StructNode extends TypeNode {
    public StructNode(IdNode id) {
        myId = id;
    }

    public IdNode idNode() {
        return myId;
    }
    
    /**
     * type
     */
    public Type type() {
        return new StructType(myId);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("struct ");
        p.print(myId.name());
    }
    
    // 1 kid
    private IdNode myId;
}

// **********************************************************************
// StmtNode and its subclasses
// **********************************************************************

abstract class StmtNode extends ASTnode {
    abstract public int nameAnalysis(SymTable symTab, int offset);
    abstract public void typeCheck(Type retType);
	abstract public void codeGen(String fnName);
}

class AssignStmtNode extends StmtNode {
    public AssignStmtNode(AssignNode assign) {
        myAssign = assign;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's child
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        myAssign.nameAnalysis(symTab);
		return offset;
    }
    
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        myAssign.typeCheck();
    }
        
    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        myAssign.unparse(p, -1); // no parentheses
        p.println(";");
    }

	public void codeGen(String fnName) {
		myAssign.codeGen();
		Codegen.genPop(Codegen.T0);
	}
    // 1 kid
    private AssignNode myAssign;
}

class PostIncStmtNode extends StmtNode {
    public PostIncStmtNode(ExpNode exp) {
        myExp = exp;
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's child
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        myExp.nameAnalysis(symTab);
		return offset;
    }
    
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        Type type = myExp.typeCheck();
        
        if (!type.isErrorType() && !type.isIntType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Arithmetic operator applied to non-numeric operand");
        }
    }
        
	public void codeGen(String fnName) {
		myExp.codeGen();
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("ll","",Codegen.T1, "0x01");
		Codegen.generate("add", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.genPush(Codegen.T0);
		if (myExp instanceof IdNode) {
			((IdNode)myExp).genAddr();
		}
		else if (myExp instanceof DotAccessExpNode) {
			((DotAccessExpNode)myExp).genAddr();
		}
		else {
			System.err.println("error");
			System.exit(-1);
		}
		Codegen.generateWithComment("", "POST INCREASE");
		Codegen.genPop(Codegen.T0);
		Codegen.genPop(Codegen.T1);
		Codegen.generateWithComment("sw", "",  Codegen.T1, Codegen.T0);
	}

    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        myExp.unparse(p, 0);
        p.println("++;");
    }

    // 1 kid
    private ExpNode myExp;
}

class PostDecStmtNode extends StmtNode {
    public PostDecStmtNode(ExpNode exp) {
        myExp = exp;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's child
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        myExp.nameAnalysis(symTab);
		return offset;
    }
    
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        Type type = myExp.typeCheck();
        
        if (!type.isErrorType() && !type.isIntType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Arithmetic operator applied to non-numeric operand");
        }
    }
        
	public void codeGen(String fnName) {
		myExp.codeGen();
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("ll", "", Codegen.T1, "0x01");
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.genPush(Codegen.T0);
		if (myExp instanceof IdNode) {
			((IdNode)myExp).genAddr();
		}
		else if (myExp instanceof DotAccessExpNode) {
			((DotAccessExpNode)myExp).genAddr();
		}
		else {
			System.err.println("error");
			System.exit(-1);
		}

		Codegen.generateWithComment("", "POST DECREASE");
		Codegen.genPop(Codegen.T0);
		Codegen.genPop(Codegen.T1);
		Codegen.generateWithComment("sw", "", Codegen.T1, Codegen.T0);
	}

    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        myExp.unparse(p, 0);
        p.println("--;");
    }
    
    // 1 kid
    private ExpNode myExp;
}

class ReadStmtNode extends StmtNode {
    public ReadStmtNode(ExpNode e) {
        myExp = e;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's child
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        myExp.nameAnalysis(symTab);
		return offset;
    }    
 
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        Type type = myExp.typeCheck();
        
        if (type.isFnType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Attempt to read a function");
        }
        
        if (type.isStructDefType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Attempt to read a struct name");
        }
        
        if (type.isStructType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Attempt to read a struct variable");
        }
    }
    
	public void codeGen(String fnName) {
		Codegen.generateWithComment("","READ");
		Codegen.generate("li", Codegen.V0, "5");
		Codegen.generate("syscall");
		if( myExp instanceof IdNode) {
			((IdNode)myExp).genAddr();
		}
		else if (myExp instanceof DotAccessExpNode) {
			((DotAccessExpNode)myExp).genAddr();
		}
		else { // It is impossible to come here
			System.err.println("error");
			System.exit(-1);
		}
		Codegen.genPop(Codegen.T0);
		Codegen.generateIndexed("sw", Codegen.V0, Codegen.T0, 0);
	}

    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        p.print("cin >> ");
        myExp.unparse(p, 0);
        p.println(";");
    }

    // 1 kid (actually can only be an IdNode or an ArrayExpNode)
    private ExpNode myExp;
}

class WriteStmtNode extends StmtNode {
    public WriteStmtNode(ExpNode exp) {
        myExp = exp;
    }

    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's child
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        myExp.nameAnalysis(symTab);
		return offset;
    }

    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        Type type = myExp.typeCheck();
        
        if (type.isFnType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Attempt to write a function");
        }
        
        if (type.isStructDefType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Attempt to write a struct name");
        }
        
        if (type.isStructType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Attempt to write a struct variable");
        }
        
        if (type.isVoidType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Attempt to write void");
        }
		if (type.isStringType()) {
			V0 = 4;
		}
		else {
			V0 = 1;
		}
    }
        
	public void codeGen(String fnName) {
		myExp.codeGen();
		Codegen.generateWithComment("", "WRITE");
		Codegen.genPop(Codegen.A0);
		if (V0 == 1) {//send data
			Codegen.generateWithComment("send", "","0xff");
			Codegen.generateWithComment("send", "",Codegen.A0, "high");
			Codegen.generateWithComment("send", "",Codegen.A0,"low");
			Codegen.generateWithComment("send","","0xff");
		}
		else {//send string
			String startLab = Codegen.nextLabel();
			String finishLab = Codegen.nextLabel();
			Codegen.generateWithComment("ll", "", Codegen.T5, "0x01");
			Codegen.generateWithComment("add", "Ignore the first \"",Codegen.A0, Codegen.A0, Codegen.T5);
			Codegen.generateWithComment("ll", "\" ASCII code", Codegen.T4, "0x22");
			Codegen.genLabel(startLab);
			Codegen.generateWithComment("ld", "load send chracter", Codegen.T3, Codegen.A0);
			Codegen.generateWithComment("add","Increase address", Codegen.A0, Codegen.A0, Codegen.T5);
			Codegen.generateWithComment("sub", "", Codegen.T2, Codegen.T3, Codegen.T4);
			Codegen.generateWithComment("b","Finished when found the second \"", "eq", finishLab);
			Codegen.generateWithComment("send","",Codegen.T3, "low");
			Codegen.generateWithComment("b","","uncond",startLab);
			Codegen.genLabel(finishLab);
		}
	}

    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        p.print("cout << ");
        myExp.unparse(p, 0);
        p.println(";");
    }

    // 1 kid
    private ExpNode myExp;
	private int V0;
}

class IfStmtNode extends StmtNode {
    public IfStmtNode(ExpNode exp, DeclListNode dlist, StmtListNode slist) {
        myDeclList = dlist;
        myExp = exp;
        myStmtList = slist;
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * - process the condition
     * - enter a new scope
     * - process the decls and stmts
     * - exit the scope
     */
    public int nameAnalysis(SymTable symTab, int offset) {
		int size;
        myExp.nameAnalysis(symTab);
        symTab.addScope();
        size = myDeclList.nameAnalysis(symTab, -offset);
        size = myStmtList.nameAnalysis(symTab, size);
        try {
            symTab.removeScope();
        } catch (EmptySymTableException ex) {
            System.err.println("Unexpected EmptySymTableException " +
                               " in IfStmtNode.nameAnalysis");
            System.exit(-1);        
        }
		return size;
    }
    
     /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        Type type = myExp.typeCheck();
        
        if (!type.isErrorType() && !type.isBoolType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Non-bool expression used as an if condition");        
        }
        
        myStmtList.typeCheck(retType);
    }
       
    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        p.print("if (");
        myExp.unparse(p, 0);
        p.println(") {");
        myDeclList.unparse(p, indent+4);
        myStmtList.unparse(p, indent+4);
        doIndent(p, indent);
        p.println("}");
    }

	public void codeGen(String fnName) {
		String label = Codegen.nextLabel();
		myExp.codeGen();
		Codegen.generateWithComment("", "IF");
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("sub", "R0 is 0(FALSE)", Codegen.T0, Codegen.T0, "R0");
		Codegen.generateWithComment("b", "", "eq", label);
		myStmtList.codeGen(fnName);
		Codegen.genLabel(label);
	}

    // e kids
    private ExpNode myExp;
    private DeclListNode myDeclList;
    private StmtListNode myStmtList;
}

class IfElseStmtNode extends StmtNode {
    public IfElseStmtNode(ExpNode exp, DeclListNode dlist1,
                          StmtListNode slist1, DeclListNode dlist2,
                          StmtListNode slist2) {
        myExp = exp;
        myThenDeclList = dlist1;
        myThenStmtList = slist1;
        myElseDeclList = dlist2;
        myElseStmtList = slist2;
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * - process the condition
     * - enter a new scope
     * - process the decls and stmts of then
     * - exit the scope
     * - enter a new scope
     * - process the decls and stmts of else
     * - exit the scope
     */
    public int nameAnalysis(SymTable symTab, int offset) {
		int size;
        myExp.nameAnalysis(symTab);
        symTab.addScope();
        size = myThenDeclList.nameAnalysis(symTab, -offset);
        size = myThenStmtList.nameAnalysis(symTab, size);
        try {
            symTab.removeScope();
        } catch (EmptySymTableException ex) {
            System.err.println("Unexpected EmptySymTableException " +
                               " in IfStmtNode.nameAnalysis");
            System.exit(-1);        
        }
        symTab.addScope();
        size = myElseDeclList.nameAnalysis(symTab, -size);
        size = myElseStmtList.nameAnalysis(symTab, size);
        try {
            symTab.removeScope();
        } catch (EmptySymTableException ex) {
            System.err.println("Unexpected EmptySymTableException " +
                               " in IfStmtNode.nameAnalysis");
            System.exit(-1);        
        }
		return size;
    }
    
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        Type type = myExp.typeCheck();
        
        if (!type.isErrorType() && !type.isBoolType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Non-bool expression used as an if condition");        
        }
        
        myThenStmtList.typeCheck(retType);
        myElseStmtList.typeCheck(retType);
    }
        
	public void codeGen(String fnName) {
		String falseLabel = Codegen.nextLabel();
		String endLabel = Codegen.nextLabel();
		myExp.codeGen();
		Codegen.generateWithComment("", "IF");
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("sub","",Codegen.T0, Codegen.T0, "R0");
		Codegen.generateWithComment("b", "", "eq", falseLabel);
		myThenStmtList.codeGen(fnName);
		Codegen.generateWithComment("b","","uncond", endLabel);
		Codegen.genLabel(falseLabel, "ELSE");
		myElseStmtList.codeGen(fnName);
		Codegen.genLabel(endLabel);
	}

    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        p.print("if (");
        myExp.unparse(p, 0);
        p.println(") {");
        myThenDeclList.unparse(p, indent+4);
        myThenStmtList.unparse(p, indent+4);
        doIndent(p, indent);
        p.println("}");
        doIndent(p, indent);
        p.println("else {");
        myElseDeclList.unparse(p, indent+4);
        myElseStmtList.unparse(p, indent+4);
        doIndent(p, indent);
        p.println("}");        
    }

    // 5 kids
    private ExpNode myExp;
    private DeclListNode myThenDeclList;
    private StmtListNode myThenStmtList;
    private StmtListNode myElseStmtList;
    private DeclListNode myElseDeclList;
}

class WhileStmtNode extends StmtNode {
    public WhileStmtNode(ExpNode exp, DeclListNode dlist, StmtListNode slist) {
        myExp = exp;
        myDeclList = dlist;
        myStmtList = slist;
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * - process the condition
     * - enter a new scope
     * - process the decls and stmts
     * - exit the scope
     */
    public int nameAnalysis(SymTable symTab, int offset) {
		int size;
        myExp.nameAnalysis(symTab);
        symTab.addScope();
        size = myDeclList.nameAnalysis(symTab, -offset);
        size = myStmtList.nameAnalysis(symTab, size);
        try {
            symTab.removeScope();
        } catch (EmptySymTableException ex) {
            System.err.println("Unexpected EmptySymTableException " +
                               " in IfStmtNode.nameAnalysis");
            System.exit(-1);        
        }
		return size;
    }
    
	public void codeGen(String fnName) {
		String start = Codegen.nextLabel();
		String end = Codegen.nextLabel();
		Codegen.generateWithComment("", "WHILE");
		Codegen.genLabel(start, "START OF WHILE");
		myExp.codeGen();
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("sub","", Codegen.T0, Codegen.T0, "R0");
		Codegen.generateWithComment("b", "", "eq",  end);
		myStmtList.codeGen(fnName);
		Codegen.generateWithComment("b", "JUMP TO START", "uncond", start);
		Codegen.genLabel(end, "END OF WHILE");
	}

    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        Type type = myExp.typeCheck();
        
        if (!type.isErrorType() && !type.isBoolType()) {
            ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                         "Non-bool expression used as a while condition");        
        }
        
        myStmtList.typeCheck(retType);
    }
        
    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        p.print("while (");
        myExp.unparse(p, 0);
        p.println(") {");
        myDeclList.unparse(p, indent+4);
        myStmtList.unparse(p, indent+4);
        doIndent(p, indent);
        p.println("}");
    }

    // 3 kids
    private ExpNode myExp;
    private DeclListNode myDeclList;
    private StmtListNode myStmtList;
}

class CallStmtNode extends StmtNode {
    public CallStmtNode(CallExpNode call) {
        myCall = call;
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's child
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        myCall.nameAnalysis(symTab);
		return offset;
    }
    
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        myCall.typeCheck();
    }
    
    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        myCall.unparse(p, indent);
        p.println(";");
    }

	public void codeGen(String fnName) {
		Codegen.generateWithComment("", "CALL");
		myCall.codeGen();
		Codegen.generateWithComment("", "POP RETURN VALUE");
		Codegen.genPop(Codegen.T0);
	}

    // 1 kid
    private CallExpNode myCall;
}

class ReturnStmtNode extends StmtNode {
    public ReturnStmtNode(ExpNode exp) {
        myExp = exp;
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's child,
     * if it has one
     */
    public int nameAnalysis(SymTable symTab, int offset) {
        if (myExp != null) {
            myExp.nameAnalysis(symTab);
        }
		return offset;
    }

	public void codeGen(String fnName) {
		if (myExp != null) {
			myExp.codeGen();
			Codegen.generateWithComment("", "STORE RETURN VALUE IN V0");
			Codegen.genPop(Codegen.V0);
		}
		Codegen.generateWithComment("", "RETURN");
		Codegen.generateWithComment("la", "get exit address", Codegen.T0, "_"+fnName+"_Exit");
		Codegen.generateWithComment("jr", "", Codegen.T0);
	}
    /**
     * typeCheck
     */
    public void typeCheck(Type retType) {
        if (myExp != null) {  // return value given
            Type type = myExp.typeCheck();
            
            if (retType.isVoidType()) {
                ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                             "Return with a value in a void function");                
            }
            
            else if (!retType.isErrorType() && !type.isErrorType() && !retType.equals(type)){
                ErrMsg.fatal(myExp.lineNum(), myExp.charNum(),
                             "Bad return value");
            }
        }
        
        else {  // no return value given -- ok if this is a void function
            if (!retType.isVoidType()) {
                ErrMsg.fatal(0, 0, "Missing return value");                
            }
        }
        
    }
    
    public void unparse(PrintWriter p, int indent) {
        doIndent(p, indent);
        p.print("return");
        if (myExp != null) {
            p.print(" ");
            myExp.unparse(p, 0);
        }
        p.println(";");
    }

    // 1 kid
    private ExpNode myExp; // possibly null
}

// **********************************************************************
// ExpNode and its subclasses
// **********************************************************************

abstract class ExpNode extends ASTnode {
    /**
     * Default version for nodes with no names
     */
    public void nameAnalysis(SymTable symTab) { }
    
    abstract public Type typeCheck();
    abstract public int lineNum();
    abstract public int charNum();
	abstract public void codeGen();
}

class IntLitNode extends ExpNode {
    public IntLitNode(int lineNum, int charNum, int intVal) {
        myLineNum = lineNum;
        myCharNum = charNum;
        myIntVal = intVal;
    }
    
    /**
     * Return the line number for this literal.
     */
    public int lineNum() {
        return myLineNum;
    }
    
    /**
     * Return the char number for this literal.
     */
    public int charNum() {
        return myCharNum;
    }
        
    /**
     * typeCheck
     */
    public Type typeCheck() {
        return new IntType();
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print(myIntVal);
    }

	public void codeGen() {
		Codegen.generateWithComment("", "INTEGER LITERAL");
		Codegen.generateWithComment("ll", "", Codegen.T0, Integer.toString(myIntVal % 256));
		if (myIntVal > 256) {
			Codegen.generateWithComment("lh", "", Codegen.T0, Integer.toString(myIntVal / 256));
		}
		Codegen.genPush(Codegen.T0);
	}

    private int myLineNum;
    private int myCharNum;
    private int myIntVal;
}

class StringLitNode extends ExpNode {
    public StringLitNode(int lineNum, int charNum, String strVal) {
        myLineNum = lineNum;
        myCharNum = charNum;
        myStrVal = strVal;
    }
    
    /**
     * Return the line number for this literal.
     */
    public int lineNum() {
        return myLineNum;
    }
    
    /**
     * Return the char number for this literal.
     */
    public int charNum() {
        return myCharNum;
    }
    
    /**
     * typeCheck
     */
    public Type typeCheck() {
        return new StringType();
    }
        
    public void unparse(PrintWriter p, int indent) {
        p.print(myStrVal);
    }

	public void codeGen() {
		String label = Codegen.strLiteral.get(myStrVal);
		if (label == null ) {
			label = Codegen.nextLabel();
			Codegen.strLiteral.put(myStrVal, label);
			Codegen.strLabel.add(label);
			Codegen.generateWithComment("la", "Get String address", Codegen.T5, label);
			Codegen.generateWithComment("ll", "", Codegen.T4, "0x01");
			int i =0, counter = 0;;
			while (i < myStrVal.length()) {
				if (myStrVal.charAt(i) == '\\') {
					Codegen.generateWithComment("ll", "", Codegen.T3, "'"+myStrVal.charAt(i)+myStrVal.charAt(i+1)+"'");
					i++;
				}
				else {
					Codegen.generateWithComment("ll", "", Codegen.T3, "'"+myStrVal.charAt(i)+"'");
				}
				i++;
				counter ++;
				Codegen.generateWithComment("sw", "", Codegen.T3, Codegen.T5);
				Codegen.generateWithComment("add", "", Codegen.T5, Codegen.T5, Codegen.T4);
			}
			Codegen.labelSize.put(label, counter);
		}
		Codegen.generate("la", Codegen.T0, label);
		Codegen.genPush(Codegen.T0);
	}


    private int myLineNum;
    private int myCharNum;
    private String myStrVal;
}

class TrueNode extends ExpNode {
    public TrueNode(int lineNum, int charNum) {
        myLineNum = lineNum;
        myCharNum = charNum;
    }

    /**
     * Return the line number for this literal.
     */
    public int lineNum() {
        return myLineNum;
    }
    
    /**
     * Return the char number for this literal.
     */
    public int charNum() {
        return myCharNum;
    }
    
    /**
     * typeCheck
     */
    public Type typeCheck() {
        return new BoolType();
    }
        
    public void unparse(PrintWriter p, int indent) {
        p.print("true");
    }

	public void codeGen() {
		Codegen.generateWithComment("", "TRUE");
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x01");
		Codegen.genPush(Codegen.T0);
	}

    private int myLineNum;
    private int myCharNum;
}

class FalseNode extends ExpNode {
    public FalseNode(int lineNum, int charNum) {
        myLineNum = lineNum;
        myCharNum = charNum;
    }

    /**
     * Return the line number for this literal.
     */
    public int lineNum() {
        return myLineNum;
    }
    
    /**
     * Return the char number for this literal.
     */
    public int charNum() {
        return myCharNum;
    }

    /**
     * typeCheck
     */
    public Type typeCheck() {
        return new BoolType();
    }
        
	public void codeGen() {
		Codegen.generateWithComment("", "FALSE");
		Codegen.genPush("R0");
	}

    public void unparse(PrintWriter p, int indent) {
        p.print("false");
    }

    private int myLineNum;
    private int myCharNum;
}

class IdNode extends ExpNode {
    public IdNode(int lineNum, int charNum, String strVal) {
        myLineNum = lineNum;
        myCharNum = charNum;
        myStrVal = strVal;
    }

    /**
     * Link the given symbol to this ID.
     */
    public void link(SemSym sym) {
        mySym = sym;
    }
    
    /**
     * Return the name of this ID.
     */
    public String name() {
        return myStrVal;
    }
    
    /**
     * Return the symbol associated with this ID.
     */
    public SemSym sym() {
        return mySym;
    }
    
    /**
     * Return the line number for this ID.
     */
    public int lineNum() {
        return myLineNum;
    }
    
    /**
     * Return the char number for this ID.
     */
    public int charNum() {
        return myCharNum;
    }    
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * - check for use of undeclared name
     * - if ok, link to symbol table entry
     */
    public void nameAnalysis(SymTable symTab) {
        SemSym sym = symTab.lookupGlobal(myStrVal);
        if (sym == null) {
            ErrMsg.fatal(myLineNum, myCharNum, "Undeclared identifier");
        } else {
            link(sym);
        }
    }
 
    /**
     * typeCheck
     */
    public Type typeCheck() {
        if (mySym != null) {
            return mySym.getType();
        } 
        else {
            System.err.println("ID with null sym field in IdNode.typeCheck");
            System.exit(-1);
        }
        return null;
    }
    
	public void codeGen() {
		if (mySym.getLevel() == 0) { // global variable
			Codegen.generateWithComment("", "LOAD GLOBAL VARIABLE");
			Codegen.generateWithComment("la", "Get Address", Codegen.T0, "_"+myStrVal);
			Codegen.generateWithComment("ld", "load value", Codegen.T0, Codegen.T0);
			Codegen.genPush(Codegen.T0);
		}
		else { // local variable
			Codegen.generateWithComment("", "LOAD LOCAL VARIABLE");
			Codegen.generateWithComment("ll", "", Codegen.T0, Integer.toString(-mySym.getOffset()%256));
			if (-mySym.getOffset() > 256) {
				Codegen.generateWithComment("lh", "", Codegen.T0, Integer.toString(-mySym.getOffset()/256));
			}
			Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.FP, Codegen.T0);
			Codegen.generateWithComment("ld", "", Codegen.T0, Codegen.T0);
			Codegen.genPush(Codegen.T0);
		}
	}

	public void genAddr() {
		if (mySym.getLevel() == 0) { //global variable
			Codegen.generateWithComment("", "GET ADDRESS FOR GLOBAL VARIABLE");
			Codegen.generateWithComment("la", "", Codegen.T0, "_"+myStrVal);
			Codegen.genPush(Codegen.T0);
		}
		else { // local variable
			Codegen.generateWithComment("", "GET ADDRESS FOR LOCAL VARIABLE");
			Codegen.generateWithComment("ll","Get offset", Codegen.T0,Integer.toString(-mySym.getOffset()%256));
			if ( -mySym.getOffset() > 256) {
				Codegen.generateWithComment("lh","Get offset", Codegen.T0,Integer.toString(-mySym.getOffset()/256));
			}
			Codegen.generateWithComment("sub","Calculate address",  Codegen.T0, Codegen.FP, Codegen.T0);
			Codegen.genPush(Codegen.T0);
		}
	}

    public void unparse(PrintWriter p, int indent) {
        p.print(myStrVal);
        if (mySym != null) {
            p.print("(" + mySym + ")");
        }
    }

    private int myLineNum;
    private int myCharNum;
    private String myStrVal;
    private SemSym mySym;
}

class DotAccessExpNode extends ExpNode {
    public DotAccessExpNode(ExpNode loc, IdNode id) {
        myLoc = loc;    
        myId = id;
        mySym = null;
    }

    /**
     * Return the symbol associated with this dot-access node.
     */
    public SemSym sym() {
        return mySym;
    }    
    
    /**
     * Return the line number for this dot-access node. 
     * The line number is the one corresponding to the RHS of the dot-access.
     */
    public int lineNum() {
        return myId.lineNum();
    }
    
    /**
     * Return the char number for this dot-access node.
     * The char number is the one corresponding to the RHS of the dot-access.
     */
    public int charNum() {
        return myId.charNum();
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, do:
     * - process the LHS of the dot-access
     * - process the RHS of the dot-access
     * - if the RHS is of a struct type, set the sym for this node so that
     *   a dot-access "higher up" in the AST can get access to the symbol
     *   table for the appropriate struct definition
     */
    public void nameAnalysis(SymTable symTab) {
        badAccess = false;
        SymTable structSymTab = null; // to lookup RHS of dot-access
        SemSym sym = null;
        
        myLoc.nameAnalysis(symTab);  // do name analysis on LHS
        
        // if myLoc is really an ID, then sym will be a link to the ID's symbol
        if (myLoc instanceof IdNode) {
            IdNode id = (IdNode)myLoc;
            sym = id.sym();
            
            // check ID has been declared to be of a struct type
            
            if (sym == null) { // ID was undeclared
                badAccess = true;
            }
            else if (sym instanceof StructSym) { 
                // get symbol table for struct type
                SemSym tempSym = ((StructSym)sym).getStructType().sym();
                structSymTab = ((StructDefSym)tempSym).getSymTable();
            } 
            else {  // LHS is not a struct type
                ErrMsg.fatal(id.lineNum(), id.charNum(), 
                             "Dot-access of non-struct type");
                badAccess = true;
            }
        }
        
        // if myLoc is really a dot-access (i.e., myLoc was of the form
        // LHSloc.RHSid), then sym will either be
        // null - indicating RHSid is not of a struct type, or
        // a link to the Sym for the struct type RHSid was declared to be
        else if (myLoc instanceof DotAccessExpNode) {
            DotAccessExpNode loc = (DotAccessExpNode)myLoc;
            
            if (loc.badAccess) {  // if errors in processing myLoc
                badAccess = true; // don't continue proccessing this dot-access
            }
            else { //  no errors in processing myLoc
                sym = loc.sym();

                if (sym == null) {  // no struct in which to look up RHS
                    ErrMsg.fatal(loc.lineNum(), loc.charNum(), 
                                 "Dot-access of non-struct type");
                    badAccess = true;
                }
                else {  // get the struct's symbol table in which to lookup RHS
                    if (sym instanceof StructDefSym) {
                        structSymTab = ((StructDefSym)sym).getSymTable();
                    }
                    else {
                        System.err.println("Unexpected Sym type in DotAccessExpNode");
                        System.exit(-1);
                    }
                }
            }

        }
        
        else { // don't know what kind of thing myLoc is
            System.err.println("Unexpected node type in LHS of dot-access");
            System.exit(-1);
        }
        
        // do name analysis on RHS of dot-access in the struct's symbol table
        if (!badAccess) {
        
            sym = structSymTab.lookupGlobal(myId.name()); // lookup
            if (sym == null) { // not found - RHS is not a valid field name
                ErrMsg.fatal(myId.lineNum(), myId.charNum(), 
                             "Invalid struct field name");
                badAccess = true;
            }
            
            else {
                myId.link(sym);  // link the symbol
                // if RHS is itself as struct type, link the symbol for its struct 
                // type to this dot-access node (to allow chained dot-access)
                if (sym instanceof StructSym) {
                    mySym = ((StructSym)sym).getStructType().sym();
                }
            }
        }
    }    
 
    /**
     * typeCheck
     */
    public Type typeCheck() {
        return myId.typeCheck();
    }
    
    public void unparse(PrintWriter p, int indent) {
        myLoc.unparse(p, 0);
        p.print(".");
        myId.unparse(p, 0);
    }

	public void codeGen() {
		if (myLoc instanceof IdNode) {
			((IdNode)myLoc).genAddr();
		}
		else if (myLoc instanceof DotAccessExpNode) {
			((DotAccessExpNode)myLoc).genAddr();
		}
		else {
			System.err.println("error");
			System.exit(-1);
		}

		Codegen.generateWithComment("", "LOAD STRUCT VARIABLE");
		Codegen.genPop(Codegen.T0); // get left address
		Codegen.generateWithComment("ll", "", Codegen.T1, Integer.toString(-myId.sym().getOffset() %256));
		if ( -myId.sym().getOffset() > 256) {
			Codegen.generateWithComment("lh", "", Codegen.T1, Integer.toString(-myId.sym().getOffset() /256));
		}
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.generateWithComment("ld", "", Codegen.T1, Codegen.T0);
		Codegen.genPush(Codegen.T1);
	}

	public void genAddr() {
		if (myLoc instanceof IdNode) {
			((IdNode)myLoc).genAddr();
		}
		else if (myLoc instanceof DotAccessExpNode) {
			((DotAccessExpNode)myLoc).genAddr();
		}
		else {
			System.err.println("error");
			System.exit(-1);
		}

		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("ll", "", Codegen.T1, Integer.toString(-myId.sym().getOffset() % 256)); 
		if ( -myId.sym().getOffset() > 256) {
			Codegen.generateWithComment("lh", "", Codegen.T1, Integer.toString(-myId.sym().getOffset() / 256)); 
		}
		Codegen.generateWithComment("sub","", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.genPush(Codegen.T0);
	}

    // 2 kids
    private ExpNode myLoc;    
    private IdNode myId;
    private SemSym mySym;          // link to Sym for struct type
    private boolean badAccess;  // to prevent multiple, cascading errors
}

class AssignNode extends ExpNode {
    public AssignNode(ExpNode lhs, ExpNode exp) {
        myLhs = lhs;
        myExp = exp;
    }
    
    /**
     * Return the line number for this assignment node. 
     * The line number is the one corresponding to the left operand.
     */
    public int lineNum() {
        return myLhs.lineNum();
    }
    
    /**
     * Return the char number for this assignment node.
     * The char number is the one corresponding to the left operand.
     */
    public int charNum() {
        return myLhs.charNum();
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's 
     * two children
     */
    public void nameAnalysis(SymTable symTab) {
        myLhs.nameAnalysis(symTab);
        myExp.nameAnalysis(symTab);
    }
 
    /**
     * typeCheck
     */
    public Type typeCheck() {
        Type typeLhs = myLhs.typeCheck();
        Type typeExp = myExp.typeCheck();
        Type retType = typeLhs;
        
        if (typeLhs.isFnType() && typeExp.isFnType()) {
            ErrMsg.fatal(lineNum(), charNum(), "Function assignment");
            retType = new ErrorType();
        }
        
        if (typeLhs.isStructDefType() && typeExp.isStructDefType()) {
            ErrMsg.fatal(lineNum(), charNum(), "Struct name assignment");
            retType = new ErrorType();
        }
        
        if (typeLhs.isStructType() && typeExp.isStructType()) {
            ErrMsg.fatal(lineNum(), charNum(), "Struct variable assignment");
            retType = new ErrorType();
        }        
        
        if (!typeLhs.equals(typeExp) && !typeLhs.isErrorType() && !typeExp.isErrorType()) {
            ErrMsg.fatal(lineNum(), charNum(), "Type mismatch");
            retType = new ErrorType();
        }
        
        if (typeLhs.isErrorType() || typeExp.isErrorType()) {
            retType = new ErrorType();
        }
        
        return retType;
    }
    
	public void codeGen() {
		myExp.codeGen();
		if (myLhs instanceof IdNode) {
			((IdNode)myLhs).genAddr();
		}
		else if (myLhs instanceof DotAccessExpNode) {
			((DotAccessExpNode)myLhs).genAddr();
		}
		else {
			System.err.println("error");
			System.exit(-1);
		}
		Codegen.genPop(Codegen.T0);
		Codegen.genPop(Codegen.T1);
		Codegen.generateWithComment("", "ASSIGN");
		Codegen.generateWithComment("sw", "", Codegen.T1, Codegen.T0);
		Codegen.genPush(Codegen.T1);
	}

    public void unparse(PrintWriter p, int indent) {
        if (indent != -1)  p.print("(");
        myLhs.unparse(p, 0);
        p.print(" = ");
        myExp.unparse(p, 0);
        if (indent != -1)  p.print(")");
    }

    // 2 kids
    private ExpNode myLhs;
    private ExpNode myExp;
}

class CallExpNode extends ExpNode {
    public CallExpNode(IdNode name, ExpListNode elist) {
        myId = name;
        myExpList = elist;
    }

    public CallExpNode(IdNode name) {
        myId = name;
        myExpList = new ExpListNode(new LinkedList<ExpNode>());
    }

    /**
     * Return the line number for this call node. 
     * The line number is the one corresponding to the function name.
     */
    public int lineNum() {
        return myId.lineNum();
    }
    
    /**
     * Return the char number for this call node.
     * The char number is the one corresponding to the function name.
     */
    public int charNum() {
        return myId.charNum();
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's 
     * two children
     */
    public void nameAnalysis(SymTable symTab) {
        myId.nameAnalysis(symTab);
        myExpList.nameAnalysis(symTab);
    }  
      
    /**
     * typeCheck
     */
    public Type typeCheck() {
        if (!myId.typeCheck().isFnType()) {  
            ErrMsg.fatal(myId.lineNum(), myId.charNum(), 
                         "Attempt to call a non-function");
            return new ErrorType();
        }
        
        FnSym fnSym = (FnSym)(myId.sym());
        
        if (fnSym == null) {
            System.err.println("null sym for Id in CallExpNode.typeCheck");
            System.exit(-1);
        }
        
        if (myExpList.size() != fnSym.getNumParams()) {
            ErrMsg.fatal(myId.lineNum(), myId.charNum(), 
                         "Function call with wrong number of args");
            return fnSym.getReturnType();
        }
        
        myExpList.typeCheck(fnSym.getParamTypes());
        return fnSym.getReturnType();
    }
        
	public void codeGen() {
		// push parameter on stack
		myExpList.codeGen();
		// jump and link
		if (myId.name().equals("main")) {
			Codegen.generateWithComment("jl","", "main");
		}
		else {
			Codegen.generateWithComment("jl","", "_"+myId.name());
		}
		Codegen.generateWithComment("", "PUSH RETURN VALUE ON STACK");
		Codegen.genPush(Codegen.V0);
	}

    // ** unparse **
    public void unparse(PrintWriter p, int indent) {
        myId.unparse(p, 0);
        p.print("(");
        if (myExpList != null) {
            myExpList.unparse(p, 0);
        }
        p.print(")");
    }

    // 2 kids
    private IdNode myId;
    private ExpListNode myExpList;  // possibly null
}

abstract class UnaryExpNode extends ExpNode {
    public UnaryExpNode(ExpNode exp) {
        myExp = exp;
    }
    
    /**
     * Return the line number for this unary expression node. 
     * The line number is the one corresponding to the  operand.
     */
    public int lineNum() {
        return myExp.lineNum();
    }
    
    /**
     * Return the char number for this unary expression node.
     * The char number is the one corresponding to the  operand.
     */
    public int charNum() {
        return myExp.charNum();
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's child
     */
    public void nameAnalysis(SymTable symTab) {
        myExp.nameAnalysis(symTab);
    }
    
    // one child
    protected ExpNode myExp;
}

abstract class BinaryExpNode extends ExpNode {
    public BinaryExpNode(ExpNode exp1, ExpNode exp2) {
        myExp1 = exp1;
        myExp2 = exp2;
    }
    
    /**
     * Return the line number for this binary expression node. 
     * The line number is the one corresponding to the left operand.
     */
    public int lineNum() {
        return myExp1.lineNum();
    }
    
    /**
     * Return the char number for this binary expression node.
     * The char number is the one corresponding to the left operand.
     */
    public int charNum() {
        return myExp1.charNum();
    }
    
    /**
     * nameAnalysis
     * Given a symbol table symTab, perform name analysis on this node's 
     * two children
     */
    public void nameAnalysis(SymTable symTab) {
        myExp1.nameAnalysis(symTab);
        myExp2.nameAnalysis(symTab);
    }
    
    // two kids
    protected ExpNode myExp1;
    protected ExpNode myExp2;
}

// **********************************************************************
// Subclasses of UnaryExpNode
// **********************************************************************

class UnaryMinusNode extends UnaryExpNode {
    public UnaryMinusNode(ExpNode exp) {
        super(exp);
    }

    /**
     * typeCheck
     */
    public Type typeCheck() {
        Type type = myExp.typeCheck();
        Type retType = new IntType();
        
        if (!type.isErrorType() && !type.isIntType()) {
            ErrMsg.fatal(lineNum(), charNum(),
                         "Arithmetic operator applied to non-numeric operand");
            retType = new ErrorType();
        }
        
        if (type.isErrorType()) {
            retType = new ErrorType();
        }
        
        return retType;
    }

	public void codeGen() {
		myExp.codeGen();
		Codegen.generateWithComment("", "UNARY MINUS");
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("sub", "", Codegen.T0, "R0", Codegen.T0);
		Codegen.genPush(Codegen.T0);
	}


    public void unparse(PrintWriter p, int indent) {
        p.print("(-");
        myExp.unparse(p, 0);
        p.print(")");
    }
}

class NotNode extends UnaryExpNode {
    public NotNode(ExpNode exp) {
        super(exp);
    }

    /**
     * typeCheck
     */
    public Type typeCheck() {
        Type type = myExp.typeCheck();
        Type retType = new BoolType();
        
        if (!type.isErrorType() && !type.isBoolType()) {
            ErrMsg.fatal(lineNum(), charNum(),
                         "Logical operator applied to non-bool operand");
            retType = new ErrorType();
        }
        
        if (type.isErrorType()) {
            retType = new ErrorType();
        }
        
        return retType;
    }

	public void codeGen() {
		myExp.codeGen();
		Codegen.generateWithComment("", "NOT");
		Codegen.generateWithComment("ll", "", Codegen.T1, "1");
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T1, Codegen.T0);
		Codegen.genPush(Codegen.T0);
	}

    public void unparse(PrintWriter p, int indent) {
        p.print("(!");
        myExp.unparse(p, 0);
        p.print(")");
    }
}

// **********************************************************************
// Subclasses of BinaryExpNode
// **********************************************************************

abstract class ArithmeticExpNode extends BinaryExpNode {
    public ArithmeticExpNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    /**
     * typeCheck
     */
    public Type typeCheck() {
        Type type1 = myExp1.typeCheck();
        Type type2 = myExp2.typeCheck();
        Type retType = new IntType();
        
        if (!type1.isErrorType() && !type1.isIntType()) {
            ErrMsg.fatal(myExp1.lineNum(), myExp1.charNum(),
                         "Arithmetic operator applied to non-numeric operand");
            retType = new ErrorType();
        }
        
        if (!type2.isErrorType() && !type2.isIntType()) {
            ErrMsg.fatal(myExp2.lineNum(), myExp2.charNum(),
                         "Arithmetic operator applied to non-numeric operand");
            retType = new ErrorType();
        }
        
        if (type1.isErrorType() || type2.isErrorType()) {
            retType = new ErrorType();
        }
        
        return retType;
    }
}

abstract class LogicalExpNode extends BinaryExpNode {
    public LogicalExpNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    /**
     * typeCheck
     */
    public Type typeCheck() {
        Type type1 = myExp1.typeCheck();
        Type type2 = myExp2.typeCheck();
        Type retType = new BoolType();
        
        if (!type1.isErrorType() && !type1.isBoolType()) {
            ErrMsg.fatal(myExp1.lineNum(), myExp1.charNum(),
                         "Logical operator applied to non-bool operand");
            retType = new ErrorType();
        }
        
        if (!type2.isErrorType() && !type2.isBoolType()) {
            ErrMsg.fatal(myExp2.lineNum(), myExp2.charNum(),
                         "Logical operator applied to non-bool operand");
            retType = new ErrorType();
        }
        
        if (type1.isErrorType() || type2.isErrorType()) {
            retType = new ErrorType();
        }
        
        return retType;
    }
}

abstract class EqualityExpNode extends BinaryExpNode {
    public EqualityExpNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    /**
     * typeCheck
     */
    public Type typeCheck() {
        Type type1 = myExp1.typeCheck();
        Type type2 = myExp2.typeCheck();
        Type retType = new BoolType();
        
        if (type1.isVoidType() && type2.isVoidType()) {
            ErrMsg.fatal(lineNum(), charNum(),
                         "Equality operator applied to void functions");
            retType = new ErrorType();
        }
        
        if (type1.isFnType() && type2.isFnType()) {
            ErrMsg.fatal(lineNum(), charNum(),
                         "Equality operator applied to functions");
            retType = new ErrorType();
        }
        
        if (type1.isStructDefType() && type2.isStructDefType()) {
            ErrMsg.fatal(lineNum(), charNum(),
                         "Equality operator applied to struct names");
            retType = new ErrorType();
        }
        
        if (type1.isStructType() && type2.isStructType()) {
            ErrMsg.fatal(lineNum(), charNum(),
                         "Equality operator applied to struct variables");
            retType = new ErrorType();
        }        
        
        if (!type1.equals(type2) && !type1.isErrorType() && !type2.isErrorType()) {
            ErrMsg.fatal(lineNum(), charNum(),
                         "Type mismatch");
            retType = new ErrorType();
        }
        
        if (type1.isErrorType() || type2.isErrorType()) {
            retType = new ErrorType();
        }
        
        return retType;
    }
}

abstract class RelationalExpNode extends BinaryExpNode {
    public RelationalExpNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    /**
     * typeCheck
     */
    public Type typeCheck() {
        Type type1 = myExp1.typeCheck();
        Type type2 = myExp2.typeCheck();
        Type retType = new BoolType();
        
        if (!type1.isErrorType() && !type1.isIntType()) {
            ErrMsg.fatal(myExp1.lineNum(), myExp1.charNum(),
                         "Relational operator applied to non-numeric operand");
            retType = new ErrorType();
        }
        
        if (!type2.isErrorType() && !type2.isIntType()) {
            ErrMsg.fatal(myExp2.lineNum(), myExp2.charNum(),
                         "Relational operator applied to non-numeric operand");
            retType = new ErrorType();
        }
        
        if (type1.isErrorType() || type2.isErrorType()) {
            retType = new ErrorType();
        }
        
        return retType;
    }
}

class PlusNode extends ArithmeticExpNode {
    public PlusNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" + ");
        myExp2.unparse(p, 0);
        p.print(")");
    }

	public void codeGen() {
		myExp1.codeGen();
		myExp2.codeGen();
		Codegen.generateWithComment("","PLUS");
		Codegen.genPop(Codegen.T0);
		Codegen.genPop(Codegen.T1);
		Codegen.generateWithComment("add", "", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.genPush(Codegen.T0);
	}
}

class MinusNode extends ArithmeticExpNode {
    public MinusNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" - ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	public void codeGen() {
		myExp1.codeGen();
		myExp2.codeGen();
		Codegen.generateWithComment("","MINUS");
		Codegen.genPop(Codegen.T0);
		Codegen.genPop(Codegen.T1);
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T1, Codegen.T0);
		Codegen.genPush(Codegen.T0);
	}
}

class TimesNode extends ArithmeticExpNode {
    public TimesNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }

    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" * ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	public void codeGen() {
	}
}

class DivideNode extends ArithmeticExpNode {
    public DivideNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" / ");
        myExp2.unparse(p, 0);
        p.print(")");
    }

	public void codeGen() {
	}
}

class AndNode extends LogicalExpNode {
    public AndNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" && ");
        myExp2.unparse(p, 0);
        p.print(")");
    }

	public void codeGen() {
		String label = Codegen.nextLabel();
		myExp1.codeGen();
		// Test if the result is true
		Codegen.generateWithComment("", "AND");
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("sub","", Codegen.T0, "R0", Codegen.T0);
		Codegen.generateWithComment("b", "", "eq", label);
		Codegen.generateWithComment("", "LEFT_HAND IS TRUE");
		myExp2.codeGen();
		Codegen.genPop(Codegen.T0);
		Codegen.genLabel(label);
		Codegen.genPush(Codegen.T0);
	}
}

class OrNode extends LogicalExpNode {
    public OrNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" || ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	public void codeGen() {
		String trueLab = Codegen.nextLabel();
		// Test of Left label is true
		myExp1.codeGen();
		Codegen.generateWithComment("", "OR");
		Codegen.genPop(Codegen.T0);
		Codegen.generateWithComment("sub", "", Codegen.T0, "R0", Codegen.T0);
		Codegen.generateWithComment("b", "", "neq", trueLab);
		Codegen.generateWithComment("", "LEFT_HAND IS FALSE");
		myExp2.codeGen();
		Codegen.genPop(Codegen.T0);
		Codegen.genLabel(trueLab);
		Codegen.genPush(Codegen.T0);
	}
}

class EqualsNode extends EqualityExpNode {
    public EqualsNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" == ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	public void codeGen() {
		myExp1.codeGen();
		myExp2.codeGen();
		Codegen.generateWithComment("","EQUAL");
		Codegen.genPop(Codegen.T1);
		Codegen.genPop(Codegen.T0);
		String label = Codegen.nextLabel();
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.generateWithComment("b", "", "eq", label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x00");
		String finallabel = Codegen.nextLabel();
		Codegen.generateWithComment("b", "","uncond", finallabel);
		Codegen.genLabel(label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x01");
		Codegen.genLabel(finallabel);
		Codegen.genPush(Codegen.T0);
	}
}

class NotEqualsNode extends EqualityExpNode {
    public NotEqualsNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" != ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	public void codeGen() {
		myExp1.codeGen();
		myExp2.codeGen();
		Codegen.generateWithComment("","NOT EQUAL");
		Codegen.genPop(Codegen.T1);
		Codegen.genPop(Codegen.T0);
		String label = Codegen.nextLabel();
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.generateWithComment("b", "", "neq", label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x00");
		String finallabel = Codegen.nextLabel();
		Codegen.generateWithComment("b","", "uncond", finallabel);
		Codegen.genLabel(label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x01");
		Codegen.genLabel(finallabel);
		Codegen.genPush(Codegen.T0);
	}
}

class LessNode extends RelationalExpNode {
    public LessNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }
    
    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" < ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	
	public void codeGen() {
		myExp1.codeGen();
		myExp2.codeGen();
		Codegen.generateWithComment("","LESS");
		Codegen.genPop(Codegen.T1);
		Codegen.genPop(Codegen.T0);
		String label = Codegen.nextLabel();
		Codegen.generateWithComment("sub","", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.generateWithComment("b","", "lt", label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x00");
		String finallabel = Codegen.nextLabel();
		Codegen.generateWithComment("b","", "uncond", finallabel);
		Codegen.genLabel(label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x01");
		Codegen.genLabel(finallabel);
		Codegen.genPush(Codegen.T0);
	}
}

class GreaterNode extends RelationalExpNode {
    public GreaterNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }

    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" > ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	public void codeGen() {
		myExp1.codeGen();
		myExp2.codeGen();
		Codegen.generateWithComment("","GREATER");
		Codegen.genPop(Codegen.T1);
		Codegen.genPop(Codegen.T0);
		String label = Codegen.nextLabel();
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.generateWithComment("b", "", "gt", label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x00");
		String finallabel = Codegen.nextLabel();
		Codegen.generateWithComment("b", "", "uncond", finallabel);
		Codegen.genLabel(label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x01");
		Codegen.genLabel(finallabel);
		Codegen.genPush(Codegen.T0);
	}
}

class LessEqNode extends RelationalExpNode {
    public LessEqNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }

    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" <= ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	public void codeGen() {
		myExp1.codeGen();
		myExp2.codeGen();
		Codegen.generateWithComment("","LESS EQ");
		Codegen.genPop(Codegen.T1);
		Codegen.genPop(Codegen.T0);
		String label = Codegen.nextLabel();
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.generateWithComment("b", "", "lte", label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x00");
		String finallabel = Codegen.nextLabel();
		Codegen.generateWithComment("b", "", "uncond", finallabel);
		Codegen.genLabel(label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x01");
		Codegen.genLabel(finallabel);
		Codegen.genPush(Codegen.T0);
	}
}

class GreaterEqNode extends RelationalExpNode {
    public GreaterEqNode(ExpNode exp1, ExpNode exp2) {
        super(exp1, exp2);
    }

    public void unparse(PrintWriter p, int indent) {
        p.print("(");
        myExp1.unparse(p, 0);
        p.print(" >= ");
        myExp2.unparse(p, 0);
        p.print(")");
    }
	public void codeGen() {
		myExp1.codeGen();
		myExp2.codeGen();
		Codegen.generateWithComment("","GREATER EQ");
		Codegen.genPop(Codegen.T1);
		Codegen.genPop(Codegen.T0);
		String label = Codegen.nextLabel();
		Codegen.generateWithComment("sub", "", Codegen.T0, Codegen.T0, Codegen.T1);
		Codegen.generateWithComment("b", "", "gte", label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x00");
		String finallabel = Codegen.nextLabel();
		Codegen.generateWithComment("b", "", "uncond", finallabel);
		Codegen.genLabel(label);
		Codegen.generateWithComment("ll", "", Codegen.T0, "0x01");
		Codegen.genLabel(finallabel);
		Codegen.genPush(Codegen.T0);
	}
}

