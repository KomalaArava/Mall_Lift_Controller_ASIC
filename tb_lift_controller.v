`timescale 1ns/1ps

module tb_lift_controller;

    reg clk;
    reg rst_n;
    reg [1:0] req_floor;
    reg req_valid;

    wire [1:0] current_floor;
    wire [1:0] motor_state;
    wire [1:0] door_state;

    // Instantiate Unit Under Test (UUT)
    lift_controller uut (
        .clk(clk),
        .rst_n(rst_n),
        .req_floor(req_floor),
        .req_valid(req_valid),
        .current_floor(current_floor),
        .motor_state(motor_state),
        .door_state(door_state)
    );

    // Clock Generation (10 ns period)
    always begin
        #5 clk = ~clk;
    end

    // Test Scenarios
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        req_floor = 2'b00;
        req_valid = 0;

        // Release reset
        #20 rst_n = 1;

        // Scenario 1: Move from Floor 0 to Floor 2
        #15;
        req_floor = 2'd2;
        req_valid = 1;
        #10;
        req_valid = 0;

        // Wait for elevator operation
        #150;

        // Scenario 2: Move from Floor 2 to Floor 1
        req_floor = 2'd1;
        req_valid = 1;
        #10;
        req_valid = 0;

        #100;

        $display("[LIFT_VERIFICATION] All Mall scenarios simulated successfully.");
        $finish;
    end

    // Monitor Signals
    initial begin
        $monitor("Time=%0dns | Reset=%b | TargetReq=%d | Car Floor=%d | Motor=%b | Door=%b",
                 $time, rst_n, req_floor, current_floor, motor_state, door_state);
    end

    // Waveform Dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_lift_controller);
    end

endmodule
