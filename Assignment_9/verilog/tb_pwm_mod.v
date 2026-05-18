`timescale 1ns / 1ps

module pwm_mod_tb;

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

    always begin
        #10 clk = ~clk; 
    end

    initial begin

        $dumpfile("pwm_simulation.vcd"); // Names the output waveform file
        $dumpvars(0, tb_pwm_mod);        // Dumps all variables in the testbench module
        
        clk = 0;
        reset = 1;
        duty_cycle = 0;
        direction = 0;

        #100;
        reset = 0;
        #20;
        
        // --- Test Case 1: 50% Duty Cycle, Forward Direction ---
        duty_cycle = 50;
        direction = 1;
        // Wait for 2 full PWM cycles to observe behavior (1 cycle @ 20kHz = 50,000 ns)
        #100000;

        // --- Test Case 2: 25% Duty Cycle, Reverse Direction ---
        duty_cycle = 25;
        direction = 0;
        #100000;

        // --- Test Case 3: 0% Duty Cycle (Should stay constantly LOW) ---
        duty_cycle = 0;
        #100000;

        // --- Test Case 4: Saturation Check (105% input should clamp to 100% / constantly HIGH) ---
        duty_cycle = 105;
        #100000;

        // --- Test Case 5: 100% Duty Cycle ---
        duty_cycle = 100;
        #100000;

        // End the simulation
        $display("Simulation complete.");
        $stop; 
    end
      
endmodule