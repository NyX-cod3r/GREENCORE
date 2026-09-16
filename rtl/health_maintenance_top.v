module health_maintenance_top (
    input clk,
    input rst,

    input [15:0] s1_pred_it, s2_pred_it, s3_pred_it,
    input [15:0] s1_pred_cooling, s2_pred_cooling, s3_pred_cooling,
    input [15:0] s1_pred_hvac, s2_pred_hvac, s3_pred_hvac,
    input [7:0]  s1_pred_temp, s2_pred_temp, s3_pred_temp,
    input [1:0]  s1_maint, s2_maint, s3_maint,

    input [15:0] s1_power, s2_power, s3_power,
    input        s1_reserve_trigger_la, s2_reserve_trigger_la, s3_reserve_trigger_la,
    input        s1_cooling_boost_la, s2_cooling_boost_la, s3_cooling_boost_la,

    input [1:0] source_server,
    input       emergency_power_restriction_trigger,

    output [7:0] s1_effective_temp, s2_effective_temp, s3_effective_temp,
    output [1:0] s1_thermal_status, s2_thermal_status, s3_thermal_status,
    output [1:0] s1_pred_thermal_status, s2_pred_thermal_status, s3_pred_thermal_status,
    output       s1_thermal_safe, s2_thermal_safe, s3_thermal_safe,
    output       s1_pred_thermal_safe, s2_pred_thermal_safe, s3_pred_thermal_safe,
    output       s1_thermal_redist_trigger, s2_thermal_redist_trigger, s3_thermal_redist_trigger,
    output       s1_cooling_malfunction, s2_cooling_malfunction, s3_cooling_malfunction,
    output       s1_maintenance_ok, s2_maintenance_ok, s3_maintenance_ok,
    output       s1_health_eligible, s2_health_eligible, s3_health_eligible,

    output [15:0] reserve_cooling_injection,
    output [15:0] reserve_charge_level,
    output [15:0] s1_reserve_injection, s2_reserve_injection, s3_reserve_injection,
    output        cooling_reserve_active
);

    wire s1_cooling_reserve_request, s2_cooling_reserve_request, s3_cooling_reserve_request;

    wire cooling_boost_required_combined =
        s1_cooling_boost_la || s2_cooling_boost_la || s3_cooling_boost_la ||
        s1_cooling_reserve_request || s2_cooling_reserve_request || s3_cooling_reserve_request;

    health_maintenance HM_S1 (
        .predicted_it_power(s1_pred_it),
        .predicted_cooling_power(s1_pred_cooling),
        .predicted_hvac_power(s1_pred_hvac),
        .predicted_temperature(s1_pred_temp),
        .reserve_cooling_boost(reserve_cooling_injection),
        .maintenance_risk(s1_maint),
        .effective_temperature(s1_effective_temp),
        .thermal_status(s1_thermal_status),
        .predicted_thermal_status(s1_pred_thermal_status),
        .thermal_safe(s1_thermal_safe),
        .predicted_thermal_safe(s1_pred_thermal_safe),
        .thermal_redistribution_trigger(s1_thermal_redist_trigger),
        .cooling_malfunction(s1_cooling_malfunction),
        .cooling_reserve_request(s1_cooling_reserve_request),
        .maintenance_ok(s1_maintenance_ok),
        .health_eligible(s1_health_eligible)
    );

    health_maintenance HM_S2 (
        .predicted_it_power(s2_pred_it),
        .predicted_cooling_power(s2_pred_cooling),
        .predicted_hvac_power(s2_pred_hvac),
        .predicted_temperature(s2_pred_temp),
        .reserve_cooling_boost(reserve_cooling_injection),
        .maintenance_risk(s2_maint),
        .effective_temperature(s2_effective_temp),
        .thermal_status(s2_thermal_status),
        .predicted_thermal_status(s2_pred_thermal_status),
        .thermal_safe(s2_thermal_safe),
        .predicted_thermal_safe(s2_pred_thermal_safe),
        .thermal_redistribution_trigger(s2_thermal_redist_trigger),
        .cooling_malfunction(s2_cooling_malfunction),
        .cooling_reserve_request(s2_cooling_reserve_request),
        .maintenance_ok(s2_maintenance_ok),
        .health_eligible(s2_health_eligible)
    );

    health_maintenance HM_S3 (
        .predicted_it_power(s3_pred_it),
        .predicted_cooling_power(s3_pred_cooling),
        .predicted_hvac_power(s3_pred_hvac),
        .predicted_temperature(s3_pred_temp),
        .reserve_cooling_boost(reserve_cooling_injection),
        .maintenance_risk(s3_maint),
        .effective_temperature(s3_effective_temp),
        .thermal_status(s3_thermal_status),
        .predicted_thermal_status(s3_pred_thermal_status),
        .thermal_safe(s3_thermal_safe),
        .predicted_thermal_safe(s3_pred_thermal_safe),
        .thermal_redistribution_trigger(s3_thermal_redist_trigger),
        .cooling_malfunction(s3_cooling_malfunction),
        .cooling_reserve_request(s3_cooling_reserve_request),
        .maintenance_ok(s3_maintenance_ok),
        .health_eligible(s3_health_eligible)
    );

    reserve_power_supply RESERVE (
        .s1_power(s1_power),
        .s2_power(s2_power),
        .s3_power(s3_power),
        .s1_reserve_trigger(s1_reserve_trigger_la),
        .s2_reserve_trigger(s2_reserve_trigger_la),
        .s3_reserve_trigger(s3_reserve_trigger_la),
        .source_server(source_server),
        .emergency_power_restriction_trigger(emergency_power_restriction_trigger),
        .cooling_boost_required(cooling_boost_required_combined),
        .clk(clk),
        .rst(rst),
        .s1_reserve_injection(s1_reserve_injection),
        .s2_reserve_injection(s2_reserve_injection),
        .s3_reserve_injection(s3_reserve_injection),
        .reserve_cooling_injection(reserve_cooling_injection),
        .reserve_charge_level(reserve_charge_level)
    );

    assign cooling_reserve_active = (reserve_cooling_injection != 16'd0);
endmodule
