//
// Authors: D. Gaethofs, D.A. Rooijackers
// Title: Assignment 4 
// Brief: Quadrature Decoder 
//

module quad_decod(
    input quadA, 
    input quadB, 
    input clk, 
    output reg [15:0] count = 0, 
    output reg [1:0] direction = 0
);

    reg [1:0] curr_state;
    reg [1:0] prev_state = 2'b00;

always @ (posedge clk)
begin
    
    curr_state <= {quadA, quadB};

    case (curr_state)
        2'b00:
            begin
                if (prev_state == 2'b01)
                    begin
                        count <= count + 1;
                        prev_state <= curr_state;
                        direction = 2'b01; //right
                    end 
                else if (prev_state == 2'b10)
                    begin
                       count <= count - 1;
                       prev_state <= curr_state;
                       direction = 2'b10; //left 
                    end
            end
        2'b01:
            begin
                if (prev_state == 2'b00)
                    begin
                        count <= count - 1;
                        prev_state <= curr_state;
                        direction = 2'b10; //left
                    end 
                else if (prev_state == 2'b11)
                    begin
                       count <= count + 1;
                       prev_state <= curr_state;
                       direction = 2'b01; //right 
                    end
            end
        2'b10:
            begin
                if (prev_state == 2'b00)
                    begin
                        count <= count + 1;
                        prev_state <= curr_state;
                        direction = 2'b10; //right
                    end 
                else if (prev_state == 2'b11)
                    begin
                       count <= count - 1;
                       prev_state <= curr_state;
                       direction = 2'b01; //left 
                    end
            end
        2'b11:
            begin
                if (prev_state == 2'b10)
                    begin
                        count <= count + 1;
                        prev_state <= curr_state;
                        direction = 2'b10; //right
                    end 
                else if (prev_state == 2'b01)
                    begin
                       count <= count - 1;
                       prev_state <= curr_state;
                       direction = 2'b01; //left 
                    end
            end
    endcase

end

endmodule