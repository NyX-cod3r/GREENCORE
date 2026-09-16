module green_core_controller (
    input clk,
    input rst,

    input [15:0] s1_pred_it, s1_pred_cooling, s1_pred_hvac, s1_pred_pump,
    input [15:0] s2_pred_it, s2_pred_cooling, s2_pred_hvac, s2_pred_pump,
    input [15:0] s3_pred_it, s3_pred_cooling, s3_pred_hvac, s3_pred_pump,

    input [7:0]  s1_pred_temp, s2_pred_temp, s3_pred_temp,
    input [1:0]  s1_maint, s2_maint, s3_maint,
    input [1:0]  mode_select,

    output [15:0] s1_pred_total, s2_pred_total, s3_pred_total,
    output [2:0]  s1_pred_zone, s2_pred_zone, s3_pred_zone,
    output        s1_pred_high, s2_pred_high, s3_pred_high,

    output [7:0]  s1_effective_temp, s2_effective_temp, s3_effective_temp,
    output        s1_health_eligible, s2_health_eligible, s3_health_eligible,
    output        s1_receiver_eligible, s2_receiver_eligible, s3_receiver_eligible,

    output [1:0]  best_receiver,
    output [1:0]  source_server, receiver_server,
    output        redistribution_enable,
    output [15:0] redistribution_amount,
    output        emergency_power_restriction_trigger,
    output        cooling_boost_required,

    output [15:0] s1_reserve_injection, s2_reserve_injection, s3_reserve_injection,
    output [15:0] reserve_cooling_injection,
    output [15:0] reserve_charge_level,

    output [15:0] s1_allocated, s2_allocated, s3_allocated,
    output [15:0] s1_extra_cooling, s2_extra_cooling, s3_extra_cooling,
    output        full_cooling_engage,

    output        s1_allocation_valid, s2_allocation_valid, s3_allocation_valid,
    output        reserve_valid,
    output        reserve_injection_consistent,
    output        redistribution_consistent,
    output        restriction_consistent,
    output        final_valid
);

    wire s1_reserve_trigger, s2_reserve_trigger, s3_reserve_trigger;
    wire s1_cooling_boost_la, s2_cooling_boost_la, s3_cooling_boost_la;

    wire [1:0] s1_thermal_status, s2_thermal_status, s3_thermal_status;
    wire [1:0] s1_pred_thermal_status, s2_pred_thermal_status, s3_pred_thermal_status;
    wire s1_thermal_safe, s2_thermal_safe, s3_thermal_safe;
    wire s1_pred_thermal_safe, s2_pred_thermal_safe, s3_pred_thermal_safe;
    wire s1_thermal_redist_trigger, s2_thermal_redist_trigger, s3_thermal_redist_trigger;
    wire s1_cooling_malfunction, s2_cooling_malfunction, s3_cooling_malfunction;
    wire s1_maintenance_ok, s2_maintenance_ok, s3_maintenance_ok;

    load_analyzer_top LA (
        .s1_pred_it(s1_pred_it), .s1_pred_cooling(s1_pred_cooling), .s1_pred_hvac(s1_pred_hvac), .s1_pred_pump(s1_pred_pump),
        .s2_pred_it(s2_pred_it), .s2_pred_cooling(s2_pred_cooling), .s2_pred_hvac(s2_pred_hvac), .s2_pred_pump(s2_pred_pump),
        .s3_pred_it(s3_pred_it), .s3_pred_cooling(s3_pred_cooling), .s3_pred_hvac(s3_pred_hvac), .s3_pred_pump(s3_pred_pump),
        .s1_pred_total(s1_pred_total), .s2_pred_total(s2_pred_total), .s3_pred_total(s3_pred_total),
        .s1_pred_zone(s1_pred_zone), .s2_pred_zone(s2_pred_zone), .s3_pred_zone(s3_pred_zone),
        .s1_pred_high(s1_pred_high), .s2_pred_high(s2_pred_high), .s3_pred_high(s3_pred_high),
        .s1_reserve_trigger(s1_reserve_trigger), .s2_reserve_trigger(s2_reserve_trigger), .s3_reserve_trigger(s3_reserve_trigger),
        .s1_cooling_boost(s1_cooling_boost_la), .s2_cooling_boost(s2_cooling_boost_la), .s3_cooling_boost(s3_cooling_boost_la)
    );

    // Temporary wires for redistribution outputs, used by Health+Maintenance
    // to drive the reserve subsystem safely.
    wire [1:0] rm_source_server;
    wire [1:0] rm_receiver_server;
    wire rm_redistribution_enable;
    wire [15:0] rm_redistribution_amount;
    wire rm_emergency_restriction;
    wire rm_cooling_boost_required;

    wire [1:0] best_receiver_w;
    wire s1_receiver_eligible_w, s2_receiver_eligible_w, s3_receiver_eligible_w;

    health_maintenance_top HM (
        .clk(clk), .rst(rst),
        .s1_pred_it(s1_pred_it), .s2_pred_it(s2_pred_it), .s3_pred_it(s3_pred_it),
        .s1_pred_cooling(s1_pred_cooling), .s2_pred_cooling(s2_pred_cooling), .s3_pred_cooling(s3_pred_cooling),
        .s1_pred_hvac(s1_pred_hvac), .s2_pred_hvac(s2_pred_hvac), .s3_pred_hvac(s3_pred_hvac),
        .s1_pred_temp(s1_pred_temp), .s2_pred_temp(s2_pred_temp), .s3_pred_temp(s3_pred_temp),
        .s1_maint(s1_maint), .s2_maint(s2_maint), .s3_maint(s3_maint),
        .s1_power(s1_pred_total), .s2_power(s2_pred_total), .s3_power(s3_pred_total),
        .s1_reserve_trigger_la(s1_reserve_trigger), .s2_reserve_trigger_la(s2_reserve_trigger), .s3_reserve_trigger_la(s3_reserve_trigger),
        .s1_cooling_boost_la(s1_cooling_boost_la), .s2_cooling_boost_la(s2_cooling_boost_la), .s3_cooling_boost_la(s3_cooling_boost_la),
        .source_server(rm_source_server),
        .emergency_power_restriction_trigger(rm_emergency_restriction),
        .s1_effective_temp(s1_effective_temp), .s2_effective_temp(s2_effective_temp), .s3_effective_temp(s3_effective_temp),
        .s1_thermal_status(s1_thermal_status), .s2_thermal_status(s2_thermal_status), .s3_thermal_status(s3_thermal_status),
        .s1_pred_thermal_status(s1_pred_thermal_status), .s2_pred_thermal_status(s2_pred_thermal_status), .s3_pred_thermal_status(s3_pred_thermal_status),
        .s1_thermal_safe(s1_thermal_safe), .s2_thermal_safe(s2_thermal_safe), .s3_thermal_safe(s3_thermal_safe),
        .s1_pred_thermal_safe(s1_pred_thermal_safe), .s2_pred_thermal_safe(s2_pred_thermal_safe), .s3_pred_thermal_safe(s3_pred_thermal_safe),
        .s1_thermal_redist_trigger(s1_thermal_redist_trigger), .s2_thermal_redist_trigger(s2_thermal_redist_trigger), .s3_thermal_redist_trigger(s3_thermal_redist_trigger),
        .s1_cooling_malfunction(s1_cooling_malfunction), .s2_cooling_malfunction(s2_cooling_malfunction), .s3_cooling_malfunction(s3_cooling_malfunction),
        .s1_maintenance_ok(s1_maintenance_ok), .s2_maintenance_ok(s2_maintenance_ok), .s3_maintenance_ok(s3_maintenance_ok),
        .s1_health_eligible(s1_health_eligible), .s2_health_eligible(s2_health_eligible), .s3_health_eligible(s3_health_eligible),
        .reserve_cooling_injection(reserve_cooling_injection),
        .reserve_charge_level(reserve_charge_level),
        .s1_reserve_injection(s1_reserve_injection), .s2_reserve_injection(s2_reserve_injection), .s3_reserve_injection(s3_reserve_injection),
        .cooling_reserve_active()
    );

    priority_eligibility PE (
        .s1_pred_power(s1_pred_total), .s2_pred_power(s2_pred_total), .s3_pred_power(s3_pred_total),
        .s1_health_eligible(s1_health_eligible), .s2_health_eligible(s2_health_eligible), .s3_health_eligible(s3_health_eligible),
        .s1_pred_temp(s1_pred_temp), .s2_pred_temp(s2_pred_temp), .s3_pred_temp(s3_pred_temp),
        .mode_select(mode_select),
        .s1_receiver_eligible(s1_receiver_eligible_w), .s2_receiver_eligible(s2_receiver_eligible_w), .s3_receiver_eligible(s3_receiver_eligible_w),
        .best_receiver(best_receiver_w)
    );

    assign s1_receiver_eligible = s1_receiver_eligible_w;
    assign s2_receiver_eligible = s2_receiver_eligible_w;
    assign s3_receiver_eligible = s3_receiver_eligible_w;
    assign best_receiver = best_receiver_w;

    redistribution_manager RM (
        .s1_pred_power(s1_pred_total), .s2_pred_power(s2_pred_total), .s3_pred_power(s3_pred_total),
        .s1_pred_temp(s1_pred_temp), .s2_pred_temp(s2_pred_temp), .s3_pred_temp(s3_pred_temp),
        .s1_pred_high(s1_pred_high), .s2_pred_high(s2_pred_high), .s3_pred_high(s3_pred_high),
        .s1_thermal_redist_trigger(s1_thermal_redist_trigger),
        .s2_thermal_redist_trigger(s2_thermal_redist_trigger),
        .s3_thermal_redist_trigger(s3_thermal_redist_trigger),
        .best_receiver(best_receiver_w),
        .source_server(rm_source_server), .receiver_server(rm_receiver_server),
        .redistribution_enable(rm_redistribution_enable),
        .redistribution_amount(rm_redistribution_amount),
        .emergency_power_restriction_trigger(rm_emergency_restriction),
        .cooling_boost_required(rm_cooling_boost_required)
    );

    assign source_server = rm_source_server;
    assign receiver_server = rm_receiver_server;
    assign redistribution_enable = rm_redistribution_enable;
    assign redistribution_amount = rm_redistribution_amount;
    assign emergency_power_restriction_trigger = rm_emergency_restriction;
    assign cooling_boost_required = rm_cooling_boost_required;

    power_allocation_engine ALLOC (
        .clk(clk), .rst(rst),
        .s1_pred_power(s1_pred_total), .s2_pred_power(s2_pred_total), .s3_pred_power(s3_pred_total),
        .s1_pred_it(s1_pred_it), .s2_pred_it(s2_pred_it), .s3_pred_it(s3_pred_it),
        .s1_pred_cooling(s1_pred_cooling), .s2_pred_cooling(s2_pred_cooling), .s3_pred_cooling(s3_pred_cooling),
        .s1_pred_hvac(s1_pred_hvac), .s2_pred_hvac(s2_pred_hvac), .s3_pred_hvac(s3_pred_hvac),
        .s1_reserve_trigger(s1_reserve_trigger), .s2_reserve_trigger(s2_reserve_trigger), .s3_reserve_trigger(s3_reserve_trigger),
        .s1_reserve_injection(s1_reserve_injection), .s2_reserve_injection(s2_reserve_injection), .s3_reserve_injection(s3_reserve_injection),
        .source_server(rm_source_server), .receiver_server(rm_receiver_server),
        .redistribution_enable(rm_redistribution_enable),
        .redistribution_amount(rm_redistribution_amount),
        .emergency_power_restriction_trigger(rm_emergency_restriction),
        .cooling_boost_required(rm_cooling_boost_required),
        .s1_allocated(s1_allocated), .s2_allocated(s2_allocated), .s3_allocated(s3_allocated),
        .s1_extra_cooling(s1_extra_cooling), .s2_extra_cooling(s2_extra_cooling), .s3_extra_cooling(s3_extra_cooling),
        .full_cooling_engage(full_cooling_engage)
    );

    safety_check SAFETY (
        .s1_allocated(s1_allocated), .s2_allocated(s2_allocated), .s3_allocated(s3_allocated),
        .reserve_charge_level(reserve_charge_level),
        .s1_reserve_injection(s1_reserve_injection), .s2_reserve_injection(s2_reserve_injection), .s3_reserve_injection(s3_reserve_injection),
        .s1_reserve_trigger(s1_reserve_trigger), .s2_reserve_trigger(s2_reserve_trigger), .s3_reserve_trigger(s3_reserve_trigger),
        .full_cooling_engage(full_cooling_engage),
        .source_server(rm_source_server), .receiver_server(rm_receiver_server),
        .redistribution_enable(rm_redistribution_enable),
        .emergency_power_restriction_trigger(rm_emergency_restriction),
        .s1_allocation_valid(s1_allocation_valid), .s2_allocation_valid(s2_allocation_valid), .s3_allocation_valid(s3_allocation_valid),
        .reserve_valid(reserve_valid),
        .reserve_injection_consistent(reserve_injection_consistent),
        .redistribution_consistent(redistribution_consistent),
        .restriction_consistent(restriction_consistent),
        .final_valid(final_valid)
    );
endmodule
