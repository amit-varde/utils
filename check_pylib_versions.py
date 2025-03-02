import pkg_resources
import importlib.metadata
import os

# Read the requirements file
requirements_file = "requirements.txt"

if not os.path.exists(requirements_file):
    print(f"Error: {requirements_file} not found!")
    exit(1)

with open(requirements_file, "r") as file:
    required_packages = {}
    for line in file:
        line = line.strip()
        if "==" in line:  # Expecting format 'package==version'
            pkg, version = line.split("==")
            required_packages[pkg.lower()] = version

# Get installed packages and their versions
installed_packages = {dist.metadata["Name"].lower(): dist.version for dist in importlib.metadata.distributions()}

# Compare versions
print("\nChecking package versions...\n")
missing=0
mismatch=0
uptodate=0
for pkg, required_version in required_packages.items():
    installed_version = installed_packages.get(pkg)
    
    if installed_version is None:
        print(f"MISSING: {pkg} is MISSING (Required: {required_version})")
        missing=missing+1
    elif installed_version != required_version:
        print(f"MISMATCH:  {pkg} version mismatch (Installed: {installed_version}, Required: {required_version})")
        mismatch=mismatch+1
    else:
        print(f"UPTODATE: {pkg} is up-to-date ({installed_version})")
        uptodate=uptodate+1

print("\nVersion check complete!")
print("Missing =", missing)
print("Mismatched=",mismatch)
print("UpToDate=", uptodate)

