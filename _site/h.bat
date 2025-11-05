@echo off
echo ============================================
echo  Fresh Jekyll Build and Serve Script
echo ============================================
echo.

REM Step 1: Delete Gemfile.lock
echo [1/6] Deleting Gemfile.lock...
if exist Gemfile.lock (
    del /F /Q Gemfile.lock
    echo       ✓ Gemfile.lock deleted
) else (
    echo       ✓ Gemfile.lock not found, skipping
)
echo.

REM Step 2: Delete _site folder
echo [2/6] Deleting _site folder...
if exist _site (
    rmdir /S /Q _site
    echo       ✓ _site folder deleted
) else (
    echo       ✓ _site folder not found, skipping
)
echo.

REM Step 3: Delete .jekyll-cache
echo [3/6] Deleting .jekyll-cache...
if exist .jekyll-cache (
    rmdir /S /Q .jekyll-cache
    echo       ✓ .jekyll-cache deleted
) else (
    echo       ✓ .jekyll-cache not found, skipping
)
echo.

REM Step 4: Install dependencies
echo [4/6] Running bundle install...
call bundle install
if errorlevel 1 (
    echo       ✗ Bundle install failed!
    pause
    exit /b 1
)
echo       ✓ Dependencies installed
echo.

REM Step 5: Build the site
echo [5/6] Building Jekyll site...
call bundle exec jekyll build
if errorlevel 1 (
    echo       ✗ Jekyll build failed!
    pause
    exit /b 1
)
echo       ✓ Site built successfully
echo.

REM Step 6: Start the server
echo [6/6] Starting Jekyll server...
echo.
echo ============================================
echo  Server will start at http://localhost:4000/gnaneshblog/
echo  Press Ctrl+C to stop the server
echo ============================================
echo.
call bundle exec jekyll serve

pause
