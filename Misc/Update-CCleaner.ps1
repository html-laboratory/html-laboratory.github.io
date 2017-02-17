#Requires -version 5
<#
	.SYNOPSIS
	Update or install CCleaner.
	<Update-CCleaner.ps1> [-Auto] [-Force]

	.DESCRIPTION
	# [about_Execution_Policies](http://go.microsoft.com/fwlink/?LinkID=135170)
	"Run as Administrator" PowerShell
	`Unblock-File '<Update-CCleaner.ps1>'`
	PowerShell or Command Prompt or Run
	`PowerShell -ExecutionPolicy RemoteSigned "<Update-CCleaner.ps1>" [-Auto] [-Force]`
	# Registration to Task Scheduler
	PowerShell (Recommend)
	`Register-ScheduledTask 'Update-CCleaner.ps1' -Trigger $(New-ScheduledTaskTrigger -Weekly -At '00:00:00' -RandomDelay $([TimeSpan]::FromSeconds(30))) -Settings $(New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -ExecutionTimeLimit $([TimeSpan]::FromHours(1)) -Hidden -StartWhenAvailable -Compatibility 'Win8') -Action $(New-ScheduledTaskAction -Execute "${PSHOME}\powershell.exe" -Argument '-ExecutionPolicy RemoteSigned -WindowStyle Hidden "<Update-CCleaner.ps1>" -Auto')`
	Command Prompt or Run
	`schtasks /create /tn "Update-CCleaner" /sc weekly /st 00:00 /tr "'%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe' -ExecutionPolicy RemoteSigned -WindowStyle Hidden '<Update-CCleaner.ps1>' -Auto"`

	.EXAMPLE
	./Update-CCleaner.ps1
	Update or install CCleaner. The script will not end unless press Enter key at end.

	.EXAMPLE
	./Update-CCleaner.ps1 -Auto
	Update or install CCleaner. The script will end automatically.

	.EXAMPLE
	./Update-CCleaner.ps1 -Force
	Update or install CCleaner. Forcibly proceed with decompression.

	.INPUTS
	None. You cannot pipe objects to Update-CCleaner.ps1

	.OUTPUTS
	System.Byte

	The cmdlet returns a Byte value.
#>
Param(
	[Management.Automation.SwitchParameter]$Auto,
	[Management.Automation.SwitchParameter]$Force
)
&{
	Set-StrictMode -Version Latest
	[Int32]$ErrorCount=0
	[Byte]$ExitCode=0
	Set-Location $PSScriptRoot
	$DLFiles=@{
		'CCleaner'=@{
			'Url'='https://www.piriform.com/ccleaner/download/portable/downloadfile'
			'FullName'=Join-Path $Env:TEMP 'ccsetup.zip'
		};
		'Winapp2'=@{
			'Url'='https://raw.githubusercontent.com/MoscaDotTo/Winapp2/master/Winapp2.ini'
			'FullName'=Join-Path $PWD.Path 'Winapp2.ini'
		}
	}
	$DLFiles.GetEnumerator()|ForEach-Object {
		Write-Host "Downloading $($_.Value.Url) -> $($_.Value.FullName)"
		Invoke-WebRequest $_.Value.Url -OutFile $_.Value.FullName
	}
	if($ErrorCount -eq $Error.Count){
		$ErrorCount=$Error.Count
		$Destination=New-Object 'System.Collections.Generic.Dictionary[String,String]'
		if($Force){
			$GuaranteeDirectory=New-Object 'System.Collections.Generic.Dictionary[String,Bool]'
		}
		Add-Type -Assembly 'System.IO.Compression.FileSystem'
		[IO.Compression.ZipArchive]$archive=[IO.Compression.ZipFile]::OpenRead($DLFiles.CCleaner.FullName)
		$archive.Entries|ForEach-Object {
			$Destination.FileName=Join-Path $PWD.Path $_.FullName
			Write-Host "Extracting $(Join-Path $DLFiles.CCleaner.FullName $_.FullName) -> $($Destination.FileName)"
			if($Force){
				$Destination.DirectoryName=Split-Path $Destination.FileName
				if($(Test-Path $Destination.FileName) -and $(Get-Item $Destination.FileName).PSIsContainer){
					Remove-Item $Destination.FileName -Force -Recurse
				}
				if(!$GuaranteeDirectory[$Destination.DirectoryName]){
					if(Test-Path $Destination.DirectoryName){
						if(Get-Item $Destination.DirectoryName|Where-Object{
							$_.PSIsContainer
						}){
							$GuaranteeDirectory[$Destination.DirectoryName]=$True
						}else{
							Remove-Item $Destination.DirectoryName -Force
							New-Item $Destination.DirectoryName -ItemType Directory
						}
					}else{
						New-Item $Destination.DirectoryName -ItemType Directory
					}
				}
			}
			[IO.Compression.ZipFileExtensions]::ExtractToFile($_,$Destination.FileName,$True)
		}
		$archive.Dispose();
	}else{
		$ExitCode+=1
	}
	if($ErrorCount -ne $Error.Count){
		$ExitCode+=2;
	}
	$ErrorCount=$Error.Count
	Write-Host "Removing $($DLFiles.CCleaner.FullName)"
	Remove-Item $DLFiles.CCleaner.FullName -Force
	if($ErrorCount -ne $Error.Count){
		$ExitCode+=4;
	}
	if($ExitCode){
		Write-Host 'Update was incomplete'
	}else{
		Write-Host 'Update successed!'
	}
	if(!$Auto){
		Write-Host 'Press Enter key . . . '
		[Console]::ReadKey()|Out-Null
	}
	$ExitCode
}