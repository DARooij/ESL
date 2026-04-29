`timescale 1ns/1ps

module tb_quad_decod;

    reg quadA;
    reg quadB;
    reg clk;
    wire [15:0] count;
    wire [1:0] direction;
    wire [1:0] err;


    quad_decod #() dut (
        .quadA(quadA),
        .quadB(quadB),
        .clk(clk),
        .count(count),
        .direction(direction),
        .err(err)
    );

    initial 
    begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial
    begin
        quadA = 1;
        forever #10 quadA = ~quadA;
    end

    initial 
    begin
        quadB = 0;
        #5
        quadB = 1;
        #5
        forever #5 quadB = ~quadB;
    end

endmodule