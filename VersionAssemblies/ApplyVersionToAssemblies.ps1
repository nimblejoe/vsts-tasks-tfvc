##-----------------------------------------------------------------------
## Adapted from http://TfsBuildExtensions.codeplex.com/. This source is subject to the Microsoft Permissive License. See http://www.microsoft.com/resources/sharedsource/licensingbasics/sharedsourcelicenses.mspx. All other rights reserved.
##-----------------------------------------------------------------------
# Look for the following pattern in the Build Number '{name}_{number}.{revision}' 
# If found append it to the existing Major and minor version specified on the Assemblies with the AssemblyVersion attribute.
# Updates/Adds the following attributes to all AssemblyInfo.cs files:
#   AssemblyVersion("{current}.{current}.{number}.{revision}")
#   AssemblyFileVersion("{current}.{current}.{number}.{revision}")
#   AssemblyInfoVersion("Built by {BuildNumber}")
#
# For example, if the 'Build number format' build process parameter 
# $(BuildDefinitionName)_$(Year:yy)$(DayOfYear)$(Rev:.r)
# then your build numbers come out like this:
# "Build HelloWorld_14256.1"
# This script would then apply version 14256.1 to your assemblies.
	
#Enable -Verbose option
[CmdletBinding()]
	
# Disable parameter
# Convenience option so you can debug this script or disable it in 
# your build definition without having to remove it from
# the 'Post-build script path' build process parameter.
param([switch]$Disable, $Major, $Minor, [string]$Checkin)

$provider = Get-SourceProvider

if ($PSBoundParameters.ContainsKey('Disable'))
{
	Write-Verbose "Script disabled; no actions will be taken on the files." -verbose
}

if ($Checkin -eq "false")
{
	Write-Verbose "The Checkin option was not set so AssemblyInfo files will not be checked into source control." -verbose
}


Write-Verbose "Sources Directory $($Env:BUILD_SOURCESDIRECTORY)" -verbose
Write-Verbose "Collection $($Env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)" -verbose

if($PSBoundParameters.ContainsKey('Checkin'))
{
	try
	{
		add-pssnapin Microsoft.TeamFoundation.PowerShell
	}
	catch
	{
		Write-Verbose "Could not add the Powershell snapin for TFS commands.  Powertools must be installed on the build server for the corresponding version of Visual Studio being used.  A re-install of Powertools on the build server may be required." -verbose
	}
}

	
# Regular expression pattern to find the version in the build number 
# and then apply it to the assemblies
$BuildVersionRegex = "(.*)_(\d*)\.(\d*)"


# If this script is not running on a build server, remind user to 
# set environment variables so that this script can be debugged
if(-not ($Env:BUILD_SOURCESDIRECTORY -and $Env:BUILD_BUILDNUMBER))
{
	Write-Error "You must set the following environment variables"
	Write-Error "to test this script interactively."
	Write-Host '$Env:BUILD_SOURCESDIRECTORY - For example, enter something like:'
	Write-Host '$Env:BUILD_SOURCESDIRECTORY = "C:\code\FabrikamTFVC\HelloWorld"'
	Write-Host '$Env:BUILD_BUILDNUMBER - For example, enter something like:'
	Write-Host '$Env:BUILD_BUILDNUMBER = "Build HelloWorld_0000.00.00.0"'
	exit 1
}
	
# Make sure path to source code directory is available
if (-not $Env:BUILD_SOURCESDIRECTORY)
{
	Write-Error ("BUILD_SOURCESDIRECTORY environment variable is missing.")
	exit 1
}
elseif (-not (Test-Path $Env:BUILD_SOURCESDIRECTORY))
{
	Write-Error "BUILD_SOURCESDIRECTORY does not exist: $Env:BUILD_SOURCESDIRECTORY"
	exit 1
}
Write-Verbose "BUILD_SOURCESDIRECTORY: $Env:BUILD_SOURCESDIRECTORY" -verbose
	
# Make sure there is a build number
if (-not $Env:BUILD_BUILDNUMBER)
{
	Write-Error ("BUILD_BUILDNUMBER environment variable is missing.")
	exit 1
}

Write-Verbose "BUILD_BUILDNUMBER: $Env:BUILD_BUILDNUMBER" -verbose
	
# Get and validate the version data
$VersionData = [regex]::matches($Env:BUILD_BUILDNUMBER,$BuildVersionRegex)
switch($VersionData.Count)
{
   0		
      { 
         Write-Error "Could not find version number data in BUILD_BUILDNUMBER."
         exit 1
      }
   1 {}
   default 
      { 
         Write-Warning "Found more than instance of version data in BUILD_BUILDNUMBER." 
         Write-Warning "Will assume first instance is version."
      }
}

$BuildVersion = $($VersionData.Groups[2].Value)
$BuildRevision = $($VersionData.Groups[3].Value)
	
$NewVersion = "$($Major).$($Minor).$($BuildVersion).$($BuildRevision)"
Write-Verbose "New Version Number: $($NewVersion)" -verbose

# Apply the version to the assembly property files
$files = gci $Env:BUILD_SOURCESDIRECTORY -recurse -include "*Properties*","My Project" | 
	?{ $_.PSIsContainer } | 
	foreach { gci -Path $_.FullName -Recurse -include AssemblyInfo.* }

# Array for holding the AssemblyInfo file names which will be used to create one changeset when checking them back in to source control
$filesToCheckIn = @()

if($files)
{
	Write-Verbose "Will apply $NewVersion to $($files.count) files." -verbose
		
	foreach ($file in $files) {
			
			
		if(-not $Disable)
		{
			$filesToCheckIn += $file.FullName

			#If the Checkin parameter is specified, checkout the file to be modified
			if ($Checkin -eq "true")
			{
				Add-TfsPendingChange -Edit $file.FullName | Out-Null
			}

			$filecontent = Get-Content($file)
           
            $Version_File_Regex = "\d+\.\d+\.\d+\.\d+"

            # Output the updated content to the original file (first make sure it's writeable)
			attrib $file -r
            $filecontent -replace $Version_File_Regex, $NewVersion | Out-File $file
			Write-Host "Version $NewVersion applied to file $($file.FullName)"
		}
	}


	# If the Checkin parameter is specified, check in the updated AssemblyInfo files
	if ($Checkin -eq "true")
	{
		Write-Verbose "Checking in Assembly" -verbose
		New-TfsChangeset -Item $filesToCheckIn -Verbose -Comment "***Update assembly version number - $($NewVersion) ***" -Override true
	}
}
else
{
	Write-Warning "Found no files."
}

