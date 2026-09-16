module load_analyzer_top (
    input  [15:0] s1_pred_it, s1_pred_cooling, s1_pred_hvac, s1_pred_pump,
    input  [15:0] s2_pred_it, s2_pred_cooling, s2_pred_hvac, s2_pred_pump,
    input  [15:0] s3_pred_it, s3_pred_cooling, s3_pred_hvac, s3_pred_pump,

    output [15:0] s1_pred_total, s2_pred_total, s3_pred_total,
    output [2:0]  s1_pred_zone, s2_pred_zone, s3_pred_zone,
    output        s1_pred_high, s2_pred_high, s3_pred_high,
    output        s1_reserve_trigger, s2_reserve_trigger, s3_reserve_trigger,
    output        s1_cooling_boost, s2_cooling_boost, s3_cooling_boost
);

    load_analyzer LA_S1 (
        .pred_it_power(s1_pred_it),
        .pred_cooling_power(s1_pred_cooling),
        .pred_hvac_power(s1_pred_hvac),
        .pred_pump_power(s1_pred_pump),
        .predicted_power_total(s1_pred_total),
        .predicted_zone(s1_pred_zone),
        .predicted_high_power(s1_pred_high),
        .reserve_trigger(s1_reserve_trigger),
        .cooling_boost(s1_cooling_boost)
    );

    load_analyzer LA_S2 (
        .pred_it_power(s2_pred_it),
        .pred_cooling_power(s2_pred_cooling),
        .pred_hvac_power(s2_pred_hvac),
        .pred_pump_power(s2_pred_pump),
        .predicted_power_total(s2_pred_total),
        .predicted_zone(s2_pred_zone),
        .predicted_high_power(s2_pred_high),
        .reserve_trigger(s2_reserve_trigger),
        .cooling_boost(s2_cooling_boost)
    );

    load_analyzer LA_S3 (
        .pred_it_power(s3_pred_it),
        .pred_cooling_power(s3_pred_cooling),
        .pred_hvac_power(s3_pred_hvac),
        .pred_pump_power(s3_pred_pump),
        .predicted_power_total(s3_pred_total),
        .predicted_zone(s3_pred_zone),
        .predicted_high_power(s3_pred_high),
        .reserve_trigger(s3_reserve_trigger),
        .cooling_boost(s3_cooling_boost)
    );

endmodule
