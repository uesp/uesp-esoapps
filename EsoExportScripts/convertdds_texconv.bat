@echo off
@REM
@REM ConvertDDS_texconv.BAT - by Dave Humphrey (dave@uesp.net) - 4 Aug 2026
@REM
@REM A simple script that converts DDS files in sub-directories recursively using the MS texconv utility.
@REM Output type is PNG by default but can be changed by editing the OUTPUTTYPE variable below to anything that texconv supports.
@REM
@IF [%1] == [] GOTO:NOINPUT

@set STARTPATH=%1
@set OUTPUTTYPE=png

pushd "%STARTPATH%"

for /F "delims=" %%G in ('dir /ad /on /b /s') do (
	@echo "Converting all DDS in %%G..."
	@texconv -y -nologo -ft %OUTPUTTYPE% "%%G\*.dds"
)

popd

@REM @for /R %STARTPATH% %%G in (*.dds) do (	
@REM 	@texconv -y -nologo -ft %OUTPUTTYPE% "%%G" )

@exit

:NOINPUT
@echo ConvertDDS.BAT: Missing required parameter for the target directory!
@echo For example:
@echo       convertdds.bat d:\file\output\
@echo       convertdds.bat gamemnf\output\
@echo       convertdds.bat .\
