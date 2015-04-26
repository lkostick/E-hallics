Compiler
=====================
Type:

	1. variables and parameters -> int, bool
	2. functions                -> int, bool, void
	3. note: int range is -32767 ~ 32767

Variable:

	1. support global variable declaration
	2. support struct
	3. support array
	4. all variables should be declared before any statments
		int main() {
			int a; // good declaration
			cout << a;
			int b; // bad declaration, should before "cout << a;"
			return 0;
		}
		int main() { // correct version
			int a, b;
			cout << a;
			return 0;
		}
	5. struct declaration and struct variable should be sperated
		struct d {
			int a;
		} e; // bad
		sturct d e; //good
	6. do not support initialization in declaration
		int a = 0; // bad
	7. struct name can be same with other variable
		struct d d; // good

Function:
	
	1. Functions should be declared before using
	2. parameters can only be passed by value
	3. do not support overload
	4. cannot return if function type is void, and cannot has a plain return in other type
		void test()  {
			return 0; // bad
		}
		int test() {
			return; //bad
		}
	5. return statement is not required, then the return value is unknown
		int test() {
			cout <<"hello world" << endl;
		} // this is allowed, but the value return by test() is unknown

Statement:
	
	1. support while and for loop, format is same with c
	2. support "cout << expression;" for output
	3. support if and if-else statements. Not support elseif

Expression:
	
	1. support plus, minus, unary minus, post increase and post decrease
	2. support &&, || and ! for logical operation
	3. support <, >, <=, >=, == and != relation operation
	4. special instruction "__overflow" for detecting overflow
