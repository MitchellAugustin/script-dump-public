#!/usr/bin/env python3
import re
import statistics
from pathlib import Path

RESULTS_DIR = Path("/var/lib/initramfs-test/results")
pattern = re.compile(r"\+ ([0-9.]+)s \(kernel\)")

def parse_kernel_times(file_path):
    times = []
    with open(file_path) as f:
        for line in f:
            m = pattern.search(line)
            if m:
                times.append(float(m.group(1)))
    return times

def summarize(times):
    return {
        "runs": len(times),
        "min": min(times),
        "max": max(times),
        "avg": statistics.mean(times),
        "median": statistics.median(times),
        "std": statistics.stdev(times) if len(times) > 1 else 0.0
    }

def main():
    files = sorted(RESULTS_DIR.glob("*_boot.txt"))
    if not files:
        print(f"No *_boot.txt files found in {RESULTS_DIR}")
        return

    print(f"Kernel time statistics from {RESULTS_DIR}\n")
    header = f"{'Algorithm':<10} {'Runs':>4} {'Min':>8} {'Max':>8} {'Avg':>8} {'Median':>8} {'StdDev':>8}"
    print(header)
    print("-" * len(header))

    for file in files:
        algo = file.stem.replace("_boot", "")
        times = parse_kernel_times(file)
        if not times:
            print(f"{algo:<10} no kernel times found")
            continue
        stats = summarize(times)
        print(f"{algo:<10} {stats['runs']:>4d} {stats['min']:8.3f} {stats['max']:8.3f} "
              f"{stats['avg']:8.3f} {stats['median']:8.3f} {stats['std']:8.3f}")

if __name__ == "__main__":
    main()

