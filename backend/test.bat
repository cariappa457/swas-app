@echo off
echo Running Tests for SWSAS Backend...
if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install -r requirements.txt >nul 2>&1
pip install -r requirements-dev.txt >nul 2>&1
python -m pytest %*
