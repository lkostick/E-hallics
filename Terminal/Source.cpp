#include <windows.h>
#include <iostream>
#include <string>
using namespace std;

int flag = 0;
char pc[4];
int addr;
int data[4];
char store_data;
DWORD WINAPI SerialCOMMREAD(LPVOID lpParam);

int main()
{
	DWORD dwThreadID;
	HANDLE hThread;

	hThread = CreateThread(NULL, 0, SerialCOMMREAD, NULL, 0, &dwThreadID);
	string command;
	char filename[1024];
	int error;
	while (1) // read data from cin
	{
		cin >> command; 
		if (command.compare("set") == 0) {
			error = 0;
			for (int i = 0; i < 4; i++){
				cin >> pc[i];
				if (pc[i]<48 || (pc[i] >57 && pc[i] <'A') || (pc[i] >'F' &&pc[i] <'a') || (pc[i] >'f')) {
					cerr << "Unexpected PC" << endl;
					cin.clear();
					cin.ignore(1000, '\n');
					error = 1;
					break;
				}
			}
			flag = 1-error;
		}
		else if (command.compare("load") == 0){
			cin >> filename;
			HANDLE program = CreateFile(TEXT(filename), GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
			if (program == INVALID_HANDLE_VALUE) {
				cerr << "Can not open file: " << filename << endl;
			}
			else {
				char byte ;
				DWORD read= 1;
				addr = 0;
				while (read == 1) {
					if (flag == 0) {
						ReadFile(program, &byte, 1, &read, 0);
						if (byte != 10) {
							if (byte == '@') {
								addr = 0;
								for (int i = 0; i < 4; i++) {
									ReadFile(program, &byte, 1, &read, 0);
									addr += ((byte <= '9') ? byte - '0' : (byte < 'a') ? byte - 'A' + 10 : byte - 'a' + 10);
									if (i != 3) addr *= 16;
								}
								//cout << addr << endl;
							}
							else {
								for (int i = 0; i < 4; i++) {
									data[i] = (byte <= '9') ? byte - '0' : (byte < 'a') ? byte - 'A' + 10 : byte - 'a' + 10;
									ReadFile(program, &byte, 1, &read, 0);
								}
								flag = 2;
							}
						}
					}
					Sleep(7);
				}
				CloseHandle(program);
			}
		}
		else if (command.compare("get") == 0) {
			error = 0;
			for (int i = 0; i < 4; i++) {
				cin >> pc[i];
				if (pc[i]<48 || (pc[i] >57 && pc[i] <'A') || (pc[i] >'F' &&pc[i] <'a') || (pc[i] >'f')) {
					cerr << "Unexpected memory address" << endl;
					cin.clear();
					cin.ignore(1000, '\n');
					error = 1;
					break;
				}
			}
			if (error == 0) flag = 3;
		}
		else if (command.compare("getblock") == 0) {
			for (int i = 0; i < 200; i++) {
				while (flag != 0) Sleep(5);
				pc[3] = (i>9) ? ((i % 16 > 9) ? ('a'+i%16-10):('0'+i%16) ):('0' + i);
				pc[2] = (i/16 > 9)?((i/16-10)+'a'): ('0'+i/16);
				pc[1] = '0';
				pc[0] = '1';
				flag = 3;
			}
		}
		else if (command.compare("store") == 0) {
			error = 0;
			addr = 0;
			for (int i = 0; i < 4; i++) {
				cin >> pc[i];
				if (pc[i]<48 || (pc[i] >57 && pc[i] <'A') || (pc[i] >'F' &&pc[i] <'a') || (pc[i] >'f')) {
					cerr << "Unexpected memory address" << endl;
					cin.clear();
					cin.ignore(1000, '\n');
					error = 1;
					break;
				}
				addr += ((pc[i] <= '9') ? pc[i] - '0' : (pc[i] < 'a') ? pc[i] - 'A' + 10 : pc[i] - 'a' + 10);
				if (i != 3) addr *= 16;
			}
			if (error == 0) {
				for (int i = 0; i < 4; i++) {
					cin >> store_data;
					if (store_data<48 || (store_data >57 && store_data <'A') || (store_data >'F' && store_data <'a') || (store_data >'f')) {
						cerr << "Unexpected data" << endl;
						cin.clear();
						cin.ignore(1000, '\n');
						error = 1;
						break;
					}
					data[i] = (store_data <= '9') ? store_data - '0' : (store_data < 'a') ? store_data - 'A' + 10 : store_data - 'a' + 10;
				}
			}
			if (error == 0)
				flag = 2;
		}
		else if (command.compare("wakeup") == 0) {
			flag = 4;
		}
		else if (command.compare("loadtext") == 0){
			cin >> filename;
			addr = 0x3010;
			HANDLE program = CreateFile(TEXT(filename), GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
			if (program == INVALID_HANDLE_VALUE) {
				cerr << "Can not open file: " << filename << endl;
			}
			else {
				char byte;
				DWORD read = 1;
				for (int i = 0; i < 16; i++) {
					if (flag == 0) {
						for (int j = 0; j < 4; j++){
							ReadFile(program, &byte, 1, &read, 0);
							data[j] = (byte <= '9') ? byte - '0' : (byte < 'a') ? byte - 'A' + 10 : byte - 'a' + 10;
							flag = 2;
						}
						Sleep(7);
					}
					else i--;
				}
			}
			CloseHandle(program);
		}
		else {
			cerr << "Unknown command" << endl;
			cin.clear();
			cin.ignore(1000, '\n');
		}
	}
	WaitForSingleObject(hThread, INFINITE);
	return 0;
}
DWORD WINAPI SerialCOMMREAD(LPVOID lpParam)
{
	// Declare variables and structures
	HANDLE hSerial;
	DCB dcbSerialParams = { 0 };
	COMMTIMEOUTS timeouts = { 0 };

	// Open the highest available serial port number
	if ((hSerial = CreateFile(
		"COM1", GENERIC_READ|GENERIC_WRITE, 0, NULL,
		OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL))
		== INVALID_HANDLE_VALUE)
	{
		cerr << "Failed to open COM1" << endl;
		return -1;
	}

	// Set device parameters (38400 baud, 1 start bit,
	// 1 stop bit, no parity)
	dcbSerialParams.DCBlength = sizeof(dcbSerialParams);
	if (GetCommState(hSerial, &dcbSerialParams) == 0)
	{
		cerr << "Error getting device state\n";
		CloseHandle(hSerial);
		return -1;
	}

	dcbSerialParams.BaudRate = CBR_38400;
	dcbSerialParams.ByteSize = 8;
	dcbSerialParams.StopBits = ONESTOPBIT;
	dcbSerialParams.Parity = NOPARITY;
	if (SetCommState(hSerial, &dcbSerialParams) == 0)
	{
		cerr << "Error setting device parameters\n";
		CloseHandle(hSerial);
		return -1;
	}

	cout << endl << "## Device parameters ##" << endl;
	cout << "BaudRate 38400" << endl;
	cout << "ByteSize 8" << endl;
	cout << "One Stop Bit" << endl;
	cout << "No Parity Bit" << endl;
	cout << "#######################" << endl;

	// Set COM port timeout settings
	timeouts.ReadIntervalTimeout = 50;
	timeouts.ReadTotalTimeoutConstant = 50;
	timeouts.ReadTotalTimeoutMultiplier = 10;
	timeouts.WriteTotalTimeoutConstant = 50;
	timeouts.WriteTotalTimeoutMultiplier = 10;
	if (SetCommTimeouts(hSerial, &timeouts) == 0)
	{
		cerr << "Error setting timeouts\n";
		CloseHandle(hSerial);
		return -1;
	}

	char byte,bytes;
	int reg_flag = 1, trans, new_line = 1;
	int reg_count = 0;
	char HEX[16] ={'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};
	DWORD dwBytesTransferred, byteWritten;
	SetCommMask(hSerial, EV_RXCHAR | EV_CTS | EV_DSR | EV_RLSD | EV_RING);
	while (1)
	{
		if (WaitForSingleObject(hSerial, 1) == WAIT_OBJECT_0)
		{
			ReadFile(hSerial, &byte, 1, &dwBytesTransferred, 0);
			if (dwBytesTransferred == 1)
			{
				if (new_line) {
					cout << "> ";
					new_line = 0;
				}
				if (reg_count < 0) {
					cout << endl << "> Something is wrong, reset terminal" << endl;
					reg_flag = 1;
					reg_count = 0;
				}
				if ((int)byte == -1 && reg_count == 0) {
					if (reg_flag ==-1) reg_flag = 1;
					else reg_flag = -1;
					if (reg_flag == -1) reg_count = 2;
				}
				else if ((int)byte == -2 && reg_count == 0){
					if ( reg_flag == -2)  reg_flag = 1;
					else reg_flag = -2;
					if (reg_flag == -2) reg_count = 2;
				}
				else if(reg_flag ==1) {
					if ((int)byte == 13)
					{
						cout << endl;
						new_line = 1;
					}
					else cout << byte;
				}
				else if (reg_flag == -1)
				{
					if ((int)byte < 0)
						trans = (int)byte + 256;
					else
						trans = (int)byte;
					cout << HEX[trans / 16] << HEX[trans % 16];
					reg_count--;
				}
				else {
					if (reg_count == 2)
						trans = ((int)byte < 0) ? (int)byte + 256 : (int)byte;
					else {
						trans *= 256;
						trans += ((int)byte < 0) ? (int)byte + 256 : (int)byte;
					}
					if (trans > 32767) trans -= 65536;
					if (reg_count == 1) cout << trans;
					reg_count--;
				}
			}
		}
		if (flag == 1)
		{
			for (int i = 0; i < 6; i++)
			{
				if (i == 0) bytes = 1;
				else if (i == 5) bytes = 15 * 16;
				else if (pc[i-1] <= '9' && pc[i-1] >= '0')
					bytes = i * 16 + pc[i-1] - '0';
				else
					switch (pc[i-1]) {
					case 'a':
					case 'A': bytes = i * 16 + 10;
						break;
					case 'b':
					case 'B': bytes = i * 16 + 11;
						break;
					case 'c':
					case 'C': bytes = i * 16 + 12;
						break;
					case 'd':
					case 'D': bytes = i * 16 + 13;
						break;
					case 'e':
					case 'E': bytes = i * 16 + 14;
						break;
					case 'f':
					case 'F': bytes = i * 16 + 15;
						break;
					default: cout << "Wrong address!" << endl;
					}
				if (!WriteFile(hSerial, &bytes, 1, &byteWritten, 0))
				{
					cerr << "Error in sending data" << endl;
					CloseHandle(hSerial);
					return -1;
				}
			}
			flag = 0;
		}
		else if (flag == 2)
		{
			int hex_addr[4];
			hex_addr[0] = addr / 16 / 16 / 16;
			hex_addr[1] = addr / 16 / 16 % 16;
			hex_addr[2] = addr / 16 % 16;
			hex_addr[3] = addr % 16;
			for (int i = 0; i <10; i++)
			{
				if (i == 0) bytes = 0;
				else if (i < 5)
					bytes = i * 16 + hex_addr[i - 1];
				else if (i < 9)
					bytes = i * 16 + data[i - 5];
				else
					bytes = 16 * 15;

				if (!WriteFile(hSerial, &bytes, 1, &byteWritten, 0))
				{
					cerr << "Error in sending data" << endl;
					CloseHandle(hSerial);
					return -1;
				}
			}
			addr += 1;
			flag = 0;
		}
		else if (flag == 3) {
			for (int i = 0; i < 6; i++)
			{
				if (i == 0) bytes = 2;
				else if (i == 5) bytes = 15 * 16;
				else if (pc[i - 1] <= '9' && pc[i - 1] >= '0')
					bytes = i * 16 + pc[i - 1] - '0';
				else
					switch (pc[i - 1]) {
					case 'a':
					case 'A': bytes = i * 16 + 10;
						break;
					case 'b':
					case 'B': bytes = i * 16 + 11;
						break;
					case 'c':
					case 'C': bytes = i * 16 + 12;
						break;
					case 'd':
					case 'D': bytes = i * 16 + 13;
						break;
					case 'e':
					case 'E': bytes = i * 16 + 14;
						break;
					case 'f':
					case 'F': bytes = i * 16 + 15;
						break;
					default: cout << "Wrong address!" << endl;
				}
				if (!WriteFile(hSerial, &bytes, 1, &byteWritten, 0))
				{
					cerr << "Error in sending data" << endl;
					CloseHandle(hSerial);
					return -1;
				}
			}
			flag = 0;
		}
		else if (flag == 4) {
			for (int i = 0; i < 2; i++) {
				if (i == 0)
					bytes = 3;
				else bytes = 15 * 16;

				if (!WriteFile(hSerial, &bytes, 1, &byteWritten, 0))
				{
					cerr << "Error in sending data" << endl;
					CloseHandle(hSerial);
					return -1;
				}
			}
			flag = 0;
		}
	}
	return 0;
}
