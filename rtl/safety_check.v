module safety_check (
    input [15:0] s1_allocated, s2_allocated, s3_allocated,
    input [15:0] reserve_charge_level,
    input [15:0] s1_reserve_injection, s2_reserve_injection, s3_reserve_injection,
    input        s1_reserve_trigger, s2_reserve_trigger, s3_reserve_trigger,
    input        full_cooling_engage,
    input [1:0]  source_server, receiver_server,
    input        redistribution_enable,
    input        emergency_power_restriction_trigger,

    output       s1_allocation_valid, s2_allocation_valid, s3_allocation_valid,
    output       reserve_valid,
    output       reserve_injection_consistent,
    output       redistribution_consistent,
    output       restriction_consistent,
    output       final_valid
);
    localparam [1:0] NONE = 2'b00;
    localparam [15:0] MAX_POWER   = 16'd1000;
    localparam [15:0] RESERVE_MAX = 16'd10000;

    assign s1_allocation_valid = (s1_allocated <= MAX_POWER);
    assign s2_allocation_valid = (s2_allocated <= MAX_POWER);
    assign s3_allocation_valid = (s3_allocated <= MAX_POWER);

    assign reserve_valid = (reserve_charge_level <= RESERVE_MAX);

    assign reserve_injection_consistent =
        ((s1_reserve_trigger == 1'b1) || (s1_reserve_injection == 16'd0)) &&
        ((s2_reserve_trigger == 1'b1) || (s2_reserve_injection == 16'd0)) &&
        ((s3_reserve_trigger == 1'b1) || (s3_reserve_injection == 16'd0));

    assign redistribution_consistent =
        (!redistribution_enable) ||
        ((source_server != NONE) &&
         (receiver_server != NONE) &&
         (source_server != receiver_server));

    assign restriction_consistent =
        (!emergency_power_restriction_trigger) || full_cooling_engage;

    assign final_valid =
        s1_allocation_valid &&
        s2_allocation_valid &&
        s3_allocation_valid &&
        reserve_valid &&
        reserve_injection_consistent &&
        redistribution_consistent &&
        restriction_consistent;
endmodule
