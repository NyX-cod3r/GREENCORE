module redistribution_manager (
    input  [15:0] s1_pred_power, s2_pred_power, s3_pred_power,
    input  [7:0]  s1_pred_temp, s2_pred_temp, s3_pred_temp,

    input         s1_pred_high, s2_pred_high, s3_pred_high,
    input         s1_thermal_redist_trigger,
    input         s2_thermal_redist_trigger,
    input         s3_thermal_redist_trigger,

    input  [1:0]  best_receiver,

    output [1:0]  source_server,
    output [1:0]  receiver_server,
    output        redistribution_enable,
    output [15:0] redistribution_amount,
    output        emergency_power_restriction_trigger,
    output        cooling_boost_required
);
    localparam [1:0] NONE = 2'b00;
    localparam [1:0] S1   = 2'b01;
    localparam [1:0] S2   = 2'b10;
    localparam [1:0] S3   = 2'b11;

    localparam [15:0] SOURCE_THRESHOLD     = 16'd750;
    localparam [15:0] RECEIVER_TARGET      = 16'd750;
    localparam [15:0] MIN_SOURCE_POWER     = 16'd400;
    localparam [7:0]  COOLING_TEMP_LIMIT   = 8'd70;

    wire s1_source_trigger = s1_pred_high || s1_thermal_redist_trigger;
    wire s2_source_trigger = s2_pred_high || s2_thermal_redist_trigger;
    wire s3_source_trigger = s3_pred_high || s3_thermal_redist_trigger;

    wire [16:0] s1_severity = s1_source_trigger ?
        ({1'b0, s1_pred_power} + ({9'd0, s1_pred_temp} * 17'd7)) : 17'd0;
    wire [16:0] s2_severity = s2_source_trigger ?
        ({1'b0, s2_pred_power} + ({9'd0, s2_pred_temp} * 17'd7)) : 17'd0;
    wire [16:0] s3_severity = s3_source_trigger ?
        ({1'b0, s3_pred_power} + ({9'd0, s3_pred_temp} * 17'd7)) : 17'd0;

    function [1:0] pick_worst;
        input [16:0] score1, score2, score3;
        begin
            if ((score1 == 0) && (score2 == 0) && (score3 == 0))
                pick_worst = NONE;
            else if ((score1 >= score2) && (score1 >= score3))
                pick_worst = S1;
            else if (score2 >= score3)
                pick_worst = S2;
            else
                pick_worst = S3;
        end
    endfunction

    assign source_server = pick_worst(s1_severity, s2_severity, s3_severity);
    assign receiver_server = best_receiver;

    wire [15:0] source_power =
        (source_server == S1) ? s1_pred_power :
        (source_server == S2) ? s2_pred_power :
        (source_server == S3) ? s3_pred_power : 16'd0;

    wire [7:0] source_temp =
        (source_server == S1) ? s1_pred_temp :
        (source_server == S2) ? s2_pred_temp :
        (source_server == S3) ? s3_pred_temp : 8'd0;

    wire [15:0] receiver_power =
        (receiver_server == S1) ? s1_pred_power :
        (receiver_server == S2) ? s2_pred_power :
        (receiver_server == S3) ? s3_pred_power : 16'd0;

    assign cooling_boost_required =
        (source_server != NONE) &&
        (source_temp >= COOLING_TEMP_LIMIT);

    // Source is reduced toward 750 W, not 700 W.
    wire [15:0] needed_reduction =
        (source_power > SOURCE_THRESHOLD) ?
        (source_power - SOURCE_THRESHOLD) : 16'd0;

    // Receiver must have been selected upstream only if it was <600 W.
    // Once selected, do not drive it beyond 750 W.
    wire [15:0] receiver_headroom =
        (receiver_power < RECEIVER_TARGET) ?
        (RECEIVER_TARGET - receiver_power) : 16'd0;

    // Source cannot be reduced below 400 W.
    wire [15:0] max_allowed_by_floor =
        (source_power > MIN_SOURCE_POWER) ?
        (source_power - MIN_SOURCE_POWER) : 16'd0;

    wire [15:0] amount_1 =
        (needed_reduction < receiver_headroom) ?
        needed_reduction : receiver_headroom;

    wire [15:0] final_amount =
        (amount_1 < max_allowed_by_floor) ?
        amount_1 : max_allowed_by_floor;

    assign redistribution_enable =
        (source_server != NONE) &&
        (best_receiver != NONE) &&
        (source_server != best_receiver) &&
        (final_amount != 16'd0);

    // No receiver -> do NOT force an unsafe transfer.
    assign emergency_power_restriction_trigger =
        (source_server != NONE) &&
        (best_receiver == NONE) &&
        ((source_power > SOURCE_THRESHOLD) ||
         (source_temp >= COOLING_TEMP_LIMIT));

    assign redistribution_amount =
        redistribution_enable ? final_amount : 16'd0;
endmodule
