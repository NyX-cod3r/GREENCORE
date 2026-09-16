# GreenCore: Data-Center Power Optimizer

GreenCore is a working demonstration of a controller that helps manage power and temperature in a small data center.

It watches three servers, named S1, S2, and S3. For each server, it looks at predicted power use, temperature, cooling, and maintenance condition. It can decide whether to move work away from an overloaded server, give a server extra cooling or reserve power, or apply an emergency restriction.

This project has two related parts:

1. A **Verilog hardware-style controller** that makes the power and safety decisions.
2. A **Python forecasting notebook** that predicts future server measurements from CSV or Excel data.

The dashboard displays the results produced by the Verilog simulation.

## Start here

Run these commands from the project folder:

```powershell
.\run_simulation.ps1
python -m http.server 8000
```

Then open <http://localhost:8000/DASHBOARD/dashboard.html> in a browser. The first command runs the hardware simulation. The second command starts a small local web server so the dashboard can read the simulation CSV.

## What is included

- `rtl/`: Verilog modules that implement the controller.
- `rtl/green_core_controller.v`: connects all controller modules together.
- `simulation/system_frame_tb.v`: testbench that feeds scenarios into the controller.
- `simulation/system_frames.txt`: the three input scenarios used by the testbench.
- `simulation/output/system_results.csv`: machine-readable results used by the dashboard.
- `DASHBOARD/dashboard.html`: browser dashboard for the simulation.
- `DASHBOARD/background.jpg`: dashboard background image.
- `run_simulation.ps1`: one-command compile and simulation script.
- `Copy_of_datacenter_power_forecasting.ipynb`: forecasting notebook.
- `SIH_model_for_power_optimization.ipynb`: additional notebook analysis.
- `data/server1.csv`, `data/server2.csv`, `data/server3.csv`: deterministic sample data for testing the forecasting notebook.
- `data/generate_sample_data.py`: recreates the sample data.
- `predictions.txt`: forecast values in the required text format.
- `predictions_with_timestamps.csv`: forecast values with timestamps and actual holdout values.
- `README_model_explanation.md`: a plain-language explanation of the controller modules.

## Requirements

- Windows PowerShell.
- Python 3. The notebook uses pandas, NumPy, matplotlib, scikit-learn, XGBoost, python-dateutil, and openpyxl.
- Icarus Verilog, which provides the `iverilog` and `vvp` commands.
- A web browser.
- Internet access when opening the dashboard, because Chart.js and Three.js are loaded from public CDNs.

The RTL simulation itself does not need Python packages. The dashboard does not need a Python package, but it must be served over HTTP.

## Run the Verilog simulation

From the project folder:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\run_simulation.ps1
```

The script finds every `.v` file in `rtl/`, compiles them with Icarus Verilog, runs the testbench, and writes results to `simulation/output/`.

The simulation creates or updates:

- `system_results.csv`: one row for each scenario.
- `system_run.vcd`: waveform data for a waveform viewer.
- `sih_model.vvp`: the compiled simulation file.

The checked-in scenarios currently produce three frames at 22 ns, 32 ns, and 42 ns. All three frames pass the controller safety gate. The second frame demonstrates a 120 W transfer from S1 to S2. The third frame demonstrates a high-temperature S1 condition where transfer is disabled.

If PowerShell says that `iverilog` or `vvp` cannot be found, install Icarus Verilog and reopen PowerShell or VS Code so the updated `PATH` is loaded.

## Run the dashboard

Do not open the HTML file directly from File Explorer. The browser may block its CSV request. Start the local server instead:

```powershell
python -m http.server 8000
```

Open <http://localhost:8000/DASHBOARD/dashboard.html>.

The dashboard provides a frame selector, `Next` and `Play frames` controls, predicted load, reserve charge, redistribution details, safety status, temperature and power charts, and a visual three-server controller map.

The dashboard reads `simulation/output/system_results.csv`. If the CSV cannot be loaded, it shows built-in demonstration frames.

## Run the forecasting notebook

The main notebook expects three files in the `data/` folder:

- `server1.csv` or `server1.xlsx`
- `server2.csv` or `server2.xlsx`
- `server3.csv` or `server3.xlsx`

Every input file must contain these columns:

- `ts`: timestamp
- `cooling_kw`: cooling power in kilowatts
- `hvac_kw`: HVAC power in kilowatts
- `it_power_kw`: server IT power in kilowatts
- `pump_kw`: pump power in kilowatts

The sample files in this repository are synthetic. They are useful for checking that the notebook works, but they are not real data-center measurements.

To recreate the sample files:

```powershell
python data\generate_sample_data.py
```

Then open `Copy_of_datacenter_power_forecasting.ipynb` in VS Code or Jupyter and run its Python cells in order. The notebook cleans and aligns the three files, creates history features, trains twelve forecasting models, compares them with simple baselines, forecasts the final ten days, checks the output format, and writes `predictions.txt` and `predictions_with_timestamps.csv`.

The notebook was tested with the included sample data. Its final forecast contains 14,400 rows, representing ten days at one-minute intervals. For real forecasting, replace the sample files with real server exports using the same column names. The notebook also supports Colab when the files are placed in `/content/drive/MyDrive/SIH`.

## Important terms

- **RTL**: code that describes digital hardware behavior.
- **Testbench**: a program that feeds test inputs into the hardware design and records results.
- **Simulation frame**: one test scenario at one simulated time.
- **Predicted power**: the expected power value used by the controller.
- **Reserve power**: backup capacity used when normal capacity is not enough.
- **Redistribution**: moving requested workload or power from one server to another.
- **Safety gate**: the final yes/no check that controller rules passed.
- **CSV**: a text file where values are separated by commas.
- **VCD**: a waveform file used to inspect signal changes over simulation time.

## Scope and limitations

This repository is a tested simulation and demonstration, not a direct connection to live server hardware. The included sample forecast data is synthetic. Real deployment would require live sensor inputs, a hardware integration layer, operational limits approved by the data-center team, and additional safety testing.

The forecasting notebook and the Verilog controller are connected conceptually, but the notebook does not automatically convert forecast output into `simulation/system_frames.txt`. That conversion is currently a manual project boundary.