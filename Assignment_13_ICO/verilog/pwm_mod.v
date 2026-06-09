
module pwm_mod (
    input clk,
    input rst,
    input [7:0] duty_cycle,
    input [1:0] direction,
    output wire directionA,
    output wire directionB,
    output wire pwm_out
);

parameter PWM_FREQUENCY = 20000;
parameter CLOCK_FREQUENCY = 50000000;
parameter COUNTER_MAX = CLOCK_FREQUENCY / PWM_FREQUENCY;
parameter DUTY_CYCLE_MAX = 100;
parameter THRESHOLD_CONST = COUNTER_MAX / DUTY_CYCLE_MAX;

reg [11:0] counter = 0;

wire [11:0] safe_duty;

wire [11:0] counter_theshold;

reg pwm_reg;

assign safe_duty = (duty_cycle > 8'd100) ? 8'd100 : duty_cycle;

assign counter_theshold = THRESHOLD_CONST * safe_duty;

always @ (posedge clk or posedge rst)
begin
        
    if (rst)
        begin
            pwm_reg <= 0;
            counter <= 0;
        end
    else begin
        if (counter >= (COUNTER_MAX - 1))
        begin
            counter <= 0;
        end 
        else begin
            counter <= counter + 1;
        end

        if (counter < counter_theshold)
            pwm_reg <= 1;
        else
            pwm_reg <= 0;  
    end  
end

assign pwm_out = pwm_reg;

assign directionA = direction[1];
assign directionB = direction[0];

endmodule