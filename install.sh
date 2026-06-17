#!/usr/bin/env bash
# Instala o work CLI — funciona tanto clonando o repo quanto via curl pipe
# Uso local: bash install.sh
# Uso remoto: curl -fsSL https://raw.githubusercontent.com/eltobsjr/WorkAutomations/main/install.sh | bash

set -euo pipefail

WORK_DIR="${WORK_INSTALL_DIR:-$HOME/dev/automacoes/work}"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
GITHUB_RAW="https://raw.githubusercontent.com/eltobsjr/WorkAutomations/main"
MARKER="# --- work automation ---"
SOURCE_LINE="source \"$WORK_DIR/work.zsh\""

_ok()   { printf "\033[32m✓\033[0m %s\n" "$*"; }
_err()  { printf "\033[31m✗\033[0m %s\n" "$*" >&2; exit 1; }
_info() { printf "\033[36m→\033[0m %s\n" "$*"; }
_warn() { printf "\033[33m⚠\033[0m  %s\n" "$*"; }

echo ""
printf "\033[1mwork-automations — instalador\033[0m\n"
echo ""

# ── jq ────────────────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  _info "Instalando jq..."
  if   command -v dnf  &>/dev/null; then sudo dnf install -y jq
  elif command -v apt  &>/dev/null; then sudo apt-get install -y jq
  elif command -v brew &>/dev/null; then brew install jq
  else _err "jq não encontrado. Instale em: https://jqlang.github.io/jq/download/"; fi
fi

# ── diretório de instalação ───────────────────────────────────────────────
mkdir -p "$WORK_DIR"

# ── work.zsh: copia local se disponível, senão baixa do GitHub ────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd || echo "")"
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/work.zsh" && "$SCRIPT_DIR" != "/dev" ]]; then
  cp "$SCRIPT_DIR/work.zsh" "$WORK_DIR/work.zsh"
  _ok "work.zsh copiado de $SCRIPT_DIR"
else
  _info "Baixando work.zsh do GitHub..."
  curl -fsSL "$GITHUB_RAW/work.zsh" -o "$WORK_DIR/work.zsh"
  _ok "work.zsh baixado"
fi

# ── projects.json (preserva se já existe com projetos) ────────────────────
if [[ ! -f "$WORK_DIR/projects.json" ]]; then
  echo '{}' > "$WORK_DIR/projects.json"
  _ok "projects.json criado (vazio)"
else
  _ok "projects.json existente preservado"
fi

# ── .zshrc ────────────────────────────────────────────────────────────────
if grep -q 'function work()' "$ZSHRC" 2>/dev/null; then
  _info "Removendo função work() antiga do .zshrc..."
  sed -i '/# --- Workspaces ---/,/^}/d' "$ZSHRC"
fi

if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
  _ok "work já estava instalado no .zshrc"
else
  printf '\n%s\n%s\n' "$MARKER" "$SOURCE_LINE" >> "$ZSHRC"
  _ok "source adicionado ao .zshrc"
fi

echo ""
_ok "Instalação concluída em $WORK_DIR"
echo ""
echo "  Ative agora: \033[1msource ~/.zshrc\033[0m"
echo ""
echo "Comandos:"
echo "  work new project         — cadastra novo projeto"
echo "  work <projeto>           — inicia o projeto"
echo "  work <projeto> claude    — inicia com Claude no terminal"
echo "  work list                — lista projetos cadastrados"
echo "  work help                — ajuda completa"
echo ""
