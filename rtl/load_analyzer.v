module load_analyzer (
    input  [15:0] pred_it_power,
    input  [15:0] pred_cooling_power,
    input  [15:0] pred_hvac_power,
    input  [15:0] pred_pump_power,

    output [15:0] predicted_power_total,
    output [2:0]  predicted_zone,
    output        predicted_high_power,
    output        reserve_trigger,
    output        cooling_boost
);

localparam [2:0] ZONE_EMERGENCY = 3'b000;
localparam [2:0] ZONE_BUFFER    = 3'b001;
localparam [2:0] ZONE_LOW       = 3'b010;
localparam [2:0] ZONE_MEDIUM    = 3'b011;
localparam [2:0] ZONE_HIGH      = 3'b100;
localparam [2:0] ZONE_CRITICAL  = 3'b101;

// Use a wider intermediate so large inputs saturate instead of wrapping.
function [15:0] saturating_total;
    input [15:0] it_power;
    input [15:0] cooling_power;
    input [15:0] hvac_power;
    input [15:0] pump_power;
    reg [17:0] total;
    begin
        total = {2'b0, it_power} + {2'b0, cooling_power} +
                {2'b0, hvac_power} + {2'b0, pump_power};
        saturating_total = (total > 18'd65535) ? 16'hffff : total[15:0];
    end
endfunction

assign predicted_power_total = saturating_total(
    pred_it_power, pred_cooling_power, pred_hvac_power, pred_pump_power);

function [2:0] classify;
    input [15:0] p;
    begin
        if      (p < 16'd300) classify = ZONE_EMERGENCY;
        else if (p < 16'd400) classify = ZONE_BUFFER;
        else if (p < 16'd550) classify = ZONE_LOW;
        else if (p < 16'd750) classify = ZONE_MEDIUM;
        else if (p < 16'd850) classify = ZONE_HIGH;
        else                  classify = ZONE_CRITICAL;
    end
endfunction

assign predicted_zone = classify(predicted_power_total);

assign predicted_high_power =
    (predicted_zone == ZONE_HIGH) ||
    (predicted_zone == ZONE_CRITICAL);

assign reserve_trigger = (predicted_zone == ZONE_EMERGENCY);
assign cooling_boost   = (predicted_zone == ZONE_CRITICAL);

endmodule
