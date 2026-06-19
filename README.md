# work-automations

Inicie seu ambiente de desenvolvimento completo com um único comando — abre terminais, editor e assistente de IA exatamente como você configurou.

## Instalação

**Via npm:**
```bash
npm install -g work-automations
work-setup
```

**Via curl (sem Node.js):**
```bash
curl -fsSL https://raw.githubusercontent.com/eltobsjr/WorkAutomations/main/install.sh | bash
```

> Requer: **zsh** · **jq** (instalado automaticamente) · **ptyxis** (terminal GNOME)

---

## Uso

```bash
work new project
```

O CLI vai perguntar:

1. **Nome do projeto** — identificador usado no comando (ex: `meuapp`)
2. **Pasta raiz** — diretório principal do projeto
3. **Processos paralelos** — cada processo tem nome de aba, comando, pasta e onde abrir (`nova aba`, `nova janela` ou `terminal atual`)
4. **Assistente de IA** — nenhum / Claude / Copilot / ambos

Depois disso, basta rodar:

```bash
work <projeto>
```

---

## Exemplo

```
$ work new project

╔══════════════════════════════════╗
║       work — novo projeto        ║
╚══════════════════════════════════╝

[1/4] Nome do projeto: meuapp
[2/4] Pasta raiz [~/dev/meuapp]:
      Abrir VS Code ao iniciar? [s/N]: s
[3/4] Quantos processos paralelos? [1]: 2

      — Processo 1/2 —
      Nome da aba  : Backend
      Comando      : npm run dev
      Pasta        : ~/dev/meuapp
      Abrir em     : nova aba

      — Processo 2/2 —
      Nome da aba  : Frontend
      Comando      : npm run dev:client
      Pasta        : ~/dev/meuapp/client
      Abrir em     : nova aba

[4/4] Assistente de IA? → [1] Claude

✓ Projeto "meuapp" salvo!
```

A partir daí:

```bash
work meuapp              # VS Code + aba Backend + aba Frontend
work meuapp claude       # mesmos + Claude no terminal atual
```

---

## Comandos

| Comando | Descrição |
|---|---|
| `work new project` | Cadastra novo projeto (wizard interativo) |
| `work <projeto>` | Inicia o projeto |
| `work <projeto> claude` | Inicia + abre Claude no terminal |
| `work <projeto> copilot` | Inicia + abre Copilot no terminal |
| `work list` | Lista projetos cadastrados |
| `work info <projeto>` | Detalhes e diagnóstico do projeto |
| `work delete <projeto>` | Remove projeto |
| `work help` | Ajuda completa |

---

## Links

- **npm:** https://www.npmjs.com/package/work-automations
- **GitHub:** https://github.com/eltobsjr/WorkAutomations
