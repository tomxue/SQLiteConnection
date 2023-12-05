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

param($ProjectName, $IntermediateOutputPath, $OutDir, $PublishDir, $LinuxRID = 'debian.11', $OsxRID = 'osx.11')

$ProjectName = "SQLiteConnection"
$OutDir = "Out"
$PublishDir = "MyPublish"

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$compatiblePSEdition = 'Core'
$PowerShellVersion = '7.2'

trap
{
	throw $PSItem
}

function Get-SingleNodeValue([System.Xml.XmlDocument]$doc,[string]$path)
{
	return $doc.SelectSingleNode($path).FirstChild.Value
}

$xmlDoc = [System.Xml.XmlDocument](Get-Content "$ProjectName.csproj")

$ModuleId = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/PackageId'
$Version = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Version'
$ProjectUri = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/PackageProjectUrl'
$Description = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Description'
$Author = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Authors'
$Copyright = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Copyright'
$AssemblyName = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/AssemblyName'
$CompanyName = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Company'

$SQLZIP = "sqlite-netStandard20-binary-$Version.zip"
$WINZIP = "SQLite.Interop-$Version-win.zip"
$LINUXZIP = "SQLite.Interop-$Version-$LinuxRID.zip"
$OSXZIP = "SQLite.Interop-$Version-$OsxRID.zip"
$SQLINTEROP = "SQLite.Interop.dll"

$SQLURL = "https://system.data.sqlite.org/blobs"
$WINURL = "https://github.com/rhubarb-geek-nz/SQLite.Interop-win/releases/download"
$OSXURL = "https://github.com/rhubarb-geek-nz/SQLite.Interop/releases/download"

foreach ($SRC in @($SQLZIP, $SQLURL, "$PublishDir/sqlite-netStandard20-binary"), @($WINZIP, $WINURL, $PublishDir), @($OSXZIP, $OSXURL, $PublishDir),@($LINUXZIP, $OSXURL, $PublishDir))
{
	$ZIP = $SRC[0]
	$URL = $SRC[1]
	$DEST = $SRC[2]

	if (-not(Test-Path "$IntermediateOutputPath$ZIP"))
	{
		Invoke-WebRequest -Uri "$URL/$Version/$ZIP" -OutFile "$IntermediateOutputPath$ZIP"
	}

	Expand-Archive -LiteralPath "$IntermediateOutputPath$ZIP" -DestinationPath $DEST
}

foreach ($A in 'x64', 'arm64', 'x86', 'arm')
{
	foreach ($B in @($LinuxRID, 'linux', 'so'), @($OsxRID, 'osx', 'dylib'), @('win', 'win', 'dll'))
	{
		$SRC = $B[0]
		$DEST = $B[1]
		$EXT = $B[2]

		if (Test-Path "$PublishDir/runtimes/$SRC-$A/native/$SQLINTEROP")
		{
			$null = New-Item -Path $PublishDir -Name "$DEST-$A" -ItemType 'directory'

			Write-Output "tomxue - 1"
			Write-Output $PublishDir/runtimes/$SRC-$A/native/$SQLINTEROP 
			Write-Output $PublishDir$DEST-$A/$SQLINTEROP.$EXT
			$null = Move-Item -Path "$PublishDir/runtimes/$SRC-$A/native/$SQLINTEROP" -Destination "$PublishDir/$DEST-$A/$SQLINTEROP.$EXT"
		}
	}
}

$null = Move-Item -Path "$PublishDir/sqlite-netStandard20-binary/System.Data.SQLite.dll" -Destination $PublishDir

$moduleSettings = @{
	Path = "$OutDir$ModuleId.psd1"
	RootModule = "$AssemblyName.dll"
	ModuleVersion = $Version
	Guid = 'e8e28b5f-a18e-4630-a957-856baefed648'
	Author = $Author
	CompanyName = $CompanyName
	Copyright = $Copyright
	Description = $Description
	PowerShellVersion = $PowerShellVersion
	CompatiblePSEditions = @($compatiblePSEdition)
	FunctionsToExport = @()
	CmdletsToExport = @("New-$ProjectName")
	VariablesToExport = '*'
	AliasesToExport = @()
	ProjectUri = $ProjectUri
}

function Get-IdentedString {
    <#
    .SYNOPSIS
    Returns $obj as indented string
    .DESCRIPTION
    Turns $obj to string and adds $indent * 4 spaces in front of it
    .PARAMETER obj
    Object to be converted to String
    .PARAMETER indent
    How many whitespaces * 4 to indent
    .EXAMPLE
    Get-IdentedString "Test" 1
    >>> "    Test"
    #>
    param (
        $obj,
        [int]$indent = 0
    )
    return "{0,$($indent *4)}{1}" -f "", $obj
}

function Convert-Array ($obj, [int]$indent = 0, [switch]$SkipIndentOnce) {
    if ($SkipIndentOnce) {
        $out += Get-IdentedString "@(`n" -indent 0
    }
    else {
        $out = Get-IdentedString "@(`n" -indent $indent
    }
    foreach ($elem in $obj) {
        $out += Convert-Element -obj $elem -indent $($indent + 1)
        $out += "`n"
    }
    $out += Get-IdentedString ")" -indent $indent
    return $out
}

function Convert-Int ($obj, [int]$indent = 0, [switch]$SkipIndentOnce) {
    if ($SkipIndentOnce) {
        return Get-IdentedString "$obj" -indent 0
    }
    else {
        return Get-IdentedString "$obj" -indent $indent
    }
}

function Convert-String ($obj, [int]$indent = 0, [switch]$SkipIndentOnce) {
    if ($SkipIndentOnce) {
        return Get-IdentedString "`"$obj`"" -indent 0
    }
    else {
        return Get-IdentedString "`"$obj`"" -indent $indent
    }
}

function Convert-Element {
    param (
        $obj,
        [int]$indent = 0,
        [switch]$SkipIndentOnce
    )
    $paramObj = @{
        obj    = $obj
        indent = $indent
    }
    if ($SkipIndentOnce) {
        $paramObj["SkipIndentOnce"] = $true
    }
    switch -Regex ($obj.GetType().Name) {
        "Object\[\]" {return Convert-Array @paramObj}
        "Hashtable" {return Convert-Hashtable @paramObj}
        'Int\d+' {return Convert-Int @paramObj}
        default {return Convert-String @paramObj}
    }
}

function Convert-Hashtable ($obj, $indent = 0, [switch]$SkipIndentOnce) {
    if ($SkipIndentOnce) {
        return Get-IdentedString "@{`n" -indent 0
    }
    else {
        $out = Get-IdentedString "@{`n" -indent $indent
    }
    $indent += 1
    foreach ($key in $obj.Keys) {
        $out += Convert-Element -obj $key -indent $indent
        $out += " = "
        $out += Convert-Element -obj $obj[$key] -indent $indent -SkipIndentOnce
        $out += "`n"
    }
    $indent -= 1
    $out += Get-IdentedString "}`n" -indent $indent
    return $out
}

function Export-PowerShellDataFile {
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)
        ]$Obj,
        $Path,
        [switch]$NoClobber
    )

    if ($Path) {
        if ($NoClobber -and $(Test-Path $Path)) {
            Write-Error "File exists" -ErrorAction Stop
        }

        Convert-Element -obj $Obj | Out-File $Path
    }
    else {
        Convert-Element -obj $Obj | Write-Output
    }
}

New-ModuleManifest @moduleSettings

Import-PowerShellDataFile -LiteralPath "$OutDir$ModuleId.psd1" | Export-PowerShellDataFile | Set-Content -LiteralPath "$PublishDir$ModuleId.psd1"

(Get-Content "./README.md")[0..2] | Set-Content -Path "$PublishDir/README.md"
