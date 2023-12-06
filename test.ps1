#!/usr/bin/env pwsh
#
#  Copyright 2023, Roger Brown
#
#  This file is part of rhubarb-geek-nz/SQLiteConnection.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

param(
	$ConnectionString = 'Data Source=test.db;',
	$CommandText = 'SELECT * FROM MESSAGES'
)

# Import the PSSQLite module
Import-Module -Name PSSQLite

$ErrorActionPreference = "Stop"

trap
{
	throw $PSItem
}

if (-not(Test-Path "test.db"))
{
	@"
CREATE TABLE MESSAGES (CONTENT VARCHAR(256));
INSERT INTO MESSAGES (CONTENT) VALUES ('Hello World');
"@ | & C:\Users\xuejd1\AppData\Local\anaconda3\Library\bin\sqlite3.exe test.db

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}
}

$ConStrSecure = ConvertTo-SecureString 'Data Source=D:\workspace\Vantage\arm64-transplant\SQLiteConnection\test.db;' -asplaintext -force
$Connection = New-SQLiteConnection ConnectionString $ConStrSecure

try
{
	$Connection.Open()

	$Command = $Connection.CreateCommand()

	$Command.CommandText = $CommandText
	# $Command.CommandText = 'SELECT * FROM MESSAGES'

	$Reader = $Command.ExecuteReader()

	try
	{
		$DataTable = New-Object System.Data.DataTable

		$DataTable.Load($Reader)

		$DataTable | Format-Table
	}
	finally
	{
		$Reader.Dispose()
	}
}
finally
{
	$Connection.Dispose()
}
