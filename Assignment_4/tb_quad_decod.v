
`include "quad_decod.v"
`timescale 1ns/1ps

module tb_quad_decod;

    reg quadA;
    reg quadB;
    reg clk;
    wire [15:0] count;
    wire [1:0] direction;
    integer i;
    integer j;


    quad_decod #() dut (
        .quadA(quadA),
        .quadB(quadB),
        .clk(clk),
        .count(count),
        .direction(direction)
    );

    initial 
    begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial
    begin
        quadA = 1;
        for (i = 0; i < 10; i = i + 1) begin
            #100;
            quadA = ~quadA;
        end

        quadA = 0;
        #100;
        quadA = 1;
        for (i = 0; i < 10; i = i + 1) begin
            #100;
            quadA = ~quadA;
        end
    end

    initial 
    begin
        quadB = 0;
        #50;
        quadB = 1;
        for (j = 0; j < 10; j = j + 1) begin
            #100;
            quadB = ~quadB;
        end

        quadB = 1;
        for (j = 0; j < 10; j = j + 1) begin
            #100;
            quadB = ~quadB;
        end
    end

    initial begin
        $dumpfile("signals.vcd");
        $dumpvars(0, tb_quad_decod);
        #10000;
        $finish;
    end

endmodule