@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SET "filename=%~1"
SET "option=%~2"

SET "dir=%CD%"
SET "delim=§"

GOTO start

:parse_line
SET "key=%1"
SET "value=%2"

SET key_pair=

IF NOT DEFINED key GOTO:EOF
IF "%key:~0:1%"=="#" GOTO:EOF

IF NOT "%key:~-5%"=="_PATH" IF NOT "%key:~-4%"=="_DIR" GOTO set_var
IF NOT "%value:~1:1%"==":" IF NOT "%value:~0,1%"=="\" (
  SET "value=%CD%\%value%"
)

:set_var
SET "key_pair=%key%%delim%%value%"
EXIT /B

:load_env
SET envars=
FOR /F "usebackq tokens=1,* delims==" %%A IN ("!envfile!") DO (
  CALL :parse_line %%A %%B
  IF DEFINED key_pair (
    SET "envars=!envars! !key_pair!"
  )
)

ENDLOCAL & FOR %%E IN (%envars%) DO (
  FOR /F "tokens=1* delims=§" %%K IN ("%%E") DO SET %%K=%%L
)
EXIT /B 0

:not_found
ECHO Could not find %filename% in path from !dir! to %CD%
ENDLOCAL
EXIT /B 1

:check
IF EXIST "%filename%" (
  SET "envfile=%filename%"
  GOTO load_env
)

:walk_tree
IF EXIST "!dir!\%filename%" (
  SET "envfile=%dir%\%filename%"
  GOTO load_env
)

FOR %%I IN ("!dir!") DO SET "parent=%%~dpI"
IF /I "!parent!"=="!dir!\" (
  GOTO not_found
) ELSE IF EXIST "!dir!\%stopmarker%" (
  GOTO not_found
)
SET "dir=!parent:~0,-1!"
GOTO walk_tree

:start
IF NOT DEFINED filename (
    ECHO Usage: %~nx0 envfile [stop_marker ^| --all]
    EXIT /B 1
)

IF NOT DEFINED option (
  SET "stopmarker=.git"
  GOTO check 
)

IF /I "%option%"=="--all" (
  SET "stopmarker=%CD:~0,3%"
) ELSE (
  SET "stopmarker=%option%"
)
GOTO check
