module health_maintenance (
    input  [15:0] predicted_it_power,
    input  [15:0] predicted_cooling_power,
    input  [15:0] predicted_hvac_power,
    input  [7:0]  predicted_temperature,
    input  [15:0] reserve_cooling_boost,
    input  [1:0]  maintenance_risk,

    output [7:0]  effective_temperature,
    output [1:0]  thermal_status,
    output [1:0]  predicted_thermal_status,
    output        thermal_safe,
    output        predicted_thermal_safe,
    output        thermal_redistribution_trigger,
    output        cooling_malfunction,
    output        cooling_reserve_request,
    output        maintenance_ok,
    output        health_eligible
);
    localparam [1:0] THERMAL_SAFE     = 2'b00;
    localparam [1:0] THERMAL_WARNING  = 2'b01;
    localparam [1:0] THERMAL_CRITICAL = 2'b10;

    localparam [1:0] MAINT_NORMAL   = 2'b00;
    localparam [1:0] MAINT_WATCH    = 2'b01;
    localparam [1:0] MAINT_WARNING  = 2'b10;
    localparam [1:0] MAINT_CRITICAL = 2'b11;

    localparam [7:0] TEMP_WARNING  = 8'd70;
    localparam [7:0] TEMP_CRITICAL = 8'd85;

    // Simple software-modelled reserve cooling effect:
    // every 20 W of reserve cooling represents 1 C reduction.
    wire [15:0] temp_reduction = reserve_cooling_boost / 16'd20;
    wire signed [16:0] temp_after_boost =
        $signed({1'b0, predicted_temperature}) - $signed({1'b0, temp_reduction});

    assign effective_temperature =
        (temp_after_boost <= 0) ? 8'd0 :
        (temp_after_boost >= 100) ? 8'd100 : temp_after_boost[7:0];

    function [1:0] classify_thermal;
        input [7:0] t;
        begin
            if      (t < TEMP_WARNING) classify_thermal = THERMAL_SAFE;
            else if (t < TEMP_CRITICAL) classify_thermal = THERMAL_WARNING;
            else                        classify_thermal = THERMAL_CRITICAL;
        end
    endfunction

    assign predicted_thermal_status = classify_thermal(predicted_temperature);
    assign thermal_status           = classify_thermal(effective_temperature);

    assign predicted_thermal_safe = (predicted_thermal_status != THERMAL_CRITICAL);
    assign thermal_safe           = (thermal_status != THERMAL_CRITICAL);

    assign thermal_redistribution_trigger =
        (thermal_status == THERMAL_WARNING) ||
        (thermal_status == THERMAL_CRITICAL);

    // Predictive cooling malfunction check.
    // Only predicted values are used.
    assign cooling_malfunction =
        ((3 * (predicted_cooling_power + predicted_hvac_power)) < 16'd80) &&
        (predicted_it_power > 16'd600);

    assign cooling_reserve_request =
        cooling_malfunction || (thermal_status == THERMAL_CRITICAL);

    assign maintenance_ok =
        ((maintenance_risk == MAINT_NORMAL) ||
         (maintenance_risk == MAINT_WATCH)) &&
        !cooling_malfunction;

    assign health_eligible = thermal_safe && maintenance_ok;
endmodule
