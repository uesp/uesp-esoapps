@echo off
@REM
@REM ConvertDDS.BAT - by Dave Humphrey (dave@uesp.net) - 15 Jan 2014
@REM
@REM A simple script that converts DDS files in sub-directories recursively.
@REM Output type is PNG by default but can be changed by editing the OUTPUTTYPE
@REM variable below to anything that NCONVERT.EXE supports.
@REM
@IF [%1] == [] GOTO:NOINPUT

@set STARTPATH=%1
@set OUTPUTTYPE=png

@for /R %STARTPATH% %%G in (*.dds) do (	@echo Converting %%G...
	@nconvert.exe -quiet -overwrite -out %OUTPUTTYPE% "%%G" )

@exit

:NOINPUT
@echo ConvertDDS.BAT: Missing required parameter for the target directory!
@echo For example:
@echo       convertdds.bat d:\file\output\
@echo       convertdds.bat gamemnf\output\
@echo       convertdds.bat .\
