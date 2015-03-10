#include <stdio.h>
#include <stdint.h>
typedef uint32_t WORD; /* w = 32 */
//typedef uint16_t WORD; /* w = 16 */
//typedef unsigned long int WORD;
#define w	32
//#define w	16
#define r	12
#define b	4	
#define c	1 /* c = max(b,1)/u => c = 8*b/u    */
#define t	26
WORD S[t];
WORD P = 0xb7e15163; /* for w = 32 */
WORD Q = 0x9e3779b9; /* for w = 32 */
//WORD P = 0xb7e1; /* w = 16 */
//WORD Q = 0x9e37; /* w = 16 */
#define ROTL(x,y) (((x)<<(y&(w-1))) | ((x)>>(w-(y&(w-1)))))
#define ROTR(x,y) (((x)>>(y&(w-1))) | ((x)<<(w-(y&(w-1)))))

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
		L[i/u] = (L[i/u]<<8) + K[i];
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
//	WORD k;
//	for(k=0; k<w; k+=8){
//		fwrite(A, sizeof(A), 1, outfile);
//		printf("%02.21x", (A>>k)&0xff);
//	}
}

void main(){
	WORD i,j,k,pt1[2],pt2[2], ct[2] = {0,0};
	FILE* outfile;
	unsigned char key[b];
	outfile = fopen("output.bin", "wb");
	if (sizeof(WORD)!=4){
		printf("RC5 error: WORD %d bytes. \n", sizeof(WORD));
	}
	printf("RC5-32/12/16 examples:\n");
	printf("%.4x", pt1[0]);
	for(i=1;i<6;i++){
		pt1[0] = ct[0]; pt1[1] = ct[1];
		for(j=0;j<b;j++) key[j] = ct[0]%(255-j);
		setup(key);
		encrypt(pt1,ct);
		decrypt(ct,pt2);
		printf("\n%d. key = ",i);
		for(j=0; j<b; j++) printf("%02.2x", key[j]);
		printf("\nplaintext --->  "); printword(pt1[0]); printword(pt1[1]);
		printf("\nciphertext ---> "); printword(ct[0]); printword(ct[1]);
		printf("\n");
		fwrite(ct, sizeof(ct), 1, outfile);
		printf("decrypted --->  "); printword(pt2[0]); printword(pt2[1]);
		printf("\n");
		if(pt1[0] != pt2[0] || pt1[1] != pt2[1])
			printf("Decryption Error!");
	}
	fclose(outfile);
}
