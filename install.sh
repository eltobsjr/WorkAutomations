#!/usr/bin/env bash
# Instala a automação `work` adicionando o source no ~/.zshrc

set -euo pipefail

ZSHRC="$HOME/.zshrc"
WORK_ZSH="$HOME/dev/automacoes/work/work.zsh"
SOURCE_LINE="source \"$WORK_ZSH\""
MARKER="# --- work automation ---"

# verifica dependências
if ! command -v jq &>/dev/null; then
  echo "→ Instalando jq..."
  sudo dnf install -y jq
fi

# remove instalação antiga (bloco function work() do .zshrc)
if grep -q 'function work()' "$ZSHRC" 2>/dev/null; then
  echo "→ Removendo função work() antiga do .zshrc..."
  # remove do comentário "# --- Workspaces ---" até o fechamento da função
  sed -i '/# --- Workspaces ---/,/^}/d' "$ZSHRC"
fi

# evita source duplicado
if grep -qF "$SOURCE_LINE" "$ZSHRC" 2>/dev/null; then
  echo "✓ work já instalado no .zshrc"
  exit 0
fi

# adiciona source
printf '\n%s\n%s\n' "$MARKER" "$SOURCE_LINE" >> "$ZSHRC"

echo "✓ work instalado com sucesso!"
echo "  Rode: source ~/.zshrc  (ou abra um novo terminal)"
echo ""
echo "Comandos disponíveis:"
echo "  work <projeto>           — inicia o projeto"
echo "  work <projeto> claude    — inicia com Claude no terminal atual"
echo "  work <projeto> copilot   — inicia com Copilot no terminal atual"
echo "  work new project         — cadastra novo projeto"
