module pwm_mod_demo #(
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
        output wire [7:0] duty_cycle_out,
		output wire pwm_output,    
        output wire directionA_out, 
        output wire directionB_out
	);

    reg direction_input = 0;
    reg [7:0] duty_cycle_input = 0;


    // Definition of the counter
    pwm_mod my_ip (
        .clk(clk),
        .reset(reset),
        .duty_cycle(duty_cycle_input),
        .direction(direction_input),
        .directionA(directionA_out),
        .directionB(directionB_out),
        .pwm_out(pwm_output)
    );

    assign duty_cycle_out = duty_cycle_input;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            slave_readdata <= 32'b0;
            duty_cycle_input <= 8'b0;
            direction_input <= 1'b0;
        end else begin 
            if (slave_read) begin
                slave_readdata <= {29'b0, directionB_out, directionA_out, pwm_output };
            end
            if (slave_write) begin
                duty_cycle_input <= slave_writedata[7:0];
                direction_input <= slave_writedata[8];
            end
        end
    end


endmodule