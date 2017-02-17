#Requires -version 3
<#
	.SYNOPSIS
	Change the desktop wallpaper in the background image of the top page of Bing.
	<Set-BingWallpaper.ps1> [[-Resolution] <String>]

	.DESCRIPTION
	# [about_Execution_Policies](http://go.microsoft.com/fwlink/?LinkID=135170)
	"Run as Administrator" PowerShell
	`Unblock-File '<Set-BingWallpaper.ps1>'`
	PowerShell or Command Prompt or Run
	`PowerShell -ExecutionPolicy RemoteSigned "<Set-BingWallpaper.ps1>" [[-Resolution] <String>]`
	# Registration to Task Scheduler
	PowerShell (Recommend)
	`Register-ScheduledTask 'Set-BingWallpaper' -Trigger $(New-ScheduledTaskTrigger -Daily -At '00:00:00' -RandomDelay $([TimeSpan]::FromSeconds(30))) -Settings $(New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -ExecutionTimeLimit $([TimeSpan]::FromHours(1)) -Hidden -StartWhenAvailable -Compatibility 'Win8') -Action $(New-ScheduledTaskAction -Execute "${PSHOME}\powershell.exe" -Argument '-ExecutionPolicy RemoteSigned -WindowStyle Hidden "<Set-BingWallpaper.ps1>" [[-Resolution] <String>]')`
	Command Prompt or Run
	`schtasks /create /tn "Set-BingWallpaper" /sc daily /st 00:00 /tr "'%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe' -ExecutionPolicy RemoteSigned -WindowStyle Hidden '<Set-BingWallpaper.ps1>' [[-Resolution] <String>]"`

	.PARAMETER Resolution
	Specifies the background color. Default is '1920x1080'. The acceptable values for this parameter are:

	-- 220x176 176x220
	-- 240x240
	-- 320x240 240x320
	-- 320x320
	-- 400x240 240x400
	-- 480x360 360x480
	-- 640x480 480x640
	-- 800x480 480x800
	-- 800x600
	-- 1024x768 768x1024
	-- 1280x720 720x1280
	-- 1280x768 768x1280
	-- 1366x768 768x1366
	-- 1920x1080 1080x1920
	-- 1920x1200 (with logo)

	.EXAMPLE
	./Set-BingWallpaper.ps1
	Set the wallpaper of 1920x1080 resolution.

	.EXAMPLE
	./Set-BingWallpaper.ps1 -Resolution 1366x768
	Set the wallpaper of 1366x768 resolution.

	.INPUTS
	None. You cannot pipe objects to Set-BingWallpaper.ps1.

	.OUTPUTS
	System.Boolean

	The cmdlet returns a Boolean value.
#>
Param(
	[ValidateSet(
		'220x176','176x220',
		'240x240',
		'320x240','240x320',
		'320x320',
		'400x240','240x400',
		'480x360','360x480',
		'640x480','480x640',
		'800x480','480x800',
		'800x600',
		'1024x768','768x1024',
		'1280x720','720x1280',
		'1280x768','768x1280',
		'1366x768','768x1366',
		'1920x1080','1080x1920',
		'1920x1200'
	)]
	[String]$Resolution='1920x1080'
)
&{
	Set-StrictMode -Version Latest
	[Int32]$ErrorCount=0
	[String]$Bing='www.bing.com'
	$ErrorCount=$Error.Count
	if(Test-Connection -Count 1 $Bing){
		$Bing="https://${Bing}"
		$ErrorCount=$Error.Count
		[PSCustomObject]$Response=Invoke-RestMethod "${Bing}/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=${PSUICulture}"
		if($ErrorCount -eq $Error.Count){
			[String]$DirectoryName="${Env:TEMP}\BingWallpaper"
			[String]$URL="$Bing$($Response.images[0].urlbase)_${Resolution}.jpg"
			[String]$FileName=Split-Path $URL -leaf
			[String]$Wallpaper="${DirectoryName}\${FileName}"
			$ErrorCount=$Error.Count
			if(Test-Path $DirectoryName){
				if(Get-ItemPropertyValue $DirectoryName Attributes|Where-Object {
					$_ -band [IO.FileAttributes]::Directory
				}){
					Remove-Item "${DirectoryName}\*" -Exclude $FileName -Force -Recurse
				}else{
					Remove-Item $DirectoryName -Force
					New-Item $DirectoryName -ItemType Directory
				}
			}else{
				New-Item $DirectoryName -ItemType Directory
			}
		}
		if($ErrorCount -eq $Error.Count -and !$(Test-Path $Wallpaper)){
			$ErrorCount=$Error.Count
			Invoke-WebRequest $URL -OutFile $Wallpaper
		}
		if($ErrorCount -eq $Error.Count -and $(Test-Path $Wallpaper)){
			[String]$RegPath='Registry::HKCU\Control Panel\Desktop'
			if(Test-Path $RegPath){
				@{
					#'Wallpaper'=$Wallpaper
					'WallpaperStyle'='10'
					'TileWallpaper'='0'
					'LastUpdated'=[UInt32]::MaxValue
				}.GetEnumerator()|Where-Object {
					$(Get-ItemProperty $RegPath).$($_.Key) -and $(Get-ItemPropertyValue $RegPath $_.Key) -ne $_.Value
				}|ForEach-Object {
					Set-ItemProperty $RegPath $_.Key $_.Value
				}
			}
			Add-Type @'
public class user32{
	[System.Runtime.InteropServices.DllImport("user32.dll")]
	public static extern bool SystemParametersInfo(byte uiAction,byte uiParam,string pvParam,byte fWinIni);
}
'@
			[user32]::SystemParametersInfo(20,0,$Wallpaper,3)
		}
	}
	$ErrorCount -eq $Error.Count
}