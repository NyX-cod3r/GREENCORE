module power_allocation_engine (
    input clk,
    input rst,

    input [15:0] s1_pred_power, s2_pred_power, s3_pred_power,
    input [15:0] s1_pred_it, s2_pred_it, s3_pred_it,
    input [15:0] s1_pred_cooling, s2_pred_cooling, s3_pred_cooling,
    input [15:0] s1_pred_hvac, s2_pred_hvac, s3_pred_hvac,

    input        s1_reserve_trigger, s2_reserve_trigger, s3_reserve_trigger,
    input [15:0] s1_reserve_injection, s2_reserve_injection, s3_reserve_injection,

    input [1:0] source_server,
    input [1:0] receiver_server,
    input       redistribution_enable,
    input [15:0] redistribution_amount,
    input       emergency_power_restriction_trigger,
    input       cooling_boost_required,

    output reg [15:0] s1_allocated, s2_allocated, s3_allocated,
    output reg [15:0] s1_extra_cooling, s2_extra_cooling, s3_extra_cooling,
    output reg        full_cooling_engage
);
    localparam [15:0] RAMP_STEP          = 16'd15;
    localparam [15:0] RESTRICTION_TARGET = 16'd750;
    localparam [15:0] MAX_POWER          = 16'd1000;
    localparam [1:0]  NONE = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;

    reg [15:0] s1_target, s2_target, s3_target;
    reg s1_is_restriction, s2_is_restriction, s3_is_restriction;

    function [15:0] saturating_add;
        input [15:0] base_value;
        input [15:0] increment;
        reg [16:0] total;
        begin
            total = {1'b0, base_value} + {1'b0, increment};
            saturating_add = (total > {1'b0, MAX_POWER}) ? MAX_POWER : total[15:0];
        end
    endfunction

    always @(*) begin
        s1_target = s1_pred_power;
        s2_target = s2_pred_power;
        s3_target = s3_pred_power;
        s1_is_restriction = 1'b0;
        s2_is_restriction = 1'b0;
        s3_is_restriction = 1'b0;

        if (source_server == S1 && redistribution_enable)
            s1_target = (redistribution_amount >= s1_pred_power) ? 16'd0 : (s1_pred_power - redistribution_amount);
        else if (receiver_server == S1 && redistribution_enable)
            s1_target = saturating_add(s1_pred_power, redistribution_amount);
        else if (source_server == S1 && emergency_power_restriction_trigger) begin
            s1_target = (s1_pred_power > RESTRICTION_TARGET) ? RESTRICTION_TARGET : s1_pred_power;
            s1_is_restriction = (s1_pred_power > RESTRICTION_TARGET);
        end else if (s1_reserve_trigger)
            s1_target = saturating_add(s1_pred_power, s1_reserve_injection);

        if (source_server == S2 && redistribution_enable)
            s2_target = (redistribution_amount >= s2_pred_power) ? 16'd0 : (s2_pred_power - redistribution_amount);
        else if (receiver_server == S2 && redistribution_enable)
            s2_target = saturating_add(s2_pred_power, redistribution_amount);
        else if (source_server == S2 && emergency_power_restriction_trigger) begin
            s2_target = (s2_pred_power > RESTRICTION_TARGET) ? RESTRICTION_TARGET : s2_pred_power;
            s2_is_restriction = (s2_pred_power > RESTRICTION_TARGET);
        end else if (s2_reserve_trigger)
            s2_target = saturating_add(s2_pred_power, s2_reserve_injection);

        if (source_server == S3 && redistribution_enable)
            s3_target = (redistribution_amount >= s3_pred_power) ? 16'd0 : (s3_pred_power - redistribution_amount);
        else if (receiver_server == S3 && redistribution_enable)
            s3_target = saturating_add(s3_pred_power, redistribution_amount);
        else if (source_server == S3 && emergency_power_restriction_trigger) begin
            s3_target = (s3_pred_power > RESTRICTION_TARGET) ? RESTRICTION_TARGET : s3_pred_power;
            s3_is_restriction = (s3_pred_power > RESTRICTION_TARGET);
        end else if (s3_reserve_trigger)
            s3_target = saturating_add(s3_pred_power, s3_reserve_injection);

        // Clamp all targets to the project maximum.
        if (s1_target > MAX_POWER) s1_target = MAX_POWER;
        if (s2_target > MAX_POWER) s2_target = MAX_POWER;
        if (s3_target > MAX_POWER) s3_target = MAX_POWER;
    end

    function [15:0] calc_extra_cooling;
        input [15:0] pred_it, pred_cooling, pred_hvac;
        reg [31:0] heat_term, required_total, current_total;
        begin
            // Simple deterministic cooling estimate for the simulation.
            heat_term = (70 * pred_it) / 1000;
            if (heat_term > 30) begin
                required_total = ((heat_term - 30) * 10) / 3;
                current_total = pred_cooling + pred_hvac;
                calc_extra_cooling =
                    (required_total > current_total) ?
                    (required_total - current_total) : 16'd0;
            end else begin
                calc_extra_cooling = 16'd0;
            end
        end
    endfunction

    wire [15:0] s1_cool_calc = calc_extra_cooling(s1_pred_it, s1_pred_cooling, s1_pred_hvac);
    wire [15:0] s2_cool_calc = calc_extra_cooling(s2_pred_it, s2_pred_cooling, s2_pred_hvac);
    wire [15:0] s3_cool_calc = calc_extra_cooling(s3_pred_it, s3_pred_cooling, s3_pred_hvac);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s1_allocated <= 16'd0;
            s2_allocated <= 16'd0;
            s3_allocated <= 16'd0;
            s1_extra_cooling <= 16'd0;
            s2_extra_cooling <= 16'd0;
            s3_extra_cooling <= 16'd0;
            full_cooling_engage <= 1'b0;
        end else begin
            if (s1_target > s1_allocated)
                s1_allocated <= ((s1_target - s1_allocated) > RAMP_STEP) ? (s1_allocated + RAMP_STEP) : s1_target;
            else if (s1_target < s1_allocated)
                s1_allocated <= ((s1_allocated - s1_target) > RAMP_STEP) ? (s1_allocated - RAMP_STEP) : s1_target;

            if (s2_target > s2_allocated)
                s2_allocated <= ((s2_target - s2_allocated) > RAMP_STEP) ? (s2_allocated + RAMP_STEP) : s2_target;
            else if (s2_target < s2_allocated)
                s2_allocated <= ((s2_allocated - s2_target) > RAMP_STEP) ? (s2_allocated - RAMP_STEP) : s2_target;

            if (s3_target > s3_allocated)
                s3_allocated <= ((s3_target - s3_allocated) > RAMP_STEP) ? (s3_allocated + RAMP_STEP) : s3_target;
            else if (s3_target < s3_allocated)
                s3_allocated <= ((s3_allocated - s3_target) > RAMP_STEP) ? (s3_allocated - RAMP_STEP) : s3_target;

            s1_extra_cooling <= (source_server == S1 && cooling_boost_required) ? s1_cool_calc : 16'd0;
            s2_extra_cooling <= (source_server == S2 && cooling_boost_required) ? s2_cool_calc : 16'd0;
            s3_extra_cooling <= (source_server == S3 && cooling_boost_required) ? s3_cool_calc : 16'd0;

            full_cooling_engage <= s1_is_restriction || s2_is_restriction || s3_is_restriction;
        end
    end
endmodule
