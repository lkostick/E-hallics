module alu(input [15:0] src0,src1,input [2:0] opcode, output reg [15:0] dst,output reg ov,zr,n);
    
   localparam Add=3'h0;
   localparam Sub=3'h1;
   localparam Xor=3'h2;
   localparam Sll=3'h3;
   localparam Srl=3'h4;
   localparam Sra=3'h5;
   localparam Llb=3'h6;
   localparam Lhb=3'h7;
    
   reg [15:0] Sum,src_temp,dst_ARI,dst_XOR,dst_SLL,dst_SRL,dst_SRA,dst_LHB,dst_LLB;
   reg    ov_temp;

  
   always @(*) begin
      //////////////////////////////
      //  1's complement and add  //
      //////////////////////////////
      src_temp=src1^{16{opcode[0]}};      
      Sum=src0+src_temp+opcode[0];
      
      /////////////////////
      // Check overflow  //
      /////////////////////
      if (Sum[15]!=src0[15]) begin
		  if (src0[15]==src_temp[15]) ov_temp= 1;
		  else ov_temp=0;
      end
      else ov_temp=0;

      ////////////////////////////
      //  Set Saturation result //
      ////////////////////////////
      if (ov_temp==0) dst_ARI=Sum;
      else  dst_ARI=16'h8000^{16{Sum[15]}};

      /////////////////////////////////////////
      //  Set results for other instruction  //
      /////////////////////////////////////////
      dst_XOR=src0^src1;
      dst_SLL=src0<<src1[3:0];
      dst_SRL=src0>>src1[3:0];
      dst_SRA={{15{src0[15]}},src0}>>src1[3:0];
      dst_LHB={src1[7:0],src0[7:0]};
	  dst_LLB={8'h00, src1[7:0]};
      
      ///////////////////////////
      //  Select final result  //
      ///////////////////////////
      case (opcode)
		  Add:  dst=dst_ARI;
		  Sub:  dst=dst_ARI;
		  Xor:  dst=dst_XOR;
		  Sll:  dst=dst_SLL;
		  Srl:  dst=dst_SRL;
		  Sra:  dst=dst_SRA;
		  Lhb:  dst=dst_LHB;
		  default: dst=dst_LLB;
      endcase
      
      /////////////////
      //  Set Flags  //
      /////////////////
      zr=~|dst;                      
      ov=ov_temp;         
      n=dst[15];         
   end
   
endmodule
