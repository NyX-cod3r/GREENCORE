# GreenCore Power Optimization System

GreenCore is a deterministic FPGA-style controller for balancing power and thermal load across three data-center servers. The Verilog RTL analyzes predicted load, evaluates thermal and maintenance health, selects a safe receiver, redistributes power, manages reserve capacity, and validates the final allocation.

This repository contains:

- `rtl/`: controller and safety modules
- `simulation/system_frame_tb.v`: frame-based Verilog testbench
- `simulation/system_frames.txt`: input scenarios
- `simulation/output/system_results.csv`: dashboard-ready simulation output
- `DASHBOARD/dashboard.html`: browser dashboard for the simulation
- `Copy_of_datacenter_power_forecasting.ipynb` and `SIH_model_for_power_optimization.ipynb`: notebook experiments and visual analysis

## Prerequisites

- Windows PowerShell
- Icarus Verilog with both `iverilog` and `vvp` available on `PATH`
- A browser
- Python 3 for the local dashboard server

The notebooks additionally require their imports to be installed in the selected Python environment. The RTL simulation and dashboard do not require Python packages.

## Run the simulation

From the repository root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\run_simulation.ps1
```

The command compiles every Verilog file in `rtl/`, runs the testbench, and regenerates:

- `simulation/output/system_results.csv`
- `simulation/output/system_run.vcd`

The compiled `simulation/output/sih_model.vvp` file is also regenerated locally. Build and waveform artifacts are ignored by Git.

If the command reports that `iverilog` or `vvp` is missing, install Icarus Verilog and reopen PowerShell so the updated `PATH` is loaded.

## Run the dashboard

The dashboard fetches the generated CSV, so serve the repository over HTTP rather than opening the HTML file directly:

```powershell
python -m http.server 8000
```

Open <http://localhost:8000/DASHBOARD/dashboard.html> in a browser. Use the frame selector, `Next`, and `Play frames` controls to inspect the controller decisions. The dashboard uses Chart.js and Three.js from their public CDNs, so an internet connection is needed for charts and the 3D view.

## Current simulation

The checked-in CSV contains three scenarios at 22 ns, 32 ns, and 42 ns. The current scenarios produce valid safety gates in every frame. The 32 ns frame demonstrates a 120 W redistribution from S1 to S2; the 42 ns frame demonstrates a high-temperature S1 condition with transfer disabled.

## Notebook analysis

Open either notebook in VS Code or Jupyter after selecting a Python environment with the packages imported by that notebook. `Copy_of_datacenter_power_forecasting.ipynb` expects three source files in `data/`:

- `server1.csv` or `server1.xlsx`
- `server2.csv` or `server2.xlsx`
- `server3.csv` or `server3.xlsx`

Each file must contain `ts`, `cooling_kw`, `hvac_kw`, `it_power_kw`, and `pump_kw` columns. The notebook also works in Colab when those files are placed in `/content/drive/MyDrive/SIH`. The repository currently does not include these private source datasets, so the forecasting notebook cannot complete until they are supplied. Its loader now reports this requirement directly.

For a reproducible local smoke test, the repository includes deterministic synthetic inputs in `data/server1.csv`, `data/server2.csv`, and `data/server3.csv`. Regenerate them with:

```powershell
python data\generate_sample_data.py
```

These sample files are for validation only and do not represent real data-center measurements. Replace them with the real server exports for meaningful forecasting.

The notebooks are analysis surfaces; the Verilog testbench is the source of truth for the generated controller behavior shown in the dashboard.