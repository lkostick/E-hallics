###
# This Makefile can be used to make a parser for the C-- language
# (parser.class) and to make a program (P4.class) that tests the parser and
# the unparse methods in ast.java.
#
# make clean removes all generated files.
#
###

JC = javac

Compiler.class: Compiler.java parser.class Yylex.class ASTnode.class Codegen.class
	$(JC) -g Compiler.java

parser.class: parser.java ASTnode.class Yylex.class ErrMsg.class
	$(JC) parser.java

parser.java: CMM.cup
	java java_cup.Main < CMM.cup

Yylex.class: CMM.jlex.java sym.class ErrMsg.class
	$(JC) -g CMM.jlex.java

ASTnode.class: ast.java Type.java
	$(JC) -g ast.java

CMM.jlex.java: CMM.jlex sym.class
	java JLex.Main CMM.jlex

sym.class: sym.java
	$(JC) -g sym.java

sym.java: CMM.cup
	java java_cup.Main < CMM.cup

ErrMsg.class: ErrMsg.java
	$(JC) ErrMsg.java

Sym.class: Sym.java Type.java ast.java
	$(JC) -g Sym.java
	
SymTable.class: SymTable.java Sym.java DuplicateSymException.java EmptySymTableException.java
	$(JC) -g SymTable.java
	
Type.class: Type.java
	$(JC) -g Type.java

DuplicateSymException.class: DuplicateSymException.java
	$(JC) -g DuplicateSymException.java
	
EmptySymTableException.class: EmptySymTableException.java
	$(JC) -g EmptySymTableException.java

Codegen.class: Codegen.java
	$(JC) -g Codegen.java

###
# test
###
test: demo.cf P5.class
	java P5 demo.cf demo.s
	spim -f demo.s > output
	echo Loaded: /u/c/s/cs536-1/public/tools//spim/exceptions.s> correct
	echo TEST FINISHED>> correct
	diff output correct
	rm -f output correct
###
# clean
###
clean:
	rm -f *~ *.class parser.java CSX.jlex.java sym.java
