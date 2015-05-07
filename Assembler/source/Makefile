###
# This Makefile can be used to make a scanner for the C-- language
# (Yylex.class) and to make a program that tests the scanner (P2.class).
#
# The default makes both the scanner and the test program.
#
# make clean removes all generated files.
#
# Note: P2.java will not compile unless Yylex.class exists.
#
###

# define the java compiler to be used and the flags
JC = javac
FLAGS = -g -cp $(CP)
CP = ./:../

asmbl.class: asmbl.java parse.class Yylex.class sym.class ASTnode.class
	$(JC) $(FLAGS) asmbl.java

parse.class: parser.java ASTnode.class Yylex.class
	$(JC) parser.java

parser.java: asmbl.cup
	java -cp $(CP) java_cup.Main < asmbl.cup

Yylex.class: asmbl.jlex.java sym.class
	$(JC) -cp $(CP) asmbl.jlex.java

ASTnode.class: ast.java
	$(JC) -g ast.java

asmbl.jlex.java: asmbl.jlex sym.class
	java -cp $(CP) JLex.Main asmbl.jlex

sym.class: sym.java
	$(JC)  sym.java

sym.java: asmbl.cup
	java -cp $(CP) java_cup.Main < asmbl.cip

jar: asmbl.class
	jar cvfe asmbl.jar asmbl *.class java_cup/runtime/Scanner.class java_cup/runtime/Symbol.class java_cup/runtime/lr_parser.class java_cup/runtime/SymbolFactory.class java_cup/runtime/DefaultSymbolFactory.class
	chmod +x asmbl.jar

###
# clean up
###

clean:
	rm -f *~ *.class asmbl.jlex.java parser.java sym.java asmbl.jar
