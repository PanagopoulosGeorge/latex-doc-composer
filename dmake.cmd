@echo off
rem Run any `make` target inside the Docker LaTeX image (Windows).
rem   dmake build D=docs/my-thesis
rem   dmake shell
rem The first run builds the image (a few minutes). Paths must be inside this repo.
setlocal
cd /d "%~dp0"
where docker >nul 2>nul || (echo Docker is not installed: https://docs.docker.com/desktop/setup/install/windows-install/ & exit /b 1)
docker info >nul 2>nul || (echo Docker is installed but not running. Start Docker Desktop and retry. & exit /b 1)
for /f "delims=" %%i in ('git config user.name 2^>nul') do (set "GIT_AUTHOR_NAME=%%i" & set "GIT_COMMITTER_NAME=%%i")
for /f "delims=" %%i in ('git config user.email 2^>nul') do (set "GIT_AUTHOR_EMAIL=%%i" & set "GIT_COMMITTER_EMAIL=%%i")
if /i "%~1"=="shell" (docker compose run --rm tex bash & exit /b)
docker compose run --rm tex make %*
