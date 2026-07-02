#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# create_issues.sh
#
# Crea automáticamente todas las issues del proyecto en un repositorio de
# GitHub a partir de issues.json, usando GitHub CLI (gh).
#
# Requisitos previos:
#   1. Tener instalado GitHub CLI: https://cli.github.com/
#   2. Estar autenticado: gh auth login
#   3. Tener instalado jq (https://stedolan.github.io/jq/)
#
# Uso:
#   ./scripts/create_issues.sh <owner>/<repo>
#
# Ejemplo:
#   ./scripts/create_issues.sh mi-usuario/turnero-barber
#
# El script:
#   - Crea las labels necesarias en el repo (si no existen).
#   - Crea cada issue definida en issues.json con su título, cuerpo y labels.
# ==============================================================================

if [ $# -lt 1 ]; then
  echo "Uso: $0 <owner>/<repo>"
  echo "Ejemplo: $0 mi-usuario/turnero-barber"
  exit 1
fi

REPO="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISSUES_FILE="$SCRIPT_DIR/../issues.json"

if ! command -v gh &> /dev/null; then
  echo "Error: GitHub CLI (gh) no está instalado. Instalalo desde https://cli.github.com/"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq no está instalado. Instalalo con 'sudo apt install jq' (Linux) o 'brew install jq' (Mac)."
  exit 1
fi

if [ ! -f "$ISSUES_FILE" ]; then
  echo "Error: no se encontró el archivo $ISSUES_FILE"
  exit 1
fi

echo "Verificando autenticación con GitHub..."
gh auth status || { echo "Ejecutá 'gh auth login' primero."; exit 1; }

echo ""
echo "=== Creando labels necesarias en $REPO ==="

# Colores fijos por tipo de label, solo estéticos
declare -A LABEL_COLORS=(
  ["epic:setup"]="0E8A16"
  ["epic:data-model"]="1D76DB"
  ["epic:auth"]="D93F0B"
  ["epic:superadmin"]="5319E7"
  ["epic:config-local"]="FBCA04"
  ["epic:public-booking"]="B60205"
  ["epic:messaging"]="0052CC"
  ["epic:agenda"]="0E8A16"
  ["epic:stats"]="C2E0C6"
  ["epic:frontend-admin"]="BFD4F2"
  ["epic:frontend-public"]="BFDADC"
  ["epic:qa"]="FEF2C0"
  ["epic:deploy"]="D4C5F9"
  ["backend"]="006B75"
  ["frontend"]="1D76DB"
  ["infra"]="5319E7"
  ["security"]="B60205"
  ["ci-cd"]="0E8A16"
  ["testing"]="FBCA04"
  ["docs"]="C5DEF5"
  ["size:XS"]="C2E0C6"
  ["size:S"]="BFD4F2"
  ["size:M"]="FBCA04"
  ["size:L"]="D93F0B"
)

# Extraer todas las labels únicas usadas en issues.json
ALL_LABELS=$(jq -r '.[].labels[]' "$ISSUES_FILE" | sort -u)

for label in $ALL_LABELS; do
  color="${LABEL_COLORS[$label]:-EDEDED}"
  if gh label list --repo "$REPO" --search "$label" --json name -q '.[].name' | grep -qx "$label"; then
    echo "  Label '$label' ya existe, se omite."
  else
    gh label create "$label" --repo "$REPO" --color "$color" --force 2>/dev/null \
      && echo "  Label '$label' creada." \
      || echo "  No se pudo crear la label '$label' (puede que ya exista)."
  fi
done

echo ""
echo "=== Creando issues en $REPO ==="

TOTAL=$(jq length "$ISSUES_FILE")
COUNT=0

jq -c '.[]' "$ISSUES_FILE" | while read -r issue; do
  COUNT=$((COUNT + 1))
  TITLE=$(echo "$issue" | jq -r '.title')
  BODY=$(echo "$issue" | jq -r '.body')
  LABELS=$(echo "$issue" | jq -r '.labels | join(",")')

  echo "[$COUNT/$TOTAL] Creando: $TITLE"

  gh issue create \
    --repo "$REPO" \
    --title "$TITLE" \
    --body "$BODY" \
    --label "$LABELS" \
    > /dev/null

  # Pequeña pausa para no chocar con rate limits de la API
  sleep 1
done

echo ""
echo "=== Listo. Se crearon $TOTAL issues en $REPO ==="
echo "Podés agruparlas en un GitHub Project desde la pestaña 'Projects' del repositorio,"
echo "usando el campo 'Labels' para filtrar por épica (epic:setup, epic:auth, etc.)."
