#!/bin/zsh
set -e
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# 1) Landing Page
cd "$ROOT_DIR/landing_page"
if [ ! -d node_modules ]; then
  npm install --silent
fi
# Liberar puerto 3000 si está ocupado
if lsof -i :3000 >/dev/null 2>&1; then
  echo "Puerto 3000 ocupado. Matando proceso..."
  lsof -ti :3000 | xargs kill -9 || true
  sleep 1
fi
npm start &
LP_PID=$!
echo "Landing Page en http://localhost:3000 (PID $LP_PID)"
# 2) Flutter Web en puerto fijo 57563
cd "$ROOT_DIR/paqueteria_app"
flutter run -d chrome --web-port 57563
# Al salir de Flutter, mata el server de landing
kill $LP_PID || true
