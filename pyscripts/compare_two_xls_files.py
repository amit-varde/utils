import pandas as pd
import argparse

def read_excel(file_path, sheet_name=0):
    """
    Reads an Excel file and returns a DataFrame.
    
    :param file_path: Path to the Excel file.
    :param sheet_name: Name or index of the sheet to read.
    :return: DataFrame containing the sheet data.
    """
    return pd.read_excel(file_path, sheet_name=sheet_name)

def compare_sheets(df1, df2):
    """
    Compares two DataFrames and returns the differences.
    
    :param df1: First DataFrame.
    :param df2: Second DataFrame.
    :return: DataFrame containing the differences.
    """
    comparison_df = df1.compare(df2)
    return comparison_df

def main(file1, file2, sheet_name1=0, sheet_name2=0):
    """
    Main function to compare two Excel sheets.
    
    :param file1: Path to the first Excel file.
    :param file2: Path to the second Excel file.
    :param sheet_name1: Name or index of the sheet in the first file.
    :param sheet_name2: Name or index of the sheet in the second file.
    """
    df1 = read_excel(file1, sheet_name1)
    df2 = read_excel(file2, sheet_name2)
    
    differences = compare_sheets(df1, df2)
    
    if differences.empty:
        print("The sheets are identical.")
    else:
        print("Differences found:")
        print(differences)

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Compare two Excel sheets.")
    parser.add_argument("file1", help="Path to the first Excel file.")
    parser.add_argument("file2", help="Path to the second Excel file.")
    parser.add_argument("--sheet1", default=0, help="Sheet name or index in the first file.")
    parser.add_argument("--sheet2", default=0, help="Sheet name or index in the second file.")
    
    args = parser.parse_args()
    
    main(args.file1, args.file2, args.sheet1, args.sheet2)