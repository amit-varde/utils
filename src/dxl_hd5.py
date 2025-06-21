#!/usr/bin/env python3
"""
dxl_hd5.py - HDF5 Utility Script

This script provides a set of utilities for inspecting, extracting, and exporting groups and datasets from HDF5 files.

Features:
- Print the structure of an HDF5 file, including groups, datasets, shapes, dtypes, and attributes.
- Pretty-print the contents of datasets (with preview of values).
- Extract 2D datasets to CSV.
- Show all datasets in a specific group.
- Export a specific group or all top-level groups to new HDF5 files (in a subdirectory named after the input file).

Usage Examples:

# Show the structure of an HDF5 file
python dxl_hd5.py -i input.h5 --show STRUCTURE

# Show all datasets in a specific group
python dxl_hd5.py -i input.h5 --show groupname

# Export a specific group to a new HDF5 file
python dxl_hd5.py -i input.h5 -o groupname
# Output: ./<input_basename>/groupname.h5

# Export all top-level groups to separate HDF5 files
python dxl_hd5.py -i input.h5 --dump_all_groups
# Output: ./<input_basename>/<groupname>.h5 for each group

# Extract the first 2D dataset to CSV
python dxl_hd5.py -i input.h5 | tee output.csv

Arguments:
  -i, --input                Path to the HDF5 file (required)
  --show WHAT                Show structure (use "STRUCTURE") or datasets in a specific group name
  -o, --dump_group_to_hdf5   Dump the specified group to a new HDF5 file (output will be GROUP.h5 in a subdirectory)
  --dump_all_groups          Export all top-level groups in the input file to separate HDF5 files

Requirements:
- Python 3
- h5py
- pandas

"""
import sys
import os

# --- Python version and venv check ---
REQUIRED_PYTHON = (3, 7)
REQUIRED_PACKAGES = ["h5py", "pandas"]

if sys.version_info < REQUIRED_PYTHON:
    print(f"[dxl_hd5.py] ERROR: Python {REQUIRED_PYTHON[0]}.{REQUIRED_PYTHON[1]} required. You are using {sys.version_info.major}.{sys.version_info.minor}.", file=sys.stderr)
    sys.exit(1)

if sys.prefix == sys.base_prefix:
    print("[dxl_hd5.py] WARNING: You are not running inside a Python virtual environment (venv).", file=sys.stderr)
    print("To create and activate a venv:", file=sys.stderr)
    print("  python3 -m venv .venv && source .venv/bin/activate", file=sys.stderr)

missing = []
for pkg in REQUIRED_PACKAGES:
    try:
        __import__(pkg)
    except ImportError:
        missing.append(pkg)

if missing:
    print(f"[dxl_hd5.py] ERROR: Required packages not installed: {', '.join(missing)}", file=sys.stderr)
    print("To install, run:", file=sys.stderr)
    print(f"  pip install {' '.join(missing)}", file=sys.stderr)
    sys.exit(1)

import pandas as pd
import h5py
import argparse

def print_h5_structure(fpath):
    with h5py.File(fpath, 'r') as f:
        print("HDF5 file structure:", file=sys.stderr)
        def printname(name, obj):
            if isinstance(obj, h5py.Dataset):
                print(f"[DATASET] {name} (dtype: {obj.dtype}, shape: {obj.shape})", file=sys.stderr)
                if len(obj.attrs) > 0:
                    print(f"  Attributes: {dict(obj.attrs)}", file=sys.stderr)
            elif isinstance(obj, h5py.Group):
                print(f"[GROUP]   {name}", file=sys.stderr)
                if len(obj.attrs) > 0:
                    print(f"  Attributes: {dict(obj.attrs)}", file=sys.stderr)
            else:
                print(f"[OTHER]   {name} (type: {type(obj).__name__})", file=sys.stderr)
        f.visititems(printname)

def extract_2d_dataset_to_csv(fpath):
    with h5py.File(fpath, 'r') as f:
        for name in f:
            obj = f[name]
            if isinstance(obj, h5py.Dataset):
                arr = obj[()]
                if arr.ndim == 2:
                    df = pd.DataFrame(arr)
                    df.to_csv(sys.stdout, index=False)
                    return True
    return False

def pretty_print_dataset(dataset, max_rows=10):
    """
    Pretty print the contents of an h5py.Dataset based on dtype.
    Shows up to max_rows rows.
    """
    print(f"  {dataset.name} - dtype: {dataset.dtype}, shape: {dataset.shape}", file=sys.stderr)
    data = dataset[()]
    # Handle 1D and 2D arrays
    if data.ndim == 1:
        for i, val in enumerate(data[:max_rows]):
            print(f"    [{i}] {val}", file=sys.stderr)
        if data.shape[0] > max_rows:
            print(f"    ... ({data.shape[0] - max_rows} more rows)", file=sys.stderr)
    elif data.ndim == 2:
        for i, row in enumerate(data[:max_rows]):
            print(f"    [{i}] {row}", file=sys.stderr)
        if data.shape[0] > max_rows:
            print(f"    ... ({data.shape[0] - max_rows} more rows)", file=sys.stderr)
    else:
        print("    (Data has more than 2 dimensions, not displayed)", file=sys.stderr)

def show_group_datasets(fpath, group_name):
    """
    Print all datasets and their shapes under a given group (e.g., 'circuit0') in the HDF5 file.
    """
    with h5py.File(fpath, 'r') as f:
        if group_name not in f:
            print(f"Group '{group_name}' not found.", file=sys.stderr)
            return
        group = f[group_name]
        print(f"Contents of group '{group_name}':", file=sys.stderr)
        def printname(name, obj):
            if isinstance(obj, h5py.Dataset):
                pretty_print_dataset(obj)
                if len(obj.attrs) > 0:
                    print(f"  Attributes: {dict(obj.attrs)}", file=sys.stderr)
            elif isinstance(obj, h5py.Group):
                print(f"[GROUP]   {name}", file=sys.stderr)
                if len(obj.attrs) > 0:
                    print(f"  Attributes: {dict(obj.attrs)}", file=sys.stderr)
            else:
                print(f"[OTHER]   {name} (type: {type(obj).__name__})", file=sys.stderr)
        group.visititems(printname)

def dump_group_to_hdf5(src_path, group_name, dest_path):
    """
    Copy a group and all its contents from one HDF5 file to a new HDF5 file.
    If the destination file exists, remove it first to avoid locking errors.
    """
    if os.path.exists(dest_path):
        os.remove(dest_path)
    with h5py.File(src_path, 'r') as src, h5py.File(dest_path, 'w') as dest:
        if group_name not in src:
            print(f"Group '{group_name}' not found in source file.", file=sys.stderr)
            return
        src.copy(group_name, dest)
        print(f"Group '{group_name}' copied from {src_path} to {dest_path}", file=sys.stderr)

def dump_all_groups_to_hdf5(src_path):
    """
    Export all top-level groups in the input HDF5 file to separate HDF5 files using dump_group_to_hdf5().
    Output files will be named <groupname>.h5 in a subdirectory named after the input file (without extension).
    """
    input_dir = os.path.dirname(os.path.abspath(src_path))
    source_basename = os.path.splitext(os.path.basename(src_path))[0]
    output_dir = os.path.join(input_dir, source_basename)
    os.makedirs(output_dir, exist_ok=True)
    with h5py.File(src_path, 'r') as src:
        for name, obj in src.items():
            if isinstance(obj, h5py.Group):
                outfile = os.path.join(output_dir, f"{name}.h5")
                dump_group_to_hdf5(src_path, name, outfile)

def main():
    parser = argparse.ArgumentParser(description='HDF5 file utility.')
    parser.add_argument('-i', '--input', dest='file', required=True, help='Path to the HDF5 file')
    parser.add_argument('--show', metavar='WHAT', help='Show structure (use "STRUCTURE") or datasets in a specific group name')
    parser.add_argument('-o', '--dump_group_to_hdf5', metavar='GROUP', help='Dump the specified group to a new HDF5 file (output will be GROUP.h5 in the same directory as input)')
    parser.add_argument('--dump_all_groups', action='store_true', help='Export all top-level groups in the input file to separate HDF5 files')
    args = parser.parse_args()

    if args.dump_all_groups:
        dump_all_groups_to_hdf5(args.file)
        return

    if args.dump_group_to_hdf5:
        input_dir = os.path.dirname(os.path.abspath(args.file))
        groupname = args.dump_group_to_hdf5
        source_basename = os.path.splitext(os.path.basename(args.file))[0]
        output_dir = os.path.join(input_dir, source_basename)
        os.makedirs(output_dir, exist_ok=True)
        outfile = os.path.join(output_dir, f"{groupname}.h5")
        dump_group_to_hdf5(args.file, groupname, outfile)
        return

    if args.show:
        if args.show.upper() == 'STRUCTURE':
            print_h5_structure(args.file)
        else:
            show_group_datasets(args.file, args.show)
    else:
        print_h5_structure(args.file)
            

if __name__ == "__main__":
     main()
