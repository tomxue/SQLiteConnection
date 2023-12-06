<#
.SYNOPSIS
Read SQLite Database using PSSQLite

.DESCRIPTION
This script demonstrates how to read data from a SQLite database using PSSQLite module in PowerShell.

.NOTES
- This script requires the PSSQLite module to be installed. You can install it using the following command:
    Install-Module -Name PSSQLite

- This script assumes that the SQLite database file is located in the current working directory.

#>

# Import the PSSQLite module
Import-Module -Name PSSQLite

# Function to read SQLite database
function Read-SQLiteDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DatabasePath
    )

    try {
        # Check if the SQLite database file exists
        if (-not (Test-Path -Path $DatabasePath)) {
            throw "SQLite database file not found."
        }

        # Connect to the SQLite database
        $connectionString = "Data Source=$DatabasePath"
		$ConStrSecure = ConvertTo-SecureString "Data Source=$DatabasePath;" -AsPlainText -Force
        $connection = New-SQLiteConnection ConnectionString $ConStrSecure

        # Open the connection
        $connection.Open()

        # Create a SQL query to retrieve data from a table
        $query = "SELECT * FROM MESSAGES"

        # Create a command object
        $command = New-SQLiteCommand -Connection $connection -CommandText $query

        # Execute the query and retrieve the data
        $data = $command.ExecuteReader()

        # Process the data
        while ($data.Read()) {
            # Access the columns by name or index
            $column1 = $data["CONTENT"]
            $column2 = $data[1]

            # Do something with the data
            Write-Output "Column1: $column1, Column2: $column2"
        }

        # Close the data reader
        $data.Close()

        # Close the connection
        $connection.Close()
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

# Example usage
try {
    # Specify the path to the SQLite database file
    $databasePath = "D:\workspace\Vantage\arm64-transplant\SQLiteConnection\test.db"

    # Call the function to read the SQLite database
    Read-SQLiteDatabase -DatabasePath $databasePath
}
catch {
    Write-Error "Failed to read the SQLite database."
}