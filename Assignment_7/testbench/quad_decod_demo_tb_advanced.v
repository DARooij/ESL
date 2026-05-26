`timescale 1ns / 1ps

module quad_decod_demo_tb_advanced;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 20; // 50 MHz clock

    // Testbench Signals
    reg                     clk;
    reg                     reset;
    reg  [7:0]              slave_address;
    reg                     slave_read;
    wire [DATA_WIDTH-1:0]   slave_readdata;
    reg                     slave_write;
    reg  [DATA_WIDTH-1:0]   slave_writedata;
    reg  [(DATA_WIDTH/8)-1:0] slave_byteenable;
    wire [7:0]              user_output;
    reg  [3:0]              SW;

    // UUT (Unit Under Test) Instance
    quad_decod_demo #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .slave_address(slave_address),
        .slave_read(slave_read),
        .slave_readdata(slave_readdata),
        .slave_write(slave_write),
        .slave_writedata(slave_writedata),
        .clk(clk),
        .reset(reset),
        .slave_byteenable(slave_byteenable),
        .user_output(user_output),
        .SW(SW)
    );

    // Clock Generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // -----------------------------------------------------------
    // TESTBENCH TASKS
    // -----------------------------------------------------------
    integer enc_state = 0; 
    
    // Task: Simulate physical rotation of the encoder
    // dir: 1 for CW (Right), 0 for CCW (Left)
    task rotate_encoder(input integer steps, input integer dir);
        integer i;
        begin
            for(i = 0; i < steps; i = i + 1) begin
                // Update internal gray code state tracker
                if (dir == 1) 
                    enc_state = (enc_state + 1) % 4;
                else 
                    enc_state = (enc_state - 1 + 4) % 4;

                // Map state tracker to Quadrature Gray Code (A, B)
                case(enc_state)
                    0: SW = 4'b0000; // 00
                    1: SW = 4'b0001; // 01
                    2: SW = 4'b0011; // 11
                    3: SW = 4'b0010; // 10
                endcase
                
                // Wait for the synchronous logic to process the edge
                #(CLK_PERIOD * 5); 
            end
        end
    endtask

    // Task: Perform Avalon Read and check against expected values
    task check_avalon_read(input [15:0] exp_count, input [1:0] exp_dir);
        reg [31:0] expected_data;
        begin
            expected_data = {14'b0, exp_dir, exp_count};
            
            @(posedge clk);
            slave_address = 8'h00; 
            slave_read    = 1'b1;
            
            @(posedge clk);
            #1; // Allow time for non-blocking assignments to settle
            
            if (slave_readdata !== expected_data) begin
                $display("[FAIL] Expected: 0x%h | Got: 0x%h", expected_data, slave_readdata);
                $error("Mismatch detected in Avalon Read!");
            end else begin
                $display("[PASS] Count: %0d | Direction: %b", exp_count, exp_dir);
            end
            
            @(posedge clk);
            slave_read = 1'b0;
            #(CLK_PERIOD * 2);
        end
    endtask

    // -----------------------------------------------------------
    // MAIN TEST SEQUENCE
    // -----------------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, quad_decod_demo_tb_advanced); 

        // 1. Initialize
        clk             = 1'b0;
        reset           = 1'b1;
        slave_address   = 8'h00;
        slave_read      = 1'b0;
        slave_write     = 1'b0;
        slave_writedata = 32'h0;
        slave_byteenable = 4'b1111;
        SW              = 4'b0000; 

        // 2. Release Reset
        #(CLK_PERIOD * 5);
        @(posedge clk) reset = 1'b0;
        #(CLK_PERIOD * 5);
        
        $display("============================================");
        $display(" Starting Automated Quadrature Decoder Test");
        $display("============================================");

        // 3. Test Clockwise Rotation (Right)
        $display("\n--- Testing Clockwise (Right) Rotation ---");
        rotate_encoder(4, 1); // Rotate CW by 4 states (1 full tick)
        check_avalon_read(16'd1, 2'b01); 

        rotate_encoder(8, 1); // Rotate CW by 8 states (2 full ticks)
        check_avalon_read(16'd3, 2'b01);

        // 4. Test Counter-Clockwise Rotation (Left)
        $display("\n--- Testing Counter-Clockwise (Left) Rotation ---");
        rotate_encoder(4, 0); // Rotate CCW by 4 states (1 full tick back)
        check_avalon_read(16'd2, 2'b10);

        rotate_encoder(12, 0); // Rotate CCW by 12 states (3 full ticks back)
        // Since we were at 2, going back 3 should wrap around to 16'hFFFF
        check_avalon_read(16'hFFFF, 2'b10);

        // 5. Test Reset Mid-Operation
        $display("\n--- Testing Asynchronous Reset Behavior ---");
        rotate_encoder(2, 1); // Move halfway into a state
        reset = 1'b1;
        #(CLK_PERIOD * 2);
        reset = 1'b0;
        #(CLK_PERIOD * 2);
        
        // After reset, count should be 0 and direction 0
        check_avalon_read(16'd0, 2'b00);

        $display("\n============================================");
        $display(" Simulation Complete");
        $display("============================================");
        $finish;
    end

endmodule