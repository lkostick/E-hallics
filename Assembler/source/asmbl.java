import java.util.*;
import java.io.*;
import java_cup.runtime.*;  // defines Symbol

public class asmbl {
    public static void main(String[] args) throws IOException {

		if (args.length != 1) {
			System.err.println("Usage: java asmbl <inputFile>");
			System.exit(-1);
		}
		FileReader inFile = null;
		try {
			inFile = new FileReader(args[0]);
		} catch (FileNotFoundException ex) {
			System.err.println("File" + args[0] + " not found.");
			System.exit(-1);
		}

		parser P = new parser(new Yylex(inFile));

		Symbol root = null;

		try {
			root = P.parse();
		} catch (Exception ex) {
			System.err.println("Exception occured during parse: "+ ex);
			System.exit(-1);
		}
		((ProgramNode)root.value).FlagCheck();
		((ASTnode)root.value).translate();
		return;
    }
}
