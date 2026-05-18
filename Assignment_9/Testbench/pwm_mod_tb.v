`timescale 1ns / 1ps

module pwm_mod_tb; // <-- 1. Check this name

    reg clk;
    reg reset;
    reg [7:0] duty_cycle;
    reg direction;

    wire directionA;
    wire directionB;
    wire pwm_out;

    pwm_mod uut (
        .clk(clk),
        .reset(reset),
        .duty_cycle(duty_cycle),
        .direction(direction),
        .directionA(directionA),
        .directionB(directionB),
        .pwm_out(pwm_out)
    );

    // Clock Generation
    always begin
        #10 clk = ~clk; 
    end

    // Stimulus Procedure
    initial begin
        // 2. THIS NAME MUST MATCH THE MODULE NAME AT THE TOP EXACTLY
        $dumpfile("pwm_simulation.vcd"); 
        $dumpvars(0, pwm_mod_tb);        

        // Initialize Inputs
        clk = 0;
        reset = 1;
        duty_cycle = 0;
        direction = 0;

        #100000;
        reset = 0;
        #100000;
        
        duty_cycle = 50;
        direction = 1;
        #100000;

        duty_cycle = 25;
        direction = 0;
        #100000;

        $display("Simulation complete.");
        $stop; 
    end
      
endmodule