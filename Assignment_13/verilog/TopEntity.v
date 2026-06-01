
module TopEntity (
  input clk,
  input rst,

  input  SPI_CLK,
  input  SPI_PICO,
  input  SPI_CS,
  input [63:0] SPI_DATA_IN,
  output SPI_POCI,
  output [63:0] SPI_DATA_OUT,

  input PITCH_ENC_A, 
  input PITCH_ENC_B, 
  input YAW_ENC_A,
  input YAW_ENC_B,

  // input [7:0] PITCH_DUTY_CYCLE,
  // input PITCH_DIRECTION,
  output wire PITCH_DIR_A,
  output wire PITCH_DIR_B,
  output wire PITCH_PWM_VAL,

  // input [7:0] YAW_DUTY_CYCLE,
  // input YAW_DIRECTION,
  output wire YAW_DIR_A,
  output wire YAW_DIR_B,
  output wire YAW_PWM_VAL

);

wire [15:0] pitch_encoder_value;
wire [1:0] pitch_direction;
wire [15:0] yaw_encoder_value;
wire [1:0] yaw_direction;

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
  .spi_DATA_OUT(SPI_DATA_OUT)
);

pwm_mod yaw_pwm(
  .clk(clk),
  .rst(rst),
  .duty_cycle(SPI_DATA_OUT[7:0]),
  .direction(SPI_DATA_OUT[9:8]),
  .PWM_OUT(YAW_PWM_VAL),
  .DIR_A(YAW_DIR_A),
  .DIR_B(YAW_DIR_B)
);

pwm_mod pitch_pwm(
  .clk(clk),
  .rst(rst),
  .duty_cycle(SPI_DATA_OUT[39:32]),
  .direction(SPI_DATA_OUT[41:40]),
  .PWM_OUT(PITCH_PWM_VAL),
  .DIR_A(PITCH_DIR_A),
  .DIR_B(PITCH_DIR_B)
);

always @ (posedge clk) begin
  SPI_DATA_IN <= {16'b0, pitch_encoder_value, 16'b0, yaw_encoder_value}; 
end

endmodule