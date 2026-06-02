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

  reg [2:0] bitcnt;
  reg byte_received;
  reg [7:0] byte_data_received;

  always @(posedge clk) begin
    if (~SPI_CS_active) bitcnt <= 0;
    else if (SPI_CLK_risingedge) begin
      bitcnt <= bitcnt + 1;
      byte_data_received <= {byte_data_received[6:0], SPI_PICO_data};
    end
  end

  always @(posedge clk) byte_received <= SPI_CS_active && SPI_CLK_risingedge && (bitcnt == 3'b111);

  reg led2;
  always @(posedge clk) if (byte_received) led2 <= byte_data_received[0];

  reg [63:0] rBuff;
  reg [3:0] rmsg_count;
  
  always @ (posedge clk) begin
  if (byte_received) begin
      rBuff <= {rBuff[55:0], byte_data_received};
      rmsg_count <= rmsg_count + 1;
    end 
  end

  always @(posedge clk) 
  begin
    if (rmsg_count == 8) begin
      SPI_DATA_OUT <= rBuff;
      sBuff <= SPI_DATA_IN;
      rmsg_count <= 0;
    end
    
  end
  
  reg [63:0] sBuff;
  reg [3:0] smsg_count;

  reg [6:0] byte_data_sent;

  always @(posedge clk)
    if (SPI_CS_active) begin
      if (SPI_CS_startmessage) byte_data_sent <= sBuff[rmsg_count*8-1:rmsg_count*8-8];
      else if (SPI_CLK_fallingedge) begin
          if (bitcnt == 3'b000) byte_data_sent <= 8'h00;
          else byte_data_sent <= {byte_data_sent[6:0], 1'b0};
      end
    end

  assign SPI_POCI = byte_data_sent[7];
 
endmodule
