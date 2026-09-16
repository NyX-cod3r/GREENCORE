# GreenCore Dashboard Guide

This dashboard is a browser view of the Verilog controller simulation. It reads `../simulation/output/system_results.csv` and lets you inspect one simulation frame at a time. A frame is one test scenario captured at a simulated time, not a live data-center reading.

## What the dashboard is showing

### Header and frame controls

- **GreenCore / AI-FPGA data center optimizer:** identifies the project and the controller being visualized.
- **Play frames:** automatically advances through the available simulation frames every 1.8 seconds. The button changes to **Pause frames** while playing.
- **Inspect simulation frame:** selects the frame whose values are shown in the cards, 3D map, temperature chart, and server telemetry.
- **Next:** advances to the next frame. After the final frame, it returns to the first one.
- **Frame number and time:** for example, `Frame 1 · 32 ns` means simulation frame 1 at simulated time 32 nanoseconds.

The dashboard loads the CSV when it starts. If the CSV cannot be loaded, it uses three built-in demonstration frames so the page can still be viewed. Those fallback values are not a replacement for the simulation output.

## Summary cards

These four cards describe the currently selected frame.

### Predicted load

This is the total predicted power for all three servers:

```text
predicted load = pred_s1 + pred_s2 + pred_s3
```

The smaller line shows the individual predicted values for S1, S2, and S3. The values are displayed in watts (`W`). This is the controller's expected server load, not necessarily the current measured load.

### Reserve charge

This is the remaining reserve-power capacity reported by the controller in the selected frame. The dashboard displays it in watts and compares it with the controller's maximum capacity of 10,000 W. A lower value means that more reserve capacity has been used in the simulated sequence.

### Redistribution

This shows whether the controller requested a transfer of workload or power:

- **Standby:** no redistribution is requested.
- **`N W transfer`:** the controller requested a transfer of `N` watts.
- The note below identifies the direction, such as `S1 -> S2`, where S1 is the source and S2 is the receiver.

The dashboard reports the request from the simulation. It does not itself move real workloads between servers.

### Safety gate

This is the final controller validation result:

- **VALID:** `final_valid = 1`; the simulated allocation and safety rules passed.
- **BLOCKED:** `final_valid = 0`; at least one safety rule failed.

## Three-server energy core

The spatial control map is an interactive 3D visualization of the controller and servers S1, S2, and S3.

- The center object represents the **AI-FPGA controller core**.
- The three surrounding rack shapes represent **S1, S2, and S3**.
- Each server label shows its predicted power and effective temperature for the selected frame.
- Server height changes with predicted power. A taller server shape indicates a higher predicted load relative to the other frames.
- Healthy servers use the normal load/healthy colors.
- A server at or above 85 degrees Celsius is shown as a thermal-risk state.
- An animated beam and particles appear when redistribution is enabled. The beam runs from the source server to the receiver server.
- `SYSTEM VALID` or `SAFETY BLOCKED` shows the selected frame's final safety result.
- Drag the map horizontally to rotate the view.

The map is a visual summary; the exact numeric values come from the cards, charts, and server telemetry below it.

## Charts

### Current vs predicted power

This line chart shows all available frames on the horizontal axis. It contains six series:

- `S1 predicted`, `S2 predicted`, and `S3 predicted` are the controller's predicted power values.
- `S1 current`, `S2 current`, and `S3 current` are the current input values recorded for comparison.

The solid lines represent predicted values. The dashed lines represent current values. The chart uses watts and is not limited to the selected frame.

### Temperature response

This bar chart shows S1, S2, and S3 for the selected frame. Each server has two bars:

- **Predicted:** `pred_temp_s1`, `pred_temp_s2`, or `pred_temp_s3`.
- **Effective:** `eff_temp_s1`, `eff_temp_s2`, or `eff_temp_s3` after the controller's simulated actions and cooling effects.

The chart uses degrees Celsius. The 85 degrees Celsius threshold is important because it is the critical-temperature boundary used by the dashboard's server status and 3D map.

### Charge trajectory

This line chart shows `reserve_charge` for every frame in the CSV. It shows how much reserve capacity remains across the simulation, in watts. It also updates when the simulation CSV is regenerated.

## Server telemetry: Health and allocation

The three server panels show detailed values for the selected frame.

- **Status:** `healthy` when effective temperature is below 85 degrees Celsius; `critical` when it is 85 degrees Celsius or higher.
- **Predicted power:** the selected server's predicted load in watts.
- **Allocation:** the power allocation produced by the controller for that server, in watts. This is the simulated controller allocation, not a live power-meter reading.
- **Temperature:** the server's effective temperature in degrees Celsius.
- **Power bar:** a visual scale based on predicted power, capped at 1,000 W for display.
- **Temperature bar:** a visual scale based on effective temperature, capped at 100 degrees Celsius for display.

The text values are authoritative; the bars are only visual indicators.

## Controller sequence

The **Decision path** panel summarizes the order of the controller's logic:

1. **Analyze:** inspect power zones and thermal signals.
2. **Protect:** check server health and maintenance eligibility.
3. **Balance:** choose a source, receiver, and transfer amount when redistribution is safe.
4. **Validate:** check reserve use, allocations, and the final safety gate.

This panel is a fixed explanation of the controller flow. It does not change from frame to frame.

## Interpreting the included frames

The checked-in simulation normally contains three frames:

- **Frame 0 at 22 ns:** normal, lower-power conditions. No transfer is requested.
- **Frame 1 at 32 ns:** S1 is overloaded relative to the other servers. The controller requests a 120 W transfer from S1 to S2.
- **Frame 2 at 42 ns:** S1 is critically hot. Redistribution is disabled rather than making an unsafe transfer, while cooling support is requested.

All three checked-in frames currently pass the final safety gate. The dashboard will show different results if the testbench inputs or generated CSV are changed.

## Data source and limitations

The dashboard reads the CSV relative to this file:

```text
DASHBOARD/readme_dashboard.md
../simulation/output/system_results.csv
```

Serve the project directory over HTTP before opening the dashboard:

```powershell
python -m http.server 8000
```

Then open `http://localhost:8000/DASHBOARD/dashboard.html`.

The dashboard is a simulation and visualization, not a live monitoring system. It does not connect to physical servers, enforce real power limits, or perform real workload migration. Chart.js and Three.js are loaded from public CDNs, so an internet connection is required when the page is opened.