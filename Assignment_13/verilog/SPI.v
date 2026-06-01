// TopEntity.v
// Contains a verilog module called TopEntity that inplements a simple SPI bouncer.
// What it receives in transaction N, it will send back in transaction N+1.
// Look into SPI and Full-Duplex connection for more information if this is unclear
//
// Heavily insired by https://www.fpga4fun.com/SPI2.html
// Code is intentionally left uncommented as it is only to demonstrate using the Logic Analyzer for SPI readout,
// not necessarely a "how-to" on verilog SPI inplementation.

module SPI (
    input  clk,
    input  SPI_CLK,
    input  SPI_PICO,
    input  SPI_CS,
    input [63:0] SPI_DATA_IN,
    output SPI_POCI,
    output [63:0] SPI_DATA_OUT
);

  reg [2:0] SPI_CLKr;
  always @(posedge clk) SPI_CLKr <= {SPI_CLKr[1:0], SPI_CLK};
  wire SPI_CLK_risingedge = (SPI_CLKr[2:1] == 2'b01);
  wire SPI_CLK_fallingedge = (SPI_CLKr[2:1] == 2'b10);

  reg [2:0] SPI_CSr;
  always @(posedge clk) SPI_CSr <= {SPI_CSr[1:0], SPI_CS};
  wire SPI_CS_active = ~SPI_CSr[1];
  wire SPI_CS_startmessage = (SPI_CSr[2:1] == 2'b10);
  wire SPI_CS_endmessage = (SPI_CSr[2:1] == 2'b01);

  reg [1:0] SPI_PICOr;
  always @(posedge clk) SPI_PICOr <= {SPI_PICOr[0], SPI_PICO};
  wire SPI_PICO_data = SPI_PICOr[1];

  reg [6:0] bitcnt;
  reg byte_received;
  reg [63:0] byte_data_received;

  always @(posedge clk) begin
    if (~SPI_CS_active) bitcnt <= 0;
    else if (SPI_CLK_risingedge) begin
      bitcnt <= bitcnt + 1;
      byte_data_received <= {byte_data_received[62:0], SPI_PICO_data};
    end
  end

  assign SPI_DATA_OUT = byte_data_received;

  always @(posedge clk) byte_received <= SPI_CS_active && SPI_CLK_risingedge && (bitcnt == 7'b1111111);

  reg led2;
  always @(posedge clk) if (byte_received) led2 <= byte_data_received[0];

  reg [63:0] byte_data_sent;

  always @(posedge clk)
    if (SPI_CS_active) begin
      if (SPI_CS_startmessage) byte_data_sent <= SPI_DATA_IN;
      else if (SPI_CLK_fallingedge) begin
        if (bitcnt == 0) byte_data_sent <= 0;
        else byte_data_sent <= {byte_data_sent[62:0], 1'b0};
      end
    end

  assign SPI_POCI = byte_data_sent[63];

endmodule
