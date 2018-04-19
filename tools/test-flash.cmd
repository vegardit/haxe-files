@echo off
REM Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

pushd .

REM cd into project root
cd %~dp0..

echo Cleaning...
if exist dump\flash rd /s /q dump\flash
if exist target\flash rd /s /q target\flash

haxelib list | findstr haxe-concurrent >NUL
if errorlevel 1 (
    echo Installing [haxe-concurrent]...
    haxelib install haxe-concurrent
)

haxelib list | findstr haxe-doctest >NUL
if errorlevel 1 (
    echo Installing [haxe-doctest]...
    haxelib install haxe-doctest
)

haxelib list | findstr haxe-strings >NUL
if errorlevel 1 (
    echo Installing [haxe-strings]...
    haxelib install haxe-strings
)

echo Compiling...
haxe -main hx.files.TestRunner ^
  -lib haxe-concurrent ^
  -lib haxe-doctest ^
  -lib haxe-strings ^
  -cp src ^
  -cp test ^
  -dce full ^
  -debug ^
  -D dump=pretty ^
  -D no-swf-compress ^
  -D swf-script-timeout=180 ^
  -swf-version 11.5 ^
  -swf target\flash\TestRunner.swf
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

REM enable Flash logging
(
    echo ErrorReportingEnable=1
    echo TraceOutputFileEnable=1
) > "%HOME%\mm.cfg"

REM add the flash target directory as trusted source to prevent "Only trusted local files may cause the Flash Player to exit."
call :normalize_path %~dp0..\target
set target_dir_absolute=%RETVAL%
(
    echo %target_dir_absolute%\flash
) > "%HOME%\AppData\Roaming\Macromedia\Flash Player\#Security\FlashPlayerTrust\HaxeDoctest.cfg"

echo Testing...
flashplayer_29_sa_debug "%~dp0..\target\flash\TestRunner.swf"
set rc=%errorlevel%

REM printing log file
type "%HOME%\AppData\Roaming\Macromedia\Flash Player\Logs\flashlog.txt"

exit /b %rc%

:normalize_path
  SET RETVAL=%~dpfn1
  exit /b