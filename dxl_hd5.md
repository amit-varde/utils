# dxl_hd5.py Documentation

## Overview
`dxl_hd5.py` is a command-line utility for inspecting, extracting, and exporting groups and datasets from HDF5 files. It is designed for data scientists and engineers who work with large or complex HDF5 files and need to:
- Explore file structure and metadata
- Preview and extract datasets
- Export groups to new HDF5 files
- Convert 2D datasets to CSV

---

## Setup

### Requirements
- Python 3.x
- [h5py](https://pypi.org/project/h5py/)
- [pandas](https://pypi.org/project/pandas/)

Install dependencies (if not already installed):
```sh
pip install h5py pandas
```

---

## Usage

### Show the structure of an HDF5 file
```sh
python dxl_hd5.py -i input.h5 --show STRUCTURE
```

### Show all datasets in a specific group
```sh
python dxl_hd5.py -i input.h5 --show groupname
```

### Export a specific group to a new HDF5 file
```sh
python dxl_hd5.py -i input.h5 -o groupname
# Output: ./<input_basename>/groupname.h5
```

### Export all top-level groups to separate HDF5 files
```sh
python dxl_hd5.py -i input.h5 --dump_all_groups
# Output: ./<input_basename>/<groupname>.h5 for each group
```

### Extract the first 2D dataset to CSV
```sh
python dxl_hd5.py -i input.h5 | tee output.csv
```

---

## Arguments
- `-i`, `--input`                Path to the HDF5 file (required)
- `--show WHAT`                  Show structure (use "STRUCTURE") or datasets in a specific group name
- `-o`, `--dump_group_to_hdf5`   Dump the specified group to a new HDF5 file (output will be GROUP.h5 in a subdirectory)
- `--dump_all_groups`            Export all top-level groups in the input file to separate HDF5 files

---

## Expected Input/Output

### Input
- An HDF5 file with one or more groups and datasets. The file can be large and complex, with nested groups and attributes.

### Output
- **Structure/Preview:** Prints the structure, groups, datasets, shapes, dtypes, and attributes to stderr.
- **CSV Extraction:** Writes the first 2D dataset found to stdout as CSV.
- **Group Export:** Creates new HDF5 files for specified groups in a subdirectory named after the input file (without extension).
- **All Groups Export:** Creates new HDF5 files for all top-level groups in the same subdirectory.

---

## Example
Suppose you have a file `data/03.h5` with groups `circuit_0`, `circuit_1`, ...

- To export all groups:
  ```sh
  python dxl_hd5.py -i data/03.h5 --dump_all_groups
  # Output: data/03/circuit_0.h5, data/03/circuit_1.h5, ...
  ```
- To show the structure:
  ```sh
  python dxl_hd5.py -i data/03.h5 --show STRUCTURE
  ```
- To extract a group:
  ```sh
  python dxl_hd5.py -i data/03.h5 -o circuit_0
  # Output: data/03/circuit_0.h5
  ```

---

## Notes
- The script prints structure and preview information to stderr, so you can redirect stdout for data extraction.
- Output HDF5 files are always written to a subdirectory named after the input file (without extension).
- For very large files, exporting groups is efficient and avoids loading the entire file into memory.

---
