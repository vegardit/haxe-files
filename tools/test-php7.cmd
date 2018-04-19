@echo off
REM Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

pushd .

REM cd into project root
cd %~dp0..

echo Cleaning...
if exist dump\php rd /s /q dump\php
if exist target\php7 rd /s /q target\php7

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
  -D php7 ^
  -php target\php7
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
%PHP7_HOME%\php "%~dp0..\target\php7\index.php"
