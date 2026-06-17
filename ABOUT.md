# work — workspace launcher

Automação de terminal para inicializar ambientes de desenvolvimento completos com um único comando.

## O que faz

Dado um nome de projeto cadastrado em `projects.json`, o `work` abre em paralelo:
- Abas no terminal atual para cada processo (backend, frontend, etc.)
- VS Code na pasta raiz (se configurado)
- Opcionalmente, Claude ou Copilot no **terminal onde o comando foi digitado**

## Sintaxe

```
work <projeto>              # inicia processos do projeto
work <projeto> claude       # + claude no terminal atual
work <projeto> copilot      # + copilot no terminal atual
work new project            # wizard para cadastrar novo projeto
work                        # lista projetos disponíveis
```

## Projetos cadastrados

Definidos em `projects.json`. Cada projeto tem:
- `root` — pasta raiz
- `editor` — editor a abrir (`code` para VS Code, vazio para nenhum)
- `processes` — lista de processos com nome, comando, pasta e onde abrir (`tab`, `window`, `here`)
- `ai` — assistentes suportados: `0`=nenhum, `1`=claude, `2`=copilot, `3`=ambos
- `ai_dir` — pasta onde o assistente abre

## Regras anti-incoerência

- Só um processo pode usar `"open": "here"` (terminal atual)
- Se um processo usa `"here"` e o usuário passa `claude`/`copilot`, o assistente vai para uma aba (sem conflito)
- `work new project` valida cada campo antes de salvar

## Arquivos

```
~/dev/automacoes/work/
├── work.zsh        ← função sourced no ~/.zshrc
├── projects.json   ← configuração dos projetos
├── install.sh      ← instala a automação no sistema
└── ABOUT.md        ← este arquivo
```

## Instalação

```bash
bash ~/dev/automacoes/work/install.sh
```
