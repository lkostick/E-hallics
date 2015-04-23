#include <stdio.h>
#include <stdint.h>
#define t 	4
#define c	1
#define w	32
#define ROTL(x,y) (((x)<<(y&(w-1))) | ((x)>>(w-(y&(w-1)))))
#define B(x) S_to_binary_(#x)

typedef uint32_t WORD; /* w = 32 */
WORD S[t];
uint32_t i,j,k,A,B,L[c];

static inline unsigned long long S_to_binary_(const char *s)
{
        unsigned long long i = 0;
        while (*s) {
                i <<= 1;
                i += *s++ - '0';
        }
        return i;
}

int main()
{   
	uint32_t inA,inS,inB,inL;
	int x = 0;
	//printf("\n%d\n", B(1000));
	S[0] = 2;
	S[1] = 0;
	S[2] = 0;
	S[3] = 0;
	L[0] = 1;
	//printf("\nROTL = %x\n", ROTL(0x71001111,0x888815792));
	for(x=0; x < 10; x++){
		S[0] = 2+x;
		S[1] = 0;
		S[2] = 0;
		S[3] = 0;
		L[0] = 1;
		for(A=B=i=j=k=0; k<3*t; k++){
			inA = A + B + S[i];
			inS = A + B + S[i];
//			printf("Into Rotate A: %.8x\n", inA);
//			printf("Into Rotate S: %.8x\n", inS);
			A = S[i] = ROTL(S[i]+(A+B),3);
//			printf("\nOut from rotate A: %.8x\n", A);
//			printf("Out from rotate S: %.8x\n", S[i]);
			inB = A + B + L[j];
			inL = A + B + L[j];
//			printf("\nInto Rotate B: %.8x\n", inB);
//			printf("Shift Amount: %d\n", (A+B)&0x1F);
//			printf("Into Rotate L: %.8x\n", inL);
			B = L[j] = ROTL(L[j]+(A+B), (A+B));
//			printf("\nOut from rotate B: %.8x\n", B);
//			printf("Out from rotate L: %.8x\n\n", L[j]);
			i = (i+1)%t;
			j = (j+1)%c;
			//printf("A = %d, S[i] = %d, B = %d, L[j] = %d, i = %d, j = %d,\n", A, S[i], B, L[j], i, j);
//			printf("S = %x\n%x\n%x\n%x\n, A = %x, B = %x, L = %x \n", S[3], S[2], S[1], S[0], A, B, L[0]);
		}
		printf("Iteration %d: S= %.8x %.8x %.8x %.8x\n",x, S[0], S[1], S[2], S[3]);
		
	}
	return 0;
}
