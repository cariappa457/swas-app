@echo off
echo Running SWSAS Backend Dev Server...
if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install -r requirements.txt >nul 2>&1
uvicorn main:app --reload --host 0.0.0.0 --port 8000
