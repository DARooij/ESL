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

  parameter BITS_PER_MESSAGE = 64;

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

  reg [7:0] bitcnt;
  reg byte_received;
  reg [BITS_PER_MESSAGE-1:0] byte_data_received;

  always @(posedge clk) begin
    if (~SPI_CS_active) bitcnt <= 0;
    else if (SPI_CLK_risingedge) begin
      bitcnt <= bitcnt + 1;
      byte_data_received <= {byte_data_received[BITS_PER_MESSAGE-2:0], SPI_PICO_data};
    end
  end

  always @(posedge clk) byte_received <= SPI_CS_active && SPI_CLK_risingedge && (bitcnt == BITS_PER_MESSAGE-1);

  // store the last fully received 64-bit word
  reg [BITS_PER_MESSAGE-1:0] last_received;
  // buffer used to drive outgoing data during the next transaction
  reg [BITS_PER_MESSAGE-1:0] send_buffer;

  always @(posedge clk) if (byte_received) last_received <= byte_data_received;
  // expose the most recently received word on the output port
  assign SPI_DATA_OUT = last_received;

  reg [BITS_PER_MESSAGE-1:0] byte_data_sent;
 
  always @(posedge clk) begin
    if (~SPI_CS_active)
      byte_data_sent <= 0;
    else if (SPI_CS_startmessage)
      // load the previously received word to transmit back this transaction
      byte_data_sent <= send_buffer;
    else if (SPI_CLK_fallingedge)
      byte_data_sent <= {byte_data_sent[BITS_PER_MESSAGE-2:0], 1'b0};
  end

  // update the send buffer at the end of a CS (so the received word is returned next transaction)
  always @(posedge clk)
    if (SPI_CS_endmessage)
      send_buffer <= last_received;

  assign SPI_POCI = byte_data_sent[BITS_PER_MESSAGE-1];
 
endmodule
