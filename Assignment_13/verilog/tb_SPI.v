`timescale 1ns/1ps
`include "SPI.v"

module tb_SPI;
  reg clk = 0;
  reg SPI_CLK = 0;
  reg SPI_PICO = 0;
  reg SPI_CS = 1;
  reg [63:0] SPI_DATA_IN = 0;
  wire SPI_POCI;
  wire [63:0] SPI_DATA_OUT;

  SPI dut (
    .clk(clk),
    .SPI_CLK(SPI_CLK),
    .SPI_PICO(SPI_PICO),
    .SPI_CS(SPI_CS),
    .SPI_DATA_IN(SPI_DATA_IN),
    .SPI_POCI(SPI_POCI),
    .SPI_DATA_OUT(SPI_DATA_OUT)
  );

  // Faster system clock to ensure the DUT samples SPI signals correctly
  always #1 clk = ~clk;

  reg [63:0] rx1;
  reg [63:0] rx2;

  task send_spi_transaction(input [63:0] tx_data, output reg [63:0] sampled_rx);
    integer i;
    begin
      sampled_rx = 0;
      SPI_DATA_IN = tx_data;
      SPI_CS = 0;
      #20;

      for (i = 0; i < 64; i = i + 1) begin
        // Transmit MSB-first to match the SPI module's transmit order
        SPI_PICO = tx_data[63 - i];
        #1 SPI_CLK = 1;
        #9 SPI_CLK = 0;
        #1;
        // Sample MSB-first into the corresponding bit position
        sampled_rx[63 - i] = SPI_POCI;
        #5;
      end

      #10;
      SPI_CS = 1;
      #20;
      SPI_PICO = 0;
    end
  endtask

  initial begin
    $dumpfile("tb_SPI.vcd");
    $dumpvars(0, tb_SPI);

    #20;
    $display("Starting SPI testbench...");

    send_spi_transaction(64'h0123_4567_89AB_CDEF, rx1);
    $display("After first transaction: SPI_DATA_OUT = %016h", SPI_DATA_OUT);

    send_spi_transaction(64'hFEDC_BA98_7654_3210, rx2);
    #200000
    $display("After second transaction: SPI_DATA_OUT = %016h", SPI_DATA_OUT);
    $display("Sampled SPI_POCI during second transaction = %016h", rx2);

    if (SPI_DATA_OUT !== 64'hFEDC_BA98_7654_3210)
      $display("FAIL: SPI_DATA_OUT does not contain the second transmitted word");
    else
      $display("PASS: SPI_DATA_OUT contains the second transaction word");

    if (rx2 !== 64'h0123_4567_89AB_CDEF)
      $display("FAIL: SPI_POCI did not transmit the first transaction word back");
    else
      $display("PASS: SPI_POCI transmitted the first transaction word back");

    $display("Test complete.");
    #20;
    $finish;
  end
endmodule
