#include <windows.h>
#include <iostream>
using namespace std;

int flag = 0;
char pc[4];
DWORD WINAPI SerialCOMMREAD(LPVOID lpParam);

int main()
{
	DWORD dwThreadID;
	HANDLE hThread;

	hThread = CreateThread(NULL, 0, SerialCOMMREAD, NULL, 0, &dwThreadID);

	while (1) // read data from cin
	{
		cin >> pc[0] >> pc[1] >> pc[2] >> pc[3];
		flag = 1;
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
	DWORD dwBytesTransferred, byteWritten;
	SetCommMask(hSerial, EV_RXCHAR | EV_CTS | EV_DSR | EV_RLSD | EV_RING);
	while (1)
	{
		if (WaitForSingleObject(hSerial, 1) == WAIT_OBJECT_0)
		{
			ReadFile(hSerial, &byte, 1, &dwBytesTransferred, 0);
			if (dwBytesTransferred == 1)
			if ((int)byte == 13)
				cout << endl;
			else cout << byte;
		}
		if (flag == 1)
		{
			flag = 0;
			for (int i = 0; i < 6; i++)
			{
				if (i == 0)
					bytes = 5;
				else if (i == 1)
					bytes = 17;
				else {
					if (pc[i - 2] <= '9' && pc[i - 2] >= '0')
						bytes = i * 16 + pc[i - 2] - '0';
					else
						switch (pc[i - 2]) {
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
							return -1;
					}
				}
				if (!WriteFile(hSerial, &bytes, 1, &byteWritten, 0))
				{
					cerr << "Error in sending data" << endl;
					CloseHandle(hSerial);
					return -1;
				}
			}
			cout << "Set PC to 0x" << pc[0] << pc[1] << pc[2] << pc[3] << endl;
		}	
	}
	return 0;
}