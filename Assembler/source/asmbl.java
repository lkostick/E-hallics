import java.util.*;
import java.io.*;
import java_cup.runtime.*;  // defines Symbol

public class asmbl {
    public static void main(String[] args) throws IOException {

		FileReader inFile = null;
		String flag = "0";
		String filename = "";
		if (args.length == 1) {
			filename = args[0];
		}
		else if (args.length == 2) {
			flag = args[0];
			filename = args[1];
			try {
				Integer.valueOf(flag, 10);
			} catch (NumberFormatException ex) {
				System.err.println("<code_length> should be decimal number");
				System.exit(-1);
			}
		}
		else {
			System.err.println("Usage: java asmbl.jar <code_length> <inputFile>");
			System.err.println("Or     java asmbl.jar <inputFile>");
			System.exit(-1);
		}

		try {
			inFile = new FileReader(filename);
		} catch (FileNotFoundException ex) {
			System.err.println("File" + filename + " not found.");
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
		((ProgramNode)root.value).translate(flag);
		return;
    }
}
