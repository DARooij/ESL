
module TopEntity (
  input clk,
  input rst,

  input  SPI_CLK,
  input  SPI_PICO,
  input  SPI_CS,
  output SPI_POCI,

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
wire [63:0] SPI_DATA_IN;
reg [63:0] SPI_DATA_IN_REG;
wire [63:0] SPI_DATA_OUT;

quad_decod pitch_decod(
  .clk(clk),
  .rst(rst),
  .quadA(PITCH_ENC_A),
  .quadB(PITCH_ENC_B),
  .out(pitch_encoder_value),
  .direction_out(pitch_direction)
);

quad_decod yaw_decod(
  .clk(clk),
  .rst(rst),
  .quadA(YAW_ENC_A),
  .quadB(YAW_ENC_B),
  .out(yaw_encoder_value),
  .direction_out(yaw_direction)
);

SPI spi_interface(
  .clk(clk),
  .SPI_CLK(SPI_CLK),
  .SPI_PICO(SPI_PICO),
  .SPI_CS(SPI_CS),
  .SPI_DATA_IN(SPI_DATA_IN),
  .SPI_POCI(SPI_POCI),
  .SPI_DATA_OUT(SPI_DATA_OUT)
);

pwm_mod yaw_pwm(
  .clk(clk),
  .rst(rst),
  .duty_cycle(SPI_DATA_OUT[7:0]),
  .direction(SPI_DATA_OUT[9:8]),
  .pwm_out(YAW_PWM_VAL),
  .directionA(YAW_DIRA),
  .directionB(YAW_DIRB)
);

pwm_mod pitch_pwm(
  .clk(clk),
  .rst(rst),
  .duty_cycle(SPI_DATA_OUT[39:32]),
  .direction(SPI_DATA_OUT[41:40]),
  .pwm_out(PITCH_PWM_VAL),
  .directionA(PITCH_DIRA),
  .directionB(PITCH_DIRB)
);

always @ (posedge clk) begin
  SPI_DATA_IN_REG <= {16'b0, pitch_encoder_value, 16'b0, yaw_encoder_value}; 
end

assign SPI_DATA_IN = SPI_DATA_IN_REG;

endmodule