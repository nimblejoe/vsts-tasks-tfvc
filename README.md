Version AssemblyInfo files for MSBuild
====

* * *
### About

- Version: 1.0.0

- This TFS vNext Build task enables you to version your .Net Assemblies during the build by updating the AssemblyInfo file with the build number.  Optionally, you can check in the updated AssemblyInfo files into TFVC.



### Requirements for this task
- **Powershell :** This plugin requires that the Powershell TFS Cmdlets are installed in the build server.  This can be installed as part of the TFS Powertools installation.

	>***Note:** The Powershell Cmdlets are not installed by default with Powertools.  You may need to run the installer a second time and specify that you want the Cmdlets added.*

- **Build Number Format :**  The build number format found on the General tab of the Build Definition must follow this pattern: <br />

	`BuildDefinitionName_BuildPart.BuildRevision` (Both BuildPart and BuildRevision are integers) <br />

	The example Build Number Format below will create an auto-incrementing build number for you: <br />
`$(BuildDefinitionName)_$(Year:yy)$(DayOfYear)$(Rev:.rr)`

	Example output:  MyBuildDefinition_16187.01
    

- **AssemblyInfo File :**  To update the AssemblyVersion and/or AssemblyFileVersion, the initial version pattern in the file must match the default format of d.d.d.d (where d represents a valid integer).  By default, AssemblyInfo files contain the following two lines:<br />
[assembly: AssemblyVersion `("1.0.0.0")`]<br />
[assembly: AssemblyFileVersion`("1.0.0.0")`]

	We recommend accepting these default values to start with.

### Parameters for Assembly Versioning build task
- **Major Version :**  This is a required field.  Must be an integer value.

- **Minor Version :**  This is a required field.  Must be an integer value.

- **Checkin AssemblyInfo :**  This is a checkbox to indicate whether or not the AssemblyInfo files are checked into source control with the updated assembly version.  If unchecked, the assemblies in the build output will be updated with the new version, but AssemblyInfo files in the source will not change.


### Additional Information
- This task must occur prior to the Visual Studio Build Task
- Optionally you can use vso build variables for the Major and Minor versions for additional flexibility


