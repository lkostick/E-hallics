#include <stdio.h>
#include <fstream>
#include <iostream>
#include <string>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>


using namespace std;
typedef uint32_t WORD;
#define w	32
#define r	1
#define b 	4
#define c	1
#define t 	4
WORD S[t];
WORD P = 0xb7e15163; /* for w = 32 */
WORD Q = 0x9e3779b9; /* for w = 32 */
#define ROTL(x,y) (((x)<<(y&(w-1))) | ((x)>>(w-(y&(w-1)))))
#define ROTR(x,y) (((x)>>(y&(w-1))) | ((x)<<(w-(y&(w-1)))))

void printword(WORD);

void encrypt(WORD *pt, WORD *ct){
	WORD i, A, B;
	A = pt[0] + S[0];
	B = pt[1] + S[1];
	for(i=1; i<=r; i++){
		A = ROTL(A^B, B) + S[2*i];
		B = ROTL(B^A, A) + S[2*i+1];
	}
	ct[0] = A; ct[1] = B;
}

void decrypt(WORD *ct, WORD *pt){
	WORD i, A, B;
	A = ct[0];
	B = ct[1];
	for(i=r; i>0; i--){
		B = ROTR(B-S[2*i+1],A)^A;
		A = ROTR(A-S[2*i],B)^B;
	}
	pt[1] = B-S[1];
	pt[0] = A-S[0];
}

void setup(unsigned char *K){
	WORD i,j,k,u,A,B,L[c];
	u = w/8;
	L[c-1] = 0;
	for(i=b-1; i!= -1; i--){ 
		L[i/u] = (L[i/u]<<8) + K[i];;
	}
	S[0] = P;
	for(i=1; i<t; i++){
		S[i] = S[i-1] + Q;
	}
	for(A=B=i=j=k=0; k<3*t; k++){
		A = S[i] = ROTL(S[i]+(A+B),3);
		B = L[j] = ROTL(L[j]+(A+B), (A+B));
		i = (i+1)%t;
		j = (j+1)%c;
	}
}

void printword(WORD A){
	printf("%.8x", A);
}


int main(int argc, char **argv) {
	int maxSize = 33;
	
	if(argc != 3) {
		cout << "Usage: ./demoRC <mode> <output_file>" << endl;
		return 1;
	}
	int mode = atoi(argv[1]);
	if(mode != 0 && mode != 1) {
		cout << "Mode must be 0,1. Mode 0: Output to File and Mode 1: Output to Console Only" << endl;
		return 1;
	}
	char *outputFileName = argv[2];
	char message[33] = {0x20};
	FILE *output;
	
	if((output = fopen(outputFileName, "w")) == NULL){
	  fprintf(stderr, "Could not read file\n");
	  return 1;
	}
	
	WORD inputKey = 0;
	unsigned char key[b];
	WORD pt1[8], pt2[8], ct[8] = {0,0,0,0,0,0,0,0};
	
	
	while(1){
		for(int y=0; y < 8; y++) {
			pt1[y] = 0;
			pt2[y] = 0;
			ct[y] = 0;
		}
		cout << "Please enter message to encrypt or \"Quit\" to exit" << endl;
		cin.get(message, maxSize);
		if(strcmp(message, "Quit") == 0) break;
		cin.ignore(1024, '\n');
		cout << "Please enter Key: " << endl;
		cin >> inputKey;
		cin.ignore(1024, '\n');
		key[0] = (inputKey & 0xFF000000) >> 24;
		key[1] = (inputKey & 0x00FF0000) >> 16;
		key[2] = (inputKey & 0x0000FF00) >> 8;
		key[3] = (inputKey & 0x000000FF);
		int x = 0;
		for(int i=0; i < 8; i++){
			x = 3;
			for(int j=0; j < 4; j++){
				pt1[i] |= (message[(4*i) + j] << (8*x))  ;
				x--;
			}
			printword(pt1[i]); cout << endl;
		}
		setup(key);
		encrypt(pt1,ct);
		decrypt(ct,pt2);
		setup(key);
		encrypt((pt1+2),(ct+2));
		decrypt((ct+2),(pt2+2));
		setup(key);
		encrypt((pt1+4),(ct+4));
		decrypt((ct+4),(pt2+4));
		setup(key);
		encrypt((pt1+6),(ct+6));
		decrypt((ct+6),(pt2+6));
		printf("key = ");
		for(int j=0; j<b; j++) printf("%02.2x", key[j]);
		printf("\nplaintext --->  ");
		for(int i=0; i<8; i++) printword(pt1[i]);
		printf("\nciphertext ---> ");
		for(int i=0; i<8; i++) printword(ct[i]);
		printf("\ndecrypted --->  ");
		for(int i=0; i<8; i++) printword(pt2[i]);
		cout << endl;
		if(pt1[0] != pt2[0] || pt1[1] != pt2[1] || pt1[2] != pt2[2] || pt1[3] != pt2[3]
			|| pt1[4] != pt2[4] || pt1[5] != pt2[5] || pt1[6] != pt2[6] || pt1[7] != pt2[7]) 
			printf("Decryption Error!\n");
		if(mode == 0){
			for(int i=0; i<8; i++) fprintf(output,"%.8x", ct[i]);
			fprintf(output,"\n");
		}
		for(int i=0; i < maxSize; i++) message[i] = 0x20;
	}
	fclose(output);
	return 0;
}

