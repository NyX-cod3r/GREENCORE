module priority_eligibility (
    input  [15:0] s1_pred_power, s2_pred_power, s3_pred_power,
    input         s1_health_eligible, s2_health_eligible, s3_health_eligible,
    input  [7:0]   s1_pred_temp, s2_pred_temp, s3_pred_temp,
    input  [1:0]   mode_select,

    output        s1_receiver_eligible, s2_receiver_eligible, s3_receiver_eligible,
    output [1:0]  best_receiver
);
    localparam [1:0] NONE = 2'b00;
    localparam [1:0] S1   = 2'b01;
    localparam [1:0] S2   = 2'b10;
    localparam [1:0] S3   = 2'b11;

    localparam [15:0] RECEIVER_LIMIT = 16'd600;
    localparam [7:0]  TEMP_LIMIT     = 8'd70;

    assign s1_receiver_eligible =
        (s1_pred_power < RECEIVER_LIMIT) &&
        (s1_pred_temp < TEMP_LIMIT) &&
        s1_health_eligible;

    assign s2_receiver_eligible =
        (s2_pred_power < RECEIVER_LIMIT) &&
        (s2_pred_temp < TEMP_LIMIT) &&
        s2_health_eligible;

    assign s3_receiver_eligible =
        (s3_pred_power < RECEIVER_LIMIT) &&
        (s3_pred_temp < TEMP_LIMIT) &&
        s3_health_eligible;

    // mode 00 = maximum headroom (lowest power wins)
    // mode 01 = coolest eligible server wins
    // mode 10 = fixed S1 > S2 > S3 priority
    // mode 11 = fixed S3 > S2 > S1 priority
    wire [15:0] s1_headroom_score = s1_receiver_eligible ? (16'd600 - s1_pred_power) : 16'd0;
    wire [15:0] s2_headroom_score = s2_receiver_eligible ? (16'd600 - s2_pred_power) : 16'd0;
    wire [15:0] s3_headroom_score = s3_receiver_eligible ? (16'd600 - s3_pred_power) : 16'd0;

    function [1:0] pick_headroom;
        input [15:0] a, b, c;
        begin
            if ((a == 0) && (b == 0) && (c == 0))
                pick_headroom = NONE;
            else if ((a >= b) && (a >= c))
                pick_headroom = S1;
            else if (b >= c)
                pick_headroom = S2;
            else
                pick_headroom = S3;
        end
    endfunction

    function [1:0] pick_coolest;
        input [7:0] t1, t2, t3;
        input e1, e2, e3;
        begin
            if (!e1 && !e2 && !e3)
                pick_coolest = NONE;
            else if (e1 && (!e2 || (t1 <= t2)) && (!e3 || (t1 <= t3)))
                pick_coolest = S1;
            else if (e2 && (!e3 || (t2 <= t3)))
                pick_coolest = S2;
            else
                pick_coolest = S3;
        end
    endfunction

    function [1:0] pick_fixed_priority;
        input [1:0] mode;
        input e1, e2, e3;
        begin
            if (!e1 && !e2 && !e3)
                pick_fixed_priority = NONE;
            else if (mode == 2'b10) begin
                if (e1) pick_fixed_priority = S1;
                else if (e2) pick_fixed_priority = S2;
                else pick_fixed_priority = S3;
            end else begin
                if (e3) pick_fixed_priority = S3;
                else if (e2) pick_fixed_priority = S2;
                else pick_fixed_priority = S1;
            end
        end
    endfunction

    assign best_receiver =
        (mode_select == 2'b00) ? pick_headroom(s1_headroom_score, s2_headroom_score, s3_headroom_score) :
        (mode_select == 2'b01) ? pick_coolest(s1_pred_temp, s2_pred_temp, s3_pred_temp,
                                               s1_receiver_eligible, s2_receiver_eligible, s3_receiver_eligible) :
                                 pick_fixed_priority(mode_select, s1_receiver_eligible,
                                                     s2_receiver_eligible, s3_receiver_eligible);
endmodule
