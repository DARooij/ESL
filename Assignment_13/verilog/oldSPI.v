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
    //  input [63:0] SPI_DATA_IN,
    output SPI_POCI,
    //  output [63:0] SPI_DATA_OUT
);

  reg [7:0] SPI_DATA_IN = 150;
  wire [7:0] SPI_DATA_OUT;
  parameter BITS_PER_MESSAGE = 8;

  // Synchronize SPI signals to the system clock domain
  reg [2:0] SPI_CLKr;
  always @(posedge clk) SPI_CLKr <= {SPI_CLKr[1:0], SPI_CLK};
  wire SPI_CLK_risingedge = (SPI_CLKr[2:1] == 2'b01);
  wire SPI_CLK_fallingedge = (SPI_CLKr[2:1] == 2'b10);

  // Synchronize SPI CS to the system clock domain
  reg [2:0] SPI_CSr;
  always @(posedge clk) SPI_CSr <= {SPI_CSr[1:0], SPI_CS};
  wire SPI_CS_active = ~SPI_CSr[1];
  wire SPI_CS_startmessage = (SPI_CSr[2:1] == 2'b10);
  wire SPI_CS_endmessage = (SPI_CSr[2:1] == 2'b01);

  // Synchronize SPI_PICO to the system clock domain
  reg [1:0] SPI_PICOr;
  always @(posedge clk) SPI_PICOr <= {SPI_PICOr[0], SPI_PICO};
  wire SPI_PICO_data = SPI_PICOr[1];

  // SPI shift register and bit counter
  reg [2:0] bitcnt;
  reg byte_received;
  reg [BITS_PER_MESSAGE-1:0] byte_data_received = 0;

  // Shift in data on SPI_CLK rising edge when CS is active
  always @(posedge clk) begin
    if (~SPI_CS_active) bitcnt <= 0;
    else if (SPI_CLK_risingedge) begin
      bitcnt <= bitcnt + 3'b001;
      byte_data_received <= {byte_data_received[BITS_PER_MESSAGE-2:0], SPI_PICO_data};
    end
  end

  // Flag when a full byte has been received (after 64 bits)
  always @(posedge clk) byte_received <= SPI_CS_active && SPI_CLK_risingedge && (bitcnt == 6'b111);
 
  // Output the received byte on SPI_DATA_OUT at the next clock cycle after reception
  reg [BITS_PER_MESSAGE-1:0] spi_data_out_reg;

  // Update SPI_DATA_OUT with the received data after a full message is received
  always @(posedge clk) if (byte_received) spi_data_out_reg <= byte_data_received;
  assign SPI_DATA_OUT = spi_data_out_reg;

  // Shift out data on SPI_POCI on SPI_CLK falling edge when CS is active
  reg [BITS_PER_MESSAGE-1:0] byte_data_sent;
 
  // Load the data to be sent on SPI_POCI at the start of a new message (when CS goes active)
  always @(posedge clk)
    if (SPI_CS_active) begin
      if (SPI_CS_startmessage) byte_data_sent <= SPI_DATA_IN;
      else if (SPI_CLK_fallingedge) begin
          if (bitcnt == 3'b000) byte_data_sent <= 8'h00;
          else byte_data_sent <= {byte_data_sent[BITS_PER_MESSAGE-2:0], 1'b0};
      end
    end

  // Output the MSB of byte_data_sent on SPI_POCI
  assign SPI_POCI = byte_data_sent[BITS_PER_MESSAGE-1];
 
endmodule
