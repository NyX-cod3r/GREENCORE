from datetime import datetime, timedelta
from pathlib import Path
import csv
import math

ROOT = Path(__file__).resolve().parent
START = datetime(2025, 1, 1)
ROWS = 36_000

for server in range(1, 4):
    path = ROOT / f"server{server}.csv"
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["ts", "cooling_kw", "hvac_kw", "it_power_kw", "pump_kw"])
        for minute in range(ROWS):
            stamp = START + timedelta(minutes=minute)
            daily = math.sin(2 * math.pi * (minute % 1440) / 1440)
            weekly = math.sin(2 * math.pi * minute / (1440 * 7))
            phase = (server - 1) * 0.7
            it_power = 420 + server * 28 + 42 * math.sin(2 * math.pi * minute / 720 + phase) + 18 * weekly
            cooling = 85 + server * 6 + 8 * daily + 3 * math.sin(2 * math.pi * minute / 360 + phase)
            hvac = 52 + server * 4 + 7 * daily + 2 * weekly
            pump = 24 + server * 2 + 3 * math.sin(2 * math.pi * minute / 480 + phase)
            writer.writerow([
                stamp.strftime("%Y-%m-%d %H:%M:%S"),
                f"{cooling:.3f}",
                f"{hvac:.3f}",
                f"{it_power:.3f}",
                f"{pump:.3f}",
            ])

print(f"Generated {ROWS:,} rows for three servers in {ROOT}")
