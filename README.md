# work-automations

Workspace launcher para zsh — inicializa ambientes de desenvolvimento completos com um único comando.

## Instalação

**Via npm:**
```bash
npm install -g work-automations
work-setup
source ~/.zshrc
```

**Via curl (sem precisar de Node):**
```bash
curl -fsSL https://raw.githubusercontent.com/eltobsjr/WorkAutomations/main/install.sh | bash
source ~/.zshrc
```

**Clonando o repositório:**
```bash
git clone https://github.com/eltobsjr/WorkAutomations.git ~/dev/automacoes/work
bash ~/dev/automacoes/work/install.sh
source ~/.zshrc
```

> Requer: **zsh**, **jq**, **ptyxis** (terminal GNOME)  
> O instalador instala o `jq` automaticamente se não encontrar.

---

## Uso

```bash
work <projeto>              # inicia o projeto
work <projeto> claude       # + Claude no terminal atual
work <projeto> copilot      # + Copilot no terminal atual
work new project            # cadastra novo projeto (wizard interativo)
work list                   # lista projetos cadastrados
work info <projeto>         # detalhes e diagnóstico do projeto
work delete <projeto>       # remove projeto
work help                   # ajuda completa
```

## Como funciona

Cada projeto é configurado via wizard (`work new project`) e salvo em `projects.json`. Ao rodar `work <projeto>`, o CLI:

1. Abre o editor (VS Code, se configurado)
2. Abre cada processo em uma nova aba ou janela do ptyxis
3. Se `claude` ou `copilot` for passado, abre o assistente no **terminal atual** onde o comando foi digitado

```bash
work rdapp              # VS Code + aba Solr/Backend + aba Frontend
work rdapp claude       # mesmos + Claude no terminal atual
```

## Configuração de projetos

O wizard `work new project` pergunta:
- Nome do projeto
- Pasta raiz
- Processos paralelos (nome da aba, comando, pasta, onde abrir)
- Assistente de IA (nenhum / claude / copilot / ambos)

Os projetos ficam em `~/dev/automacoes/work/projects.json`.

## Variável de ambiente

Por padrão o `work` instala em `~/dev/automacoes/work/`. Para mudar:

```bash
WORK_INSTALL_DIR=~/.work bash install.sh
```

## Links

- **npm:** https://www.npmjs.com/package/work-automations
- **GitHub:** https://github.com/eltobsjr/WorkAutomations
