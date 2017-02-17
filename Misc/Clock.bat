@if(0)==(0) echo off
	rem Preferences
		set pref-date=n
		set pref-second=n
		rem [y|n]

		set pref-sleep=0
		rem 0=auto 1=timeout 2=ping 3=WSH-Sleep

		color 0a
		rem color [bg][fg]
		rem 0=Black  8=Gray
		rem 1=Blue   9=Light Blue
		rem 2=Green  A=Light Green
		rem 3=Aqua   B=Light Aqua
		rem 4=Red    C=Light Red
		rem 5=Purple D=Light Purple
		rem 6=Yellow E=Light Yellow
		rem 7=White  F=Bright White

		set cols=11
		set lines=1

		rem set count=5

		set mode=1
		rem [1|2]
	rem End Preferences
	if %pref-sleep% leq 1 (
		if exist "%SystemRoot%\System32\timeout.exe" (
			if %pref-sleep%==0 (
				set pref-sleep=1
			)
		) else (
			if %pref-sleep%==1 (
				echo timeout command was not found.
				pause
				exit /b 1
			)
			if %pref-sleep%==0 (
				set pref-sleep=2
			)
		)
	)
	if %lines% lss 2 (
		if /i %pref-date%==y (
			set lines=3
		) else (
			set lines=2
		)
	)
	:resize
	mode con: cols=%cols% lines=%lines%
	if %errorlevel%==-1 (
		set /a cols+=1
		goto :resize
	)
	:loop
		cls
		@echo off
		if /i %pref-date%==y (
			echo %date%
		)
		if /i %pref-second%==y (
			if %mode%==1 (
				for /f "delims=. tokens=1" %%i in ("%TIME%") do set time2=%%i
			)
			if %mode%==2 (
				set time2=%TIME:~0,8%
			)
		) else (
			if %mode%==1 (
				for /f "delims=: tokens=1,2" %%i in ("%TIME%") do set time2=%%i:%%j
			)
			if %mode%==2 (
				set time2=%TIME:~0,5%
			)
		)
		set time2=%time2: =0%
		echo %time2%
		title %time2%
		goto :sleep%pref-sleep%
		:sleep1
			if /i %pref-second%==y (
				set wait=1
			) else (
				if %mode%==1 (
					for /f "delims=:. tokens=3" %%i in ("%TIME%") do set /a wait=60-%%i
				)
				if %mode%==2 (
					set /a wait=60-%TIME:~6,2%
				)
			)
			timeout /t %wait% >nul
		goto :loop
		:sleep2
			if %mode%==1 (
				for /f "delims=:. tokens=3,4" %%i in ("%TIME%") do set /a s=1%%i-100 & set /a cs=1%%j-100
			)
			if %mode%==2 (
				set /a s=1%TIME:~6,2%-100 & set /a cs=1%TIME:~9,2%-100
			)
			if /i %pref-second%==y (
				set /a wait=1000-%cs%*10
			) else (
				set /a wait=60000-%s%*1000+%cs%*10
			)
			if %wait% geq 10 (
				ping -n 1 -w %wait% 127.255.255.255>nul
			)
		goto :loop
		:sleep3
			cscript //B //E:JScript //Nologo "%~f0" "%DATE% %TIME%"
		goto :loop
	goto :eof
	rem set /a count-=1 &if %count% leq 0 (goto :eof)
@end
(function(){
	var future=new Date(WScript.Arguments(0).replace(/(?:^\S+ )?([\d/]+ +[\d:]+)(?:\.\d+)/,"$1")),
		present;
	if(WScript.CreateObject("WScript.Shell").Environment("Process")("pref-second").toLowerCase()==="y"){
		future.setSeconds(future.getSeconds()+1);
	}else{
		future.setMinutes(future.getMinutes()+1);
		future.setSeconds(0);
	}
	present=new Date();
	future>present&&WScript.Sleep(future-present);
}());