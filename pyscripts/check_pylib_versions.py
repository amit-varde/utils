import argparse
"""
check_pylib_versions.py
This script checks the installed Python packages against the versions specified in a requirements.txt file. 
It reads the required packages and their versions from the specified requirements file, compares them with the installed packages, 
and reports any missing or mismatched versions. The results can be printed to the console and optionally saved to an output file in text or CSV format.
Usage examples:
    python check_pylib_versions.py -f /path/to/requirements.txt
    python check_pylib_versions.py -d /path/to/directory
    python check_pylib_versions.py -f /path/to/requirements.txt -o /path/to/output.txt
    python check_pylib_versions.py -f /path/to/requirements.txt -o /path/to/output.csv
    python check_pylib_versions.py -f /path/to/requirements.txt -s -o /path/to/output.txt
    python check_pylib_versions.py -f /path/to/requirements.txt -s -o /path/to/output.csv

Options:
    -f, --file       Path to requirements.txt
    -d, --directory  Path to directory containing requirements.txt
    -o, --output     Path to output file (text or CSV format)
    -s, --silent     Silent mode. Do not print summary to console. Requires -o option.
"""
import importlib.metadata
import os
import csv
import getpass
from datetime import datetime

def read_requirements(file_path):
    """Reads a requirements.txt file and returns a dictionary of packages and their required versions."""
    required_packages = {}
    try:
        with open(file_path, "r") as file:
            for line in file:
                line = line.strip()
                if "==" in line:  # Expecting format 'package==version'
                    pkg, version = line.split("==")
                    required_packages[pkg.lower()] = version
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        exit(1)
    return required_packages

def find_installed_versions(required_packages):
    """Finds installed versions of required packages."""
    return {dist.metadata["Name"].lower(): dist.version for dist in importlib.metadata.distributions()}

def compare_versions(required_packages, installed_packages):
    """Compares installed packages against required versions."""
    compared_versions = {
        "missing": [],
        "mismatch": [],
        "uptodate": []
    }
    
    for pkg, required_version in required_packages.items():
        installed_version = installed_packages.get(pkg)
        if installed_version is None:
            compared_versions["missing"].append(pkg)
        elif installed_version != required_version:
            compared_versions["mismatch"].append(pkg)
        else:
            compared_versions["uptodate"].append(pkg)
    
    return compared_versions

def print_summary(compared_versions, required_packages, installed_packages,args):
    """Prints a summary of the version check results."""
    user = getpass.getuser()
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    script_name = os.path.basename(__file__)
    options = " ".join([f"{k}={v}" for k, v in vars(args).items() if v])

    header = [
        f"=================================================",
        f"User: {user}",
        f"Timestamp: {timestamp}",
        f"Script: {script_name}",
        f"Options: {options}",
        f"=================================================",
        "\nVersion check complete!"
    ]

    summary = header + [
        f"Missing Packages = {len(compared_versions['missing'])}",
        "\n".join([f"{pkg} (Required: {required_packages[pkg]})" for pkg in compared_versions['missing']]),
        f"Mismatched Packages = {len(compared_versions['mismatch'])}",
        "\n".join([f"{pkg} (Installed: {installed_packages[pkg]}, Required: {required_packages[pkg]})" for pkg in compared_versions['mismatch']]),
        f"UpToDate Packages = {len(compared_versions['uptodate'])}",
        "\n".join([f"{pkg} (Installed: {installed_packages[pkg]})" for pkg in compared_versions['uptodate']]),
    ]

    print("\n".join(summary))

def write_output_text(output_path, compared_versions, required_packages, installed_packages, args):
    """Writes the results to the specified output file in text format."""
    user = getpass.getuser()
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    script_name = os.path.basename(__file__)
    options = " ".join([f"{k}={v}" for k, v in vars(args).items() if v])

    header = [
        f"=================================================",
        f"User: {user}",
        f"Timestamp: {timestamp}",
        f"Script: {script_name}",
        f"Options: {options}",
        f"=================================================",
        "\nVersion check complete!"
    ]

    summary = header + [
        f"Missing Packages = {len(compared_versions['missing'])}",
        "\n".join([f"{pkg} (Required: {required_packages[pkg]})" for pkg in compared_versions['missing']]),
        f"Mismatched Packages = {len(compared_versions['mismatch'])}",
        "\n".join([f"{pkg} (Installed: {installed_packages[pkg]}, Required: {required_packages[pkg]})" for pkg in compared_versions['mismatch']]),
        f"UpToDate Packages = {len(compared_versions['uptodate'])}",
        "\n".join([f"{pkg} (Installed: {installed_packages[pkg]})" for pkg in compared_versions['uptodate']]),
    ]

    try:
        with open(output_path, "w") as f:
            f.write("\n".join(summary) + "\n")
        print(f"Results saved to {output_path}")
    except Exception as e:
        print(f"Error writing to output file: {e}")
        
def write_output_csv(output_path, compared_versions, required_packages, installed_packages, args):
    """Writes the results to the specified output file in CSV format."""
    user = getpass.getuser()
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    script_name = os.path.basename(__file__)
    options = " ".join([f"{k}={v}" for k, v in vars(args).items() if v])

    header = [
        ["User", user],
        ["Timestamp", timestamp],
        ["Script", script_name],
        ["Options", options],
        ["Version check complete!"]
    ]

    rows = [
        *[[pkg, "None", required_packages[pkg], "MISSING"] for pkg in compared_versions['missing']],
        *[[pkg, installed_packages[pkg], required_packages[pkg], "MISMATCH"] for pkg in compared_versions['mismatch']],
        *[[pkg, installed_packages[pkg], required_packages[pkg], "UPTODATE"] for pkg in compared_versions['uptodate']],
    ]

    try:
        with open(output_path, "w", newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerows(rows)
        print(f"Results saved to {output_path}")
    except Exception as e:
        print(f"Error writing to output file: {e}")


                
def main():
    parser = argparse.ArgumentParser(description="Check installed Python packages against a requirements file.")
    parser.add_argument("-f", "--file", type=str, help="Path to requirements.txt")
    parser.add_argument("-d", "--directory", type=str, help="Path to directory containing requirements.txt")
    parser.add_argument("-o", "--output", type=str, help="Path to output file")
    parser.add_argument("-s", "--silent", action="store_true", help="Silent mode. Do not print summary to console.")
    
    args = parser.parse_args()

    """ Add All kinds of checks here to ensure that the user has provided the correct input """
    if args.file and args.directory:
        print("Error: You cannot specify both -f <file> and -d <directory> at the same time.")
        exit(1)
    
    if args.silent and not args.output:
        print("Error: When using silent mode (-s), you must specify an output file with -o.")
        exit(1)
    
    """ Process Inputs """
    if args.directory:
        requirements_path = os.path.join(args.directory, "requirements.txt")
        if not os.path.exists(requirements_path):
            print(f"Error: requirements.txt not found in {args.directory}!")
            exit(1)
        print(f"Found requirements.txt at {requirements_path}. Running check...")
    elif args.file:
        requirements_path = args.file
        if not os.path.exists(requirements_path):
            print(f"Error: {requirements_path} not found!")
            exit(1)
    else:
        print("Error: You must specify either -f <file> or -d <directory>")
        exit(1)
    
    required_packages = read_requirements(requirements_path)
    installed_packages= find_installed_versions(required_packages)
    compared_versions = compare_versions(required_packages, installed_packages)

    if not args.silent:
        if not args.output or args.output == "STDOUT":
            print_summary(compared_versions, required_packages, installed_packages, args)
        else:
            if args.output:
                if args.output.lower().endswith(".csv"):
                    write_output_csv(args.output, compared_versions, required_packages, installed_packages, args)
                else:
                    write_output_text(args.output, compared_versions, required_packages, installed_packages, args)
    else:
        if args.output:
            if args.output.lower().endswith(".csv"):
                write_output_csv(args.output, compared_versions, required_packages, installed_packages, args)
            else:
                write_output_text(args.output, compared_versions, required_packages, installed_packages, args)


if __name__ == "__main__":
    main()
