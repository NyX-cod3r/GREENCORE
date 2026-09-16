module system_frame_tb;
    reg clk = 1'b0; // Initialize clk here
    reg rst;

    // Current data: reference only.
    reg [15:0] s1_it, s1_cooling, s1_hvac, s1_pump;
    reg [15:0] s2_it, s2_cooling, s2_hvac, s2_pump;
    reg [15:0] s3_it, s3_cooling, s3_hvac, s3_pump;

    // Predicted data: functional FPGA inputs.
    reg [15:0] s1_pred_it, s1_pred_cooling, s1_pred_hvac, s1_pred_pump;
    reg [15:0] s2_pred_it, s2_pred_cooling, s2_pred_hvac, s2_pred_pump;
    reg [15:0] s3_pred_it, s3_pred_cooling, s3_pred_hvac, s3_pred_pump;

    reg [7:0] s1_temp_ref, s2_temp_ref, s3_temp_ref;
    reg [7:0] s1_pred_temp, s2_pred_temp, s3_pred_temp;
    reg [1:0] s1_maint, s2_maint, s3_maint;
    reg [1:0] mode_select;

    wire [15:0] ref_s1_current_total = s1_it + s1_cooling + s1_hvac + s1_pump;
    wire [15:0] ref_s2_current_total = s2_it + s2_cooling + s2_hvac + s2_pump;
    wire [15:0] ref_s3_current_total = s3_it + s3_cooling + s3_hvac + s3_pump;

    wire [15:0] s1_pred_total, s2_pred_total, s3_pred_total;
    wire [2:0] s1_pred_zone, s2_pred_zone, s3_pred_zone;
    wire s1_pred_high, s2_pred_high, s3_pred_high;

    wire [7:0] s1_effective_temp, s2_effective_temp, s3_effective_temp;
    wire s1_health_eligible, s2_health_eligible, s3_health_eligible;
    wire s1_receiver_eligible, s2_receiver_eligible, s3_receiver_eligible;
    wire [1:0] best_receiver;

    wire [1:0] source_server, receiver_server;
    wire redistribution_enable;
    wire [15:0] redistribution_amount;
    wire emergency_power_restriction_trigger;
    wire cooling_boost_required;

    wire [15:0] s1_reserve_injection, s2_reserve_injection, s3_reserve_injection;
    wire [15:0] reserve_cooling_injection, reserve_charge_level;
    wire [15:0] s1_allocated, s2_allocated, s3_allocated;
    wire [15:0] s1_extra_cooling, s2_extra_cooling, s3_extra_cooling;
    wire full_cooling_engage;

    wire s1_allocation_valid, s2_allocation_valid, s3_allocation_valid;
    wire reserve_valid, reserve_injection_consistent;
    wire redistribution_consistent, restriction_consistent, final_valid;

    green_core_controller DUT (
        .clk(clk), .rst(rst),

        .s1_pred_it(s1_pred_it), .s1_pred_cooling(s1_pred_cooling), .s1_pred_hvac(s1_pred_hvac), .s1_pred_pump(s1_pred_pump),
        .s2_pred_it(s2_pred_it), .s2_pred_cooling(s2_pred_cooling), .s2_pred_hvac(s2_pred_hvac), .s2_pred_pump(s2_pred_pump),
        .s3_pred_it(s3_pred_it), .s3_pred_cooling(s3_pred_cooling), .s3_pred_hvac(s3_pred_hvac), .s3_pred_pump(s3_pred_pump),

        .s1_pred_temp(s1_pred_temp), .s2_pred_temp(s2_pred_temp), .s3_pred_temp(s3_pred_temp),
        .s1_maint(s1_maint), .s2_maint(s2_maint), .s3_maint(s3_maint),
        .mode_select(mode_select),

        .s1_pred_total(s1_pred_total), .s2_pred_total(s2_pred_total), .s3_pred_total(s3_pred_total),
        .s1_pred_zone(s1_pred_zone), .s2_pred_zone(s2_pred_zone), .s3_pred_zone(s3_pred_zone),
        .s1_pred_high(s1_pred_high), .s2_pred_high(s2_pred_high), .s3_pred_high(s3_pred_high),

        .s1_effective_temp(s1_effective_temp), .s2_effective_temp(s2_effective_temp), .s3_effective_temp(s3_effective_temp),
        .s1_health_eligible(s1_health_eligible), .s2_health_eligible(s2_health_eligible), .s3_health_eligible(s3_health_eligible),
        .s1_receiver_eligible(s1_receiver_eligible), .s2_receiver_eligible(s2_receiver_eligible), .s3_receiver_eligible(s3_receiver_eligible),
        .best_receiver(best_receiver),

        .source_server(source_server), .receiver_server(receiver_server),
        .redistribution_enable(redistribution_enable), .redistribution_amount(redistribution_amount),
        .emergency_power_restriction_trigger(emergency_power_restriction_trigger),
        .cooling_boost_required(cooling_boost_required),

        .s1_reserve_injection(s1_reserve_injection), .s2_reserve_injection(s2_reserve_injection), .s3_reserve_injection(s3_reserve_injection),
        .reserve_cooling_injection(reserve_cooling_injection), .reserve_charge_level(reserve_charge_level),

        .s1_allocated(s1_allocated), .s2_allocated(s2_allocated), .s3_allocated(s3_allocated),
        .s1_extra_cooling(s1_extra_cooling), .s2_extra_cooling(s2_extra_cooling), .s3_extra_cooling(s3_extra_cooling),
        .full_cooling_engage(full_cooling_engage),

        .s1_allocation_valid(s1_allocation_valid), .s2_allocation_valid(s2_allocation_valid), .s3_allocation_valid(s3_allocation_valid),
        .reserve_valid(reserve_valid), .reserve_injection_consistent(reserve_injection_consistent),
        .redistribution_consistent(redistribution_consistent), .restriction_consistent(restriction_consistent),
        .final_valid(final_valid)
    );

    always #5 clk = ~clk;

    integer fd, status, frame_num;
    integer result_fd;   // NEW: CSV output for graphing in Colab/Python

    initial begin
        $dumpfile("simulation/output/system_run.vcd");
        $dumpvars(0, system_frame_tb);

        // Safe initial conditions.
        // clk = 1'b0; // Initialize clk here - REMOVED
        rst = 1'b1;
        s1_it=0; s1_cooling=0; s1_hvac=0; s1_pump=0;
        s2_it=0; s2_cooling=0; s2_hvac=0; s2_pump=0;
        s3_it=0; s3_cooling=0; s3_hvac=0; s3_pump=0;
        s1_pred_it=0; s1_pred_cooling=0; s1_pred_hvac=0; s1_pred_pump=0;
        s2_pred_it=0; s2_pred_cooling=0; s2_pred_hvac=0; s2_pred_pump=0;
        s3_pred_it=0; s3_pred_cooling=0; s3_pred_hvac=0; s3_pred_pump=0;
        s1_temp_ref=0; s2_temp_ref=0; s3_temp_ref=0;
        s1_pred_temp=0; s2_pred_temp=0; s3_pred_temp=0;
        s1_maint=0; s2_maint=0; s3_maint=0;
        mode_select=0;

        #12;
        rst = 1'b0;

        fd = $fopen("simulation/system_frames.txt", "r");
        if (fd == 0) begin
            $display("ERROR: could not open simulation/system_frames.txt");
            $finish;
        end

        // NEW: machine-readable per-frame log for graphing in Colab/Python.
        // One row per simulated frame, covering every signal the six
        // requested graphs need (allocation, temperature before/after,
        // predicted-vs-current power, reserve charge, redistribution).
        result_fd = $fopen("simulation/output/system_results.csv", "w");
        if (result_fd == 0) begin
            $display("ERROR: could not open simulation/output/system_results.csv for writing");
            $finish;
        end
        $fwrite(result_fd, "frame,time,current_s1,pred_s1,current_s2,pred_s2,current_s3,pred_s3,alloc_s1,alloc_s2,alloc_s3,source,receiver,redist_enable,redist_amount,pred_temp_s1,pred_temp_s2,pred_temp_s3,eff_temp_s1,eff_temp_s2,eff_temp_s3,reserve_charge,final_valid\n");

        frame_num = 0;

        while (!$feof(fd)) begin
            status = $fscanf(fd,
                "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",

                s1_it, s1_cooling, s1_hvac, s1_pump,
                s1_pred_it, s1_pred_cooling, s1_pred_hvac, s1_pred_pump,
                s1_temp_ref, s1_pred_temp, s1_maint,

                s2_it, s2_cooling, s2_hvac, s2_pump,
                s2_pred_it, s2_pred_cooling, s2_pred_hvac, s2_pred_pump,
                s2_temp_ref, s2_pred_temp, s2_maint,

                s3_it, s3_cooling, s3_hvac, s3_pump,
                s3_pred_it, s3_pred_cooling, s3_pred_hvac, s3_pred_pump,
                s3_temp_ref, s3_pred_temp, s3_maint,

                mode_select
            );

            if (status == 34) begin
                #10;
                $display("========================================================");
                $display("FRAME %0d | TIME=%0t ns | MODE=%0d", frame_num, $time, mode_select);
                $display("REF  S1=%0d W | PRED S1=%0d W | Zone=%0d | PredHigh=%b", ref_s1_current_total, s1_pred_total, s1_pred_zone, s1_pred_high);
                $display("REF  S2=%0d W | PRED S2=%0d W | Zone=%0d | PredHigh=%b", ref_s2_current_total, s2_pred_total, s2_pred_zone, s2_pred_high);
                $display("REF  S3=%0d W | PRED S3=%0d W | Zone=%0d | PredHigh=%b", ref_s3_current_total, s3_pred_total, s3_pred_zone, s3_pred_high);
                $display("TEMP S1=%0dC S2=%0dC S3=%0dC | HEALTH=%b%b%b", s1_effective_temp, s2_effective_temp, s3_effective_temp, s1_health_eligible, s2_health_eligible, s3_health_eligible);
                $display("RECV S1=%b S2=%b S3=%b | BEST=%0d", s1_receiver_eligible, s2_receiver_eligible, s3_receiver_eligible, best_receiver);
                $display("REDIST SOURCE=%0d RECEIVER=%0d ENABLE=%b AMOUNT=%0d W", source_server, receiver_server, redistribution_enable, redistribution_amount);
                $display("ALLOC S1=%0d W S2=%0d W S3=%0d W | COOLING=%b EXTRA=%0d/%0d/%0d", s1_allocated, s2_allocated, s3_allocated, cooling_boost_required, s1_extra_cooling, s2_extra_cooling, s3_extra_cooling);
                $display("SAFETY final=%b alloc=%b%b%b reserve=%b redist=%b restriction=%b", final_valid, s1_allocation_valid, s2_allocation_valid, s3_allocation_valid, reserve_valid, redistribution_consistent, restriction_consistent);
                $display("========================================================");

                // NEW: one CSV row per frame, same data as the $display above
                // but machine-readable for pandas/matplotlib in Colab.
                $fwrite(result_fd,
                    "%0d,%0t,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d\n",
                    frame_num, $time,
                    ref_s1_current_total, s1_pred_total,
                    ref_s2_current_total, s2_pred_total,
                    ref_s3_current_total, s3_pred_total,
                    s1_allocated, s2_allocated, s3_allocated,
                    source_server, receiver_server, redistribution_enable, redistribution_amount,
                    s1_pred_temp, s2_pred_temp, s3_pred_temp,
                    s1_effective_temp, s2_effective_temp, s3_effective_temp,
                    reserve_charge_level,
                    final_valid
                );

                frame_num = frame_num + 1;
            end
        end

        $fclose(fd);
        $fclose(result_fd);
        $display("Simulation complete. Processed %0d frames.", frame_num);
        $display("Wrote simulation/output/system_results.csv (%0d rows) for graphing.", frame_num);
        $finish;
    end
endmodule
