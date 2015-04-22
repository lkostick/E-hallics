SPART and Controller
=========================
Controller: 

	1. Stores the data into fifo. 
	2. If the fifo is full, it gives a signal to CPU and then CPU will stall. 
	3. When the fifo is not empty and SPART is ready to send data, it will read data from fifo and send it.
	4. When SPART received data, it will store the data into buffer and interrupt CPU

SPART: 
	
	1. The baud rate is fixed, 38400
FIFO SETUP:
	1. Block RAM
	2. One clock
	3. Sync Reset
	4. Depth -> anything
	5. Data Read -> 8 bits
