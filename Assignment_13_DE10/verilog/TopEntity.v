
module TopEntity #(
  parameter DATA_WIDTH = 32
  ) (
  input clk,
  input reset,

	input  wire [7:0]  slave_address,     //      avs_s0.address
	input  wire        slave_read,        //            .read
	output reg  [DATA_WIDTH-1:0] slave_readdata,    //            .readdata
	input  wire        slave_write,       //            .write
	input  wire [DATA_WIDTH-1:0] slave_writedata,   //            .writedata
  input  wire [(DATA_WIDTH/8)-1:0] slave_byteenable,

  input PITCH_ENC_A, 
  input PITCH_ENC_B, 
  input YAW_ENC_A,
  input YAW_ENC_B,

  output wire PITCH_DIRA,
  output wire PITCH_DIRB,
  output wire PITCH_PWM_VAL,

  output wire YAW_DIRA,
  output wire YAW_DIRB,
  output wire YAW_PWM_VAL

);

wire [15:0] pitch_encoder_value;
wire [1:0] pitch_direction;
wire [15:0] yaw_encoder_value;
wire [1:0] yaw_direction;

quad_decod pitch_decod(
  .clk(clk),
  .rst(reset),
  .quadA(PITCH_ENC_A),
  .quadB(PITCH_ENC_B),
  .out(pitch_encoder_value),
  .direction_out(pitch_direction)
);

quad_decod yaw_decod(
  .clk(clk),
  .rst(reset),
  .quadA(YAW_ENC_A),
  .quadB(YAW_ENC_B),
  .out(yaw_encoder_value),
  .direction_out(yaw_direction)
);

pwm_mod yaw_pwm(
  .clk(clk),
  .rst(reset),
  .duty_cycle(yaw_duty_cycle_input),
  .direction(yaw_direction_input),
  .pwm_out(YAW_PWM_VAL),
  .directionA(YAW_DIRA),
  .directionB(YAW_DIRB)
);

pwm_mod pitch_pwm(
  .clk(clk),
  .rst(reset),
  .duty_cycle(pitch_duty_cycle_input),
  .direction(pitch_direction_input),
  .pwm_out(PITCH_PWM_VAL),
  .directionA(PITCH_DIRA),
  .directionB(PITCH_DIRB)
);

    reg yaw_direction_input = 0;
    reg [7:0] yaw_duty_cycle_input = 0;

    reg pitch_direction_input = 0;
    reg [7:0] pitch_duty_cycle_input = 0;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            slave_readdata <= 32'b0;
            yaw_duty_cycle_input <= 8'b0;
            yaw_direction_input <= 1'b0;
            pitch_duty_cycle_input <= 8'b0;
            pitch_direction_input <= 1'b0;
        end else begin 
            if (slave_read) begin
                slave_readdata <= {pitch_encoder_value, yaw_encoder_value};
            end
            if (slave_write) begin
                yaw_duty_cycle_input <= slave_writedata[7:0];
                yaw_direction_input <= slave_writedata[8];
                pitch_duty_cycle_input <= slave_writedata[16:9];
                pitch_direction_input <= slave_writedata[17];
            end
        end
    end

endmodule