@echo off
:loop
echo Starting LocalTunnel infinitely aggressively securely...
npx localtunnel --port 8000 --subdomain loose-turtles-live
echo LocalTunnel crashed securely, dynamically actively restarting heavily in 2 seconds...
timeout /t 2 >nul
goto loop
