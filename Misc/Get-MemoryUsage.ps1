#Requires -version 2
<#
	.SYNOPSIS
	Acquire and display memory usage.
	<Get-MemoryUsage.ps1> [-BackgroundColor <Array>] [-ForegroundColor <Array>] [-WindowSize <UInt16[]>] [-EnableDetail <Bool>] [-UpdateFrequency <String>]

	.DESCRIPTION
	# [about_Execution_Policies](http://go.microsoft.com/fwlink/?LinkID=135170)
	"Run as Administrator" PowerShell
	`Unblock-File '<Get-MemoryUsage.ps1>'`
	PowerShell or Command Prompt or Run
	`PowerShell -ExecutionPolicy RemoteSigned "<Get-MemoryUsage.ps1>"`

	.PARAMETER BackgroundColor
	Specifies the background color. Enter @(Safe,Advice,Warn) format. Default is @('Black','Black','Black'). The acceptable values for this parameter are:

	-- Black DarkGray Gray White 
	-- Red Yellow Cyan Green Blue Magenta 
	-- DarkRed DarkYellow DarkCyan DarkGreen DarkBlue DarkMagenta

	.PARAMETER ForegroundColor
	Specifies the foreground color. Enter @(Safe,Advice,Warn) format. Default is @('Green','Yellow','Red'). The acceptable values for this parameter are:

	-- Black DarkGray Gray White 
	-- Red Yellow Cyan Green Blue Magenta 
	-- DarkRed DarkYellow DarkCyan DarkGreen DarkBlue DarkMagenta

	.PARAMETER WindowSize
	Specifies the window size. Enter @(Width,Height) format. Default is @(15,2).

	.PARAMETER EnableDetail
	Displays UsagePhys/TotalPhys. Default is $True.

	.PARAMETER UpdateFrequency
	Specifies the frequency of update. Default is Normal. The acceptable values for this parameter are: 
	-- High Normal Low

	.EXAMPLE
	./Get-MemoryUsage.ps1 -BackgroundColor @('White','White','White') -ForegroundColor @('Blue','Green','Red') -EnableDetail $False -UpdateFrequency 'Low'
#>
Param(
	[ValidateCount(3,3)]
	[ValidateSet(
		'Black','DarkGray','Gray','White',
		'Red','Yellow','Cyan','Green','Blue','Magenta',
		'DarkRed','DarkYellow','DarkCyan','DarkGreen','DarkBlue','DarkMagenta'
	)]
	[String[]]$BackgroundColor=@('Black','Black','Black'),
	[ValidateCount(3,3)]
	[ValidateSet(
		'Black','DarkGray','Gray','White',
		'Red','Yellow','Cyan','Green','Blue','Magenta',
		'DarkRed','DarkYellow','DarkCyan','DarkGreen','DarkBlue','DarkMagenta'
	)]
	[String[]]$ForegroundColor=@('Green','Yellow','Red'),
	[UInt16[]]$WindowSize=@(15,2),
	[Bool]$EnableDetail=$True,
	[ValidateSet(
		'High','Normal','Low'
	)]
	[String]$UpdateFrequency='Normal'
)
&{
	Set-StrictMode -Version Latest
	$Color=@{
		'Background'=New-Object 'Collections.Generic.Dictionary[String,String]'
		'Foreground'=New-Object 'Collections.Generic.Dictionary[String,String]'
	}
	$Color.Background.Safe,$Color.Background.Advice,$Color.Background.Warn=$BackgroundColor
	$Color.Foreground.Safe,$Color.Foreground.Advice,$Color.Foreground.Warn=$ForegroundColor
	$Host.UI.RawUI.WindowSize=@{
		'Width'=$WindowSize[0];
		'Height'=$WindowSize[1]
	}
	[UInt16]$UpdateFrequency=@{'High'=500;'Normal'=1000;'Low'=4000}.$UpdateFrequency
	Add-Type @'
public class kernel32{
	public struct MEMORYSTATUSEX{
		public uint dwLength;
		public uint dwMemoryLoad;
		public ulong ullTotalPhys;
		public ulong ullAvailPhys;
		public ulong ullTotalPageFile;
		public ulong ullAvailPageFile;
		public ulong ullTotalVirtual;
		public ulong ullAvailVirtual;
		public ulong ullAvailExtendedVirtual;
	}
	[System.Runtime.InteropServices.DllImport("kernel32.dll")]
	private static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);
	public static ulong GetMemoryStatus(string member){
		MEMORYSTATUSEX memStatus=new MEMORYSTATUSEX();
		memStatus.dwLength=(uint)System.Runtime.InteropServices.Marshal.SizeOf(memStatus);
		GlobalMemoryStatusEx(ref memStatus);
		ulong value=0;
		if(member=="dwMemoryLoad"){
			value=memStatus.dwMemoryLoad;
		}
		if(member=="ullTotalPhys"){
			value=memStatus.ullTotalPhys;
		}
		if(member=="ullAvailPhys"){
			value=memStatus.ullAvailPhys;
		}
		return value;
	}
}
public class user32{
	public struct FLASHWINFO{
		public uint cbSize;
		public System.IntPtr hwnd;
		public uint dwFlags;
		public uint uCount;
		public uint dwTimeout;
	}
	[System.Runtime.InteropServices.DllImport("user32.dll")]
	private static extern bool FlashWindowEx(ref FLASHWINFO pwfi);
	public static bool FlashWindow(System.IntPtr MainWindowHandle,byte Flag)
	{
		FLASHWINFO fInfo=new FLASHWINFO();
		fInfo.cbSize=(uint)System.Runtime.InteropServices.Marshal.SizeOf(fInfo);
		fInfo.hwnd=MainWindowHandle;
		fInfo.dwFlags=Flag;
		fInfo.uCount=System.UInt32.MaxValue;
		fInfo.dwTimeout=0;
		return FlashWindowEx(ref fInfo);
	}
}
'@
	if($EnableDetail){
		[UInt64]$TotalPhys=[kernel32]::GetMemoryStatus('ullTotalPhys')
		[SByte]$i=-1
		[Single]$TotalPhysSI=$TotalPhys
		while(($TotalPhysSI -bor 0).ToString().Length -ge 4){
			$TotalPhysSI=$TotalPhysSI/1024
			$i++
		}
		[String]$Prefix=@('KB','MB','GB','TB','PB')[$i]
		Remove-Variable 'i'
		[Single]$UsagePhysSI=0
	}
	[Int64]$CurrentTime=0
	[Int64]$FutureTime=0
	[Byte]$MemoryLoad=0
	[IntPtr]$MainWindowHandle=(Get-Process -Id $PID).MainWindowHandle
	[Byte]$Level=0
	[Bool]$Excess=$False
	[String]$Output=''
	[Int16]$Millisecond=$UpdateFrequency-(($FutureTime-$CurrentTime)/1e4 -bor 0)
	while($True){
		$CurrentTime=[DateTime]::Now.Ticks
		$MemoryLoad=[kernel32]::GetMemoryStatus('dwMemoryLoad')
		if($MemoryLoad -lt 80 -and $Level -ne 1){
			$Host.UI.RawUI.BackgroundColor=$Color.Background.Safe
			$Host.UI.RawUI.ForegroundColor=$Color.Foreground.Safe
			if($Excess){
				[user32]::FlashWindow($MainWindowHandle,0)
				$Excess=$False
			}
			$Level=1
		}elseif($MemoryLoad -ge 80 -and $MemoryLoad -lt 90 -and $Level -ne 2){
			$Host.UI.RawUI.BackgroundColor=$Color.Background.Advice
			$Host.UI.RawUI.ForegroundColor=$Color.Foreground.Advice
			if($Excess){
				[user32]::FlashWindow($MainWindowHandle,0)
				$Excess=$False
			}
			$Level=2
		}elseif($MemoryLoad -ge 90 -and $Level -ne 3){
			$Host.UI.RawUI.BackgroundColor=$Color.Background.Warn
			$Host.UI.RawUI.ForegroundColor=$Color.Foreground.Warn
			if(!$Excess){
				[user32]::FlashWindow($MainWindowHandle,7)
				$Excess=$True
			}
			$Level=3
		}
		Clear-Host
		$Output="$(if($EnableDetail){
			"$("{0:F1}${Prefix}" -f (($TotalPhys-[kernel32]::GetMemoryStatus('ullAvailPhys'))/"1${Prefix}"))/$("{0:F1}${Prefix}" -f $TotalPhysSI) "
		})${MemoryLoad}%"
		$Host.UI.RawUI.WindowTitle=$Output
		$Output
		$FutureTime=[DateTime]::Now.Ticks
		if($Millisecond=$UpdateFrequency-(($FutureTime-$CurrentTime)/1e4 -bor 0)){
			Start-Sleep -Milliseconds $Millisecond
		}
	}
}