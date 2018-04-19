@echo off
REM Copyright (c) 2016-2018 Vegard IT GmbH, https://vegardit.com
REM SPDX-License-Identifier: Apache-2.0
REM Author: Sebastian Thomschke, Vegard IT GmbH

pushd .

REM cd into project root
cd %~dp0..

echo Cleaning...
if exist dump\js rd /s /q dump\js
if exist target\js rd /s /q target\js

haxelib list | findstr hxnodejs >NUL
if errorlevel 1 (
    echo Installing [hxnodejs]...
    haxelib install hxnodejs
)

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
  -lib hxnodejs ^
  -lib haxe-concurrent ^
  -lib haxe-doctest ^
  -lib haxe-strings ^
  -cp src ^
  -cp test ^
  -dce full ^
  -debug ^
  -D dump=pretty ^
  -D nodejs ^
  -js target\js\TestRunner.js
set rc=%errorlevel%
popd
if not %rc% == 0 exit /b %rc%

echo Testing...
node "%~dp0..\target\js\TestRunner.js"
