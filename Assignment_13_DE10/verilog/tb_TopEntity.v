`timescale 1ns/1ps

module tb_TopEntity_Combined;

    // Parameters
    parameter DATA_WIDTH = 32;

    // Inputs
    reg clk;
    reg reset;
    reg [7:0] slave_address;
    reg slave_read;
    reg slave_write;
    reg [DATA_WIDTH-1:0] slave_writedata;
    reg [(DATA_WIDTH/8)-1:0] slave_byteenable;
    reg PITCH_ENC_A, PITCH_ENC_B;
    reg YAW_ENC_A, YAW_ENC_B;

    // Outputs
    wire [DATA_WIDTH-1:0] slave_readdata;
    wire PITCH_DIRA, PITCH_DIRB, PITCH_PWM_VAL;
    wire YAW_DIRA, YAW_DIRB, YAW_PWM_VAL;

    // Instantiate the Unit Under Test (UUT)
    // Note: This uses the exact TopEntity from your first prompt.
    TopEntity #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .slave_address(slave_address),
        .slave_read(slave_read),
        .slave_readdata(slave_readdata),
        .slave_write(slave_write),
        .slave_writedata(slave_writedata),
        .slave_byteenable(slave_byteenable),
        .PITCH_ENC_A(PITCH_ENC_A),
        .PITCH_ENC_B(PITCH_ENC_B),
        .YAW_ENC_A(YAW_ENC_A),
        .YAW_ENC_B(YAW_ENC_B),
        .PITCH_DIRA(PITCH_DIRA),
        .PITCH_DIRB(PITCH_DIRB),
        .PITCH_PWM_VAL(PITCH_PWM_VAL),
        .YAW_DIRA(YAW_DIRA),
        .YAW_DIRB(YAW_DIRB),
        .YAW_PWM_VAL(YAW_PWM_VAL)
    );

    // 50MHz Clock Generator (Matches your CLOCK_FREQUENCY parameter)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; 
    end

    // Avalon-MM 32-bit Write Task
    task write_avalon(input [31:0] write_data);
        begin
            @(posedge clk);
            slave_write = 1;
            slave_writedata = write_data;
            @(posedge clk);
            slave_write = 0;
        end
    endtask

    // Monitor changes to the direction pins
    initial begin
        $dumpfile("waveforms.vcd"); // Name of the output waveform file
        $dumpvars(0, tb_TopEntity_Combined); // Dumps all variables in this module

        $monitor("Time: %0t | YAW_DIR A:%b B:%b | PITCH_DIR A:%b B:%b", 
                 $time, YAW_DIRA, YAW_DIRB, PITCH_DIRA, PITCH_DIRB);
    end

    // Test Sequence
    initial begin
        // Initialize Inputs
        reset = 1;
        slave_address = 0;
        slave_read = 0;
        slave_write = 0;
        slave_writedata = 0;
        slave_byteenable = 4'b1111;
        PITCH_ENC_A = 0; PITCH_ENC_B = 0;
        YAW_ENC_A = 0; YAW_ENC_B = 0;

        // Wait for reset to finish
        #100;
        reset = 0;
        #100;

        // ====================================================================
        // TEST CASE 1: Both Motors Direction A (Bit = 1), 10% PWM
        // ====================================================================
        // Yaw Word:   (1 << 8)  | 10 = 266        (Hex: 0x010A)
        // Pitch Word: (1 << 17) | (10 << 9) = 136192 (Hex: 0x21400)
        // Combined:   0x2150A
        $display("\n--- Test 1: Writing Dir A (1) and 10%% PWM to both ---");
        write_avalon(32'h0002150A);
        
        // Wait long enough for the PWM counter to process a few cycles
        #10000;

        // ====================================================================
        // TEST CASE 2: Both Motors Direction B (Bit = 0), 10% PWM
        // ====================================================================
        // Yaw Word:   (0 << 8)  | 10 = 10         (Hex: 0x000A)
        // Pitch Word: (0 << 17) | (10 << 9) = 5120   (Hex: 0x01400)
        // Combined:   0x0140A
        $display("\n--- Test 2: Writing Dir B (0) and 10%% PWM to both ---");
        write_avalon(32'h0000140A);
        
        #10000;

        // ====================================================================
        // TEST CASE 3: Mixed Directions
        // ====================================================================
        // Yaw: Dir A (1), 50% PWM -> (1<<8)|50 = 306 -> Hex: 0x0132
        // Pitch: Dir B (0), 20% PWM -> (0<<17)|(20<<9) -> Hex: 0x02800
        // Combined: 0x02932
        $display("\n--- Test 3: Yaw Dir A (50%%), Pitch Dir B (20%%) ---");
        write_avalon(32'h00002932);

        #10000;

        // ====================================================================
        // TEST CASE 4: Full Stop (0% PWM, Direction Bits 0)
        // ====================================================================
        $display("\n--- Test 4: Full Stop (Writing 0) ---");
        write_avalon(32'h00000000);

        #10000;

        $display("\nTestbench complete.");
        $finish;
    end
endmodule