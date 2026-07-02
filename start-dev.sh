#!/bin/bash
# ============================================
# Barbershop — Inicio rápido de desarrollo
# ============================================
# Uso:
#   ./start-dev.sh            # Levanta todo (frontend en foreground)
#   ./start-dev.sh -b         # Levanta todo en background
#   ./start-dev.sh --stop     # Detiene todo
#   ./start-dev.sh --status   # Muestra estado de los procesos
# ============================================

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/BS"
FRONTEND_DIR="$PROJECT_DIR/frontend"
LOG_DIR="$PROJECT_DIR/logs"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"
PID_FILE="$LOG_DIR/.pids"

# Colores (si el terminal lo soporta)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; CYAN=''; NC=''
fi

info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
cmd()   { echo -e "${CYAN}[CMD]${NC}   $1"; }

cleanup() {
  echo ""
  warn "Deteniendo servicios..."
  if [ -f "$PID_FILE" ]; then
    while IFS= read -r pid; do
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null && info "Proceso $pid detenido"
      fi
    done < "$PID_FILE"
    rm -f "$PID_FILE"
  fi
  docker compose down 2>/dev/null && info "Contenedores detenidos"
  info "Todo limpio. ¡Hasta luego!"
  exit 0
}

show_status() {
  echo ""
  info "=== Estado ==="
  echo ""

  if docker compose ps --services --filter "status=running" 2>/dev/null | grep -q .; then
    docker compose ps 2>/dev/null | tail -n +2
  else
    warn "Contenedores: NO corriendo"
  fi
  echo ""

  if [ -f "$PID_FILE" ]; then
    while IFS= read -r pid; do
      if kill -0 "$pid" 2>/dev/null; then
        local name
        name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "desconocido")
        info "Backend PID $pid ($name): corriendo"
      else
        warn "Backend PID $pid: detenido"
      fi
    done < "$PID_FILE"
  else
    warn "Backend: NO corriendo"
  fi
  echo ""

  if pgrep -f "vite" > /dev/null 2>&1; then
    info "Frontend: corriendo"
  else
    warn "Frontend: NO corriendo"
  fi
}

start_infra() {
  info "Levantando infraestructura (PostgreSQL + RabbitMQ)..."
  docker compose up -d 2>&1 | while IFS= read -r line; do cmd "$line"; done

  info "Esperando a que Postgres esté listo..."
  until docker compose exec postgres pg_isready -U postgres > /dev/null 2>&1; do
    sleep 1
  done
  info "Postgres listo ✅"

  info "Esperando a que RabbitMQ esté listo..."
  until curl -s -o /dev/null http://localhost:15672/ > /dev/null 2>&1; do
    sleep 1
  done
  info "RabbitMQ listo ✅"
}

start_backend() {
  mkdir -p "$LOG_DIR"

  info "Compilando y arrancando backend (Spring Boot)..."
  cd "$BACKEND_DIR"

  # Primera vez: compila sin tests
  if [ ! -f "target/*.jar" ]; then
    cmd "Compilando con Maven (puede tardar la primera vez)..."
    ./mvnw package -DskipTests -q 2>&1 | while IFS= read -r line; do cmd "$line"; done
  fi

  # Arranca el backend en background
  ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev > "$BACKEND_LOG" 2>&1 &
  echo $! >> "$PID_FILE"

  cd "$PROJECT_DIR"
  info "Backend arrancando... (logs: $BACKEND_LOG)"
}

start_frontend() {
  mkdir -p "$LOG_DIR"

  info "Instalando dependencias si hace falta..."
  cd "$FRONTEND_DIR"
  if [ ! -d "node_modules" ]; then
    cmd "pnpm install..."
    pnpm install --frozen-lockfile 2>&1 | while IFS= read -r line; do cmd "$line"; done
  fi

  if [ "${1:-}" = "--background" ]; then
    info "Arrancando frontend en background..."
    pnpm dev > "$FRONTEND_LOG" 2>&1 &
    echo $! >> "$PID_FILE"
    info "Frontend arrancando... (logs: $FRONTEND_LOG)"
  else
    info "Arrancando frontend (Vite dev server)..."
    info "URL: http://localhost:5173"
    echo ""
    cd "$FRONTEND_DIR"
    pnpm dev
  fi
}

# ============================================
# Entry point
# ============================================

case "${1:-}" in
  --stop|-s)
    trap - EXIT INT TERM
    cleanup
    ;;
  --status)
    show_status
    ;;
  -b|--background)
    trap cleanup EXIT INT TERM
    start_infra
    start_backend
    start_frontend --background

    echo ""
    info "=========================================="
    info "  TODO LEVANTADO"
    info "=========================================="
    info "  Frontend: http://localhost:5173"
    info "  Backend:  http://localhost:8080"
    info "  Postgres: localhost:5432"
    info "  RabbitMQ: localhost:5672"
    info "  RabbitMQ UI: http://localhost:15672"
    info "=========================================="
    info "  Para ver logs:"
    info "  Backend:  tail -f $BACKEND_LOG"
    info "  Frontend: tail -f $FRONTEND_LOG"
    info "=========================================="
    info "  Para detener: ./start-dev.sh --stop"
    info "=========================================="
    # Espera a que los procesos en background terminen
    wait
    ;;
  --help|-h)
    echo "Barbershop — Inicio rápido de desarrollo"
    echo ""
    echo "  ./start-dev.sh            # Levanta todo (frontend visible)"
    echo "  ./start-dev.sh -b         # Todo en background"
    echo "  ./start-dev.sh --stop     # Detiene todo"
    echo "  ./start-dev.sh --status   # Estado de los procesos"
    echo "  ./start-dev.sh --help     # Esta ayuda"
    ;;
  *)
    trap cleanup EXIT INT TERM
    start_infra
    start_backend
    start_frontend
    # cleanup se ejecuta automáticamente al salir con Ctrl+C
    ;;
esac
