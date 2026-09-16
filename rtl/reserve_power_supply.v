module reserve_power_supply (
    input [15:0] s1_power, s2_power, s3_power,
    input        s1_reserve_trigger, s2_reserve_trigger, s3_reserve_trigger,
    input [1:0]  source_server,
    input        emergency_power_restriction_trigger,
    input        cooling_boost_required,
    input        clk,
    input        rst,
    output reg [15:0] s1_reserve_injection, s2_reserve_injection, s3_reserve_injection,
    output reg [15:0] reserve_cooling_injection,
    output reg [15:0] reserve_charge_level
);
    localparam [15:0] RAMP_STEP          = 16'd15;
    localparam [15:0] RESTRICTION_TARGET = 16'd750;
    localparam [15:0] RESERVE_MAX        = 16'd10000;
    localparam [1:0]  NONE = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;

    wire [15:0] restrict_source_power =
        (source_server == S1) ? s1_power :
        (source_server == S2) ? s2_power :
        (source_server == S3) ? s3_power : 16'd0;

    wire [15:0] this_frame_cut =
        (emergency_power_restriction_trigger && (restrict_source_power > RESTRICTION_TARGET))
        ? (((restrict_source_power - RESTRICTION_TARGET) > RAMP_STEP)
            ? RAMP_STEP
            : (restrict_source_power - RESTRICTION_TARGET))
        : 16'd0;

    wire [15:0] s1_want = s1_reserve_trigger ? RAMP_STEP : 16'd0;
    wire [15:0] s2_want = s2_reserve_trigger ? RAMP_STEP : 16'd0;
    wire [15:0] s3_want = s3_reserve_trigger ? RAMP_STEP : 16'd0;
    wire [15:0] cooling_want = cooling_boost_required ? RAMP_STEP : 16'd0;

    reg [15:0] s1_inj_c, s2_inj_c, s3_inj_c, cool_inj_c, remaining;

    always @(*) begin
        remaining = reserve_charge_level;

        s1_inj_c = (remaining >= s1_want) ? s1_want : remaining;
        remaining = remaining - s1_inj_c;

        s2_inj_c = (remaining >= s2_want) ? s2_want : remaining;
        remaining = remaining - s2_inj_c;

        s3_inj_c = (remaining >= s3_want) ? s3_want : remaining;
        remaining = remaining - s3_inj_c;

        cool_inj_c = (remaining >= cooling_want) ? cooling_want : remaining;
        remaining = remaining - cool_inj_c;
    end

    // FIX: candidate next charge value is computed fresh (blocking, into a
    // 17-bit temp reg) each cycle, then clamped BEFORE it is ever written to
    // reserve_charge_level. The previous version's clamp read the stale
    // (pre-cycle) registered value via a non-blocking-assignment race, so it
    // never actually fired -- this_frame_cut (restriction recharge) could
    // push reserve_charge_level above RESERVE_MAX with nothing to bring it
    // back down, which would then make safety_check's reserve_valid (and
    // therefore final_valid) incorrectly stay low for the rest of the run.
    // Injections are already capped against `remaining` above, so the
    // subtraction side can never underflow -- only the addition side needed
    // the fix.
    reg [16:0] charge_candidate;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s1_reserve_injection  <= 16'd0;
            s2_reserve_injection  <= 16'd0;
            s3_reserve_injection  <= 16'd0;
            reserve_cooling_injection <= 16'd0;
            reserve_charge_level  <= RESERVE_MAX;
        end else begin
            s1_reserve_injection <= s1_inj_c;
            s2_reserve_injection <= s2_inj_c;
            s3_reserve_injection <= s3_inj_c;
            reserve_cooling_injection <= cool_inj_c;

            charge_candidate = {1'b0, reserve_charge_level} + {1'b0, this_frame_cut}
                              - {1'b0, s1_inj_c} - {1'b0, s2_inj_c}
                              - {1'b0, s3_inj_c} - {1'b0, cool_inj_c};

            reserve_charge_level <= (charge_candidate > {1'b0, RESERVE_MAX})
                                     ? RESERVE_MAX
                                     : charge_candidate[15:0];
        end
    end
endmodule
