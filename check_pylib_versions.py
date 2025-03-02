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

Note: The CSV output function is not working as yet.
"""
import importlib.metadata
import os
import csv

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

def check_versions(required_packages):
    """Checks installed packages against required versions."""
    installed_packages = {dist.metadata["Name"].lower(): dist.version for dist in importlib.metadata.distributions()}
    results = []
    missing, mismatch, uptodate = 0, 0, 0
    
    for pkg, required_version in required_packages.items():
        installed_version = installed_packages.get(pkg)
        if installed_version is None:
            results.append(f"MISSING: {pkg} is MISSING (Required: {required_version})")
            missing += 1
        elif installed_version != required_version:
            results.append(f"MISMATCH: {pkg} version mismatch (Installed: {installed_version}, Required: {required_version})")
            mismatch += 1
        else:
            results.append(f"UPTODATE: {pkg} is up-to-date ({installed_version})")
            uptodate += 1
    
    summary = [
        "\nVersion check complete!",
        f"Missing = {missing}",
        f"Mismatched = {mismatch}",
        f"UpToDate = {uptodate}"
    ]
    results.extend(summary)
    return results

def write_output_text(output_path, results):
    """Writes the results to the specified output file in text format."""
    try:
        with open(output_path, "w") as f:
            f.write("\n".join(results) + "\n")
        print(f"Results saved to {output_path}")
    except Exception as e:
            print(f"Error writing to output file: {e}")
        
def write_output_csv(output_path, required_packages, results):
    """Writes the results to the specified output file in CSV format."""
    try:
        with open(output_path, "w", newline='') as csvfile:
            fieldnames = ['python_library_name', 'installed_version', 'required_version', 'status']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            
            for result in results:
                if result.startswith("MISSING"):
                    pkg, status = result.split(": ")
                    pkg_name, required_version = status.split(" is MISSING (Required: ")
                    writer.writerow({
                        'python_library_name': pkg_name,
                        'installed_version': 'None',
                        'required_version': required_version.rstrip(')'),
                        'status': 'MISSING'
                    })
                elif result.startswith("MISMATCH"):
                    pkg, status = result.split(": ")
                    pkg_name, versions = status.split(" version mismatch (Installed: ")
                    installed_version, required_version = versions.split(", Required: ")
                    writer.writerow({
                        'python_library_name': pkg_name,
                        'installed_version': installed_version,
                        'required_version': required_version.rstrip(')'),
                        'status': 'MISMATCH'
                    })
                elif result.startswith("UPTODATE"):
                    pkg, status = result.split(": ")
                    pkg_name, installed_version = status.split(" is up-to-date (")
                    writer.writerow({
                        'python_library_name': pkg_name,
                        'installed_version': installed_version.rstrip(')'),
                        'required_version': required_packages[pkg_name.lower()],
                        'status': 'UPTODATE'
                    })
            print(f"Results saved to {output_path}")
    except Exception as e:
                print(f"Error writing to output file: {e}")


                
def main():
    parser = argparse.ArgumentParser(description="Check installed Python packages against a requirements file.")
    parser.add_argument("-f", "--file", type=str, help="Path to requirements.txt")
    parser.add_argument("-d", "--directory", type=str, help="Path to directory containing requirements.txt")
    parser.add_argument("-o", "--output", type=str, help="Path to output file")
    
    args = parser.parse_args()

    """ Add All kinds of checks here to ensure that the user has provided the correct input """
    if args.file and args.directory:
        print("Error: You cannot specify both -f <file> and -d <directory> at the same time.")
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
    results = check_versions(required_packages)
    
    if not args.output or args.output == "STDOUT":
        for line in results:
            print(line)
    
    if args.output:
        if args.output.lower().endswith(".csv"):
            write_output_csv(args.output, required_packages, results)
        else:
            write_output_text(args.output, results)


if __name__ == "__main__":
    main()
