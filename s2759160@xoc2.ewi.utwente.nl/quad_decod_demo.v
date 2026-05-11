`timescale 1 ps / 1 ps
module quad_decod_demo #(
		parameter COUNT_WIDTH = 16,
        parameter DATA_WIDTH = 32
	) (
		input  wire [7:0]  slave_address,     //      avs_s0.address
		input  wire        slave_read,        //            .read
		output reg  [DATA_WIDTH-1:0] slave_readdata,    //            .readdata
		input  wire        slave_write,       //            .write
		input  wire [DATA_WIDTH-1:0] slave_writedata,   //            .writedata
		input  wire        clk,          //       clock.clk
        input  wire [(DATA_WIDTH/8)-1:0] slave_byteenable,
		output wire [COUNT_WIDTH-1:0]  user_output,         // user_output.new_signal
        output wire [1:0] user_output_2 // user_output_2.new_signal
	);

    // Internal memory for the system and a subset for the IP
    reg [31:0] mem;
    wire [COUNT_WIDTH-1:0] mem_masked;
    wire enable;
    wire PITCH_ENC_A;
    wire PITCH_ENC_B;

    // Definition of the counter
    quad_decod my_ip (
        .clk(clk),
        // .count(mem_masked),
        .quadA(PITCH_ENC_A),
        .quadB(PITCH_ENC_B),
        .count(user_output),
        .direction(user_output_2)
    );

    assign mem_masked = mem[COUNT_WIDTH-1:0];
    assign user_output_2 = mem[31:30];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem <= 32'b0;
        end else begin
            if (slave_read) begin
                slave_readdata <= mem;
            end
            if (slave_write) begin
                mem <= slave_writedata;
            end;
        end;
    end



endmodule