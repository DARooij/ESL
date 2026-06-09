//
// Authors: D. Gaethofs, D.A. Rooijackers
// Title: Assignment 4 
// Brief: 
//

module quad_decod(
    input quadA, 
    input quadB, 
    input clk, 
    input rst,
    output wire [15:0] out, 
    output wire [1:0] direction_out
);

    reg [15:0] count = 0;
    reg [1:0] direction = 0;
    reg [1:0] curr_state = 2'b00;
    reg [1:0] prev_state = 2'b00;
    reg [1:0] sync = 2'b00;

always @ (posedge clk)
begin
    sync <= {quadB, quadA};
    curr_state <= sync;
end

always @ (posedge clk or posedge rst)
begin
    if (rst)
        begin
            count <= 0;
            direction <= 0;
            prev_state <= 2'b00;
        end 
    else 
        begin

            case (curr_state)
                2'b00:
                    begin
                        if (prev_state == 2'b01)
                            begin
                                count <= count + 1;
                                prev_state <= curr_state;
                                direction <= 2'b10; //right
                            end 
                        else if (prev_state == 2'b10)
                            begin
                            count <= count - 1;
                            prev_state <= curr_state;
                            direction <= 2'b01; //left 
                            end
                    end
                2'b01:
                    begin
                        if (prev_state == 2'b00)
                            begin
                                count <= count - 1;
                                prev_state <= curr_state;
                                direction <= 2'b01; //left
                            end 
                        else if (prev_state == 2'b11)
                            begin
                            count <= count + 1;
                            prev_state <= curr_state;
                            direction <= 2'b10; //right 
                            end
                    end
                2'b10:
                    begin
                        if (prev_state == 2'b00)
                            begin
                                count <= count + 1;
                                prev_state <= curr_state;
                                direction <= 2'b10; //right
                            end 
                        else if (prev_state == 2'b11)
                            begin
                            count <= count - 1;
                            prev_state <= curr_state;
                            direction <= 2'b01; //left 
                            end
                    end
                2'b11:
                    begin
                        if (prev_state == 2'b10)
                            begin
                                count <= count + 1;
                                prev_state <= curr_state;
                                direction <= 2'b10; //right
                            end 
                        else if (prev_state == 2'b01)
                            begin
                            count <= count - 1;
                            prev_state <= curr_state;
                            direction <= 2'b01; //left 
                            end
                    end
                default:
                begin
                end
            endcase
        end
end

assign out = count;
assign direction_out = direction;

endmodule