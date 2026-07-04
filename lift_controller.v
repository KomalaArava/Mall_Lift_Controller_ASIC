// =================================================================
// DESIGN UNIT: lift_controller.v
// TYPE: RTL Hardware Description
// ENCODING: IEEE 1364-2001 Verilog Standard
// =================================================================

module lift_controller (
    input wire clk,                  // System clock
    input wire rst_n,                // Asynchronous active-low reset
    input wire [1:0] req_floor,      // Requested floor from user (0, 1, or 2)
    input wire req_valid,            // Asserted high when a new button is pressed

    output reg [1:0] current_floor,  // Current location binary output
    output reg [1:0] motor_state,    // 00=Stop, 01=Up, 10=Down
    output reg [1:0] door_state      // 00=Closed, 01=Open, 10=Closing
);

// FSM State Encodings
parameter STATE_IDLE    = 3'b000;
parameter STATE_MOV_UP  = 3'b001;
parameter STATE_MOV_DN  = 3'b010;
parameter STATE_DOOR_OP = 3'b011;
parameter STATE_DOOR_CL = 3'b100;

// Internal State Registers
reg [2:0] current_state;
reg [2:0] next_state;

// Internal register to lock and store requested destination floor
reg [1:0] target_floor;

// Step counter for transitions (simulates travel and door times)
reg [3:0] delay_counter;

// -------------------------------------------------------------
// BLOCK 1: Sequential Process (State & Internal Registers)
// -------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= STATE_IDLE;
        current_floor <= 2'b00;
        target_floor <= 2'b00;
        delay_counter <= 4'd0;
    end
    else begin
        current_state <= next_state;

        // Latch new target floor if valid request arrives while idle
        if (current_state == STATE_IDLE && req_valid)
            target_floor <= req_floor;

        // Simulation Counter logic
        if (current_state != next_state) begin
            delay_counter <= 4'd0;

            // Update floor indicator when reaching destinations
            if (current_state == STATE_MOV_UP)
                current_floor <= current_floor + 1'b1;

            if (current_state == STATE_MOV_DN)
                current_floor <= current_floor - 1'b1;
        end
        else begin
            delay_counter <= delay_counter + 1'b1;
        end
    end
end

// -------------------------------------------------------------
// BLOCK 2: Combinational Process (Next State Logic)
// -------------------------------------------------------------
always @(*) begin
    case (current_state)

        STATE_IDLE: begin
            if (req_valid && (req_floor > current_floor))
                next_state = STATE_MOV_UP;
            else if (req_valid && (req_floor < current_floor))
                next_state = STATE_MOV_DN;
            else if (req_valid && (req_floor == current_floor))
                next_state = STATE_DOOR_OP;
            else
                next_state = STATE_IDLE;
        end

        STATE_MOV_UP: begin
            // Simulate time taken to move up one floor (3 cycles)
            if (delay_counter == 4'd3) begin
                if (current_floor + 1'b1 == target_floor)
                    next_state = STATE_DOOR_OP;
                else
                    next_state = STATE_MOV_UP;
            end
            else begin
                next_state = STATE_MOV_UP;
            end
        end

        STATE_MOV_DN: begin
            // Simulate time taken to move down one floor (3 cycles)
            if (delay_counter == 4'd3) begin
                if (current_floor - 1'b1 == target_floor)
                    next_state = STATE_DOOR_OP;
                else
                    next_state = STATE_MOV_DN;
            end
            else begin
                next_state = STATE_MOV_DN;
            end
        end

        STATE_DOOR_OP: begin
            // Hold doors open for 3 cycles
            if (delay_counter == 4'd3)
                next_state = STATE_DOOR_CL;
            else
                next_state = STATE_DOOR_OP;
        end

        STATE_DOOR_CL: begin
            // Doors take 2 cycles to close
            if (delay_counter == 4'd2)
                next_state = STATE_IDLE;
            else
                next_state = STATE_DOOR_CL;
        end

        default: next_state = STATE_IDLE;

    endcase
end

// -------------------------------------------------------------
// BLOCK 3: Combinational Process (Output Drivers)
// -------------------------------------------------------------
always @(*) begin

    // Safe Defaults
    motor_state = 2'b00;
    door_state  = 2'b00;

    case (current_state)

        STATE_IDLE: begin
            motor_state = 2'b00;
            door_state  = 2'b00;
        end

        STATE_MOV_UP: begin
            motor_state = 2'b01;
            door_state  = 2'b00;
        end

        STATE_MOV_DN: begin
            motor_state = 2'b10;
            door_state  = 2'b00;
        end

        STATE_DOOR_OP: begin
            motor_state = 2'b00;
            door_state  = 2'b01;
        end

        STATE_DOOR_CL: begin
            motor_state = 2'b00;
            door_state  = 2'b10;
        end

    endcase
end

endmodule