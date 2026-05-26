module quad_decod_demo #(
        parameter DATA_WIDTH = 32
	) (
		input  wire [7:0]  slave_address,     //      avs_s0.address
		input  wire        slave_read,        //            .read
		output reg  [DATA_WIDTH-1:0] slave_readdata,    //            .readdata
		input  wire        slave_write,       //            .write
		input  wire [DATA_WIDTH-1:0] slave_writedata,   //            .writedata
		input  wire        clk,          //       clock.clk
        input  wire        reset,
        input  wire [(DATA_WIDTH/8)-1:0] slave_byteenable,
		output wire [7:0]  user_output,         // user_output.new_signal
        // output wire [1:0] user_output_2 // user_output_2.new_signal
        // input wire PITCH_ENC_A,
        // input wire PITCH_ENC_B
        input wire [3:0] SW
	);

    
    wire [15:0] count;
    wire [1:0] direction;

    // Definition of the counter
    quad_decod my_ip (
        .clk(clk),
        .reset(reset),
        // .quadA(PITCH_ENC_A),
        // .quadB(PITCH_ENC_B),
        .quadA(SW[0]),
        .quadB(SW[1]),
        .out(count),
        .direction_out(direction)
    );

    assign user_output = count[7:0];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            slave_readdata <= 32'b0;
        end else begin
            if (slave_read) begin
                slave_readdata <= {14'b0, direction, count};
            end
        end;
    end

endmodule