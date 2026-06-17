# CLAUDE.md — work

## 1. Sempre ler a memória antes de começar

Ao iniciar qualquer conversa neste projeto:

1. Leia o índice de memória: `~/.claude/projects/-home-eltobsjr-dev-automacoes-work/memory/MEMORY.md`  
   É um índice — siga os links para os arquivos relevantes à tarefa atual.

2. Leia o devtrack mais recente:  
   `ls /home/eltobsjr/dev/automacoes/work/WorkSecondBrain/devtrack/ | sort | tail -1`  
   e leia o arquivo retornado. Isso garante continuidade: o que foi feito,
   decisões tomadas e pendências abertas na última sessão.

## 2. Stack e tecnologias

- **zsh** — linguagem da automação principal (`work.zsh`)
- **jq** — parsing e escrita de JSON para `projects.json`
- **ptyxis** — terminal GNOME usado para abrir abas e janelas
- **bash** — script de instalação (`install.sh`)

## 3. Estrutura do projeto

```
~/dev/automacoes/work/
├── work.zsh          ← função sourced no ~/.zshrc — CLI principal
├── projects.json     ← config dos projetos cadastrados (não editar à mão)
├── install.sh        ← adiciona source no .zshrc e instala dependências
├── ABOUT.md          ← documentação técnica para IAs
├── CLAUDE.md         ← este arquivo
└── WorkSecondBrain/  ← vault de documentação
```

## 4. Documentação

Toda documentação fica no vault: `WorkSecondBrain/`  
Logs de sessão: `WorkSecondBrain/devtrack/`  
Formato dos logs: `YYYY-MM-DD - Título.md`

## 5. Regras de desenvolvimento

- **Nunca editar `projects.json` diretamente** — sempre usar `work new project` ou `work delete <projeto>` para manter a integridade do JSON
- **Não alterar o comportamento do `work` sem testar** o fluxo completo: `work list`, `work info`, `work new project` e `work <projeto>`
- **Manter retrocompatibilidade** com o schema atual do `projects.json` ao adicionar novos campos

## 6. Fluxo de trabalho

1. Ler memória e devtrack mais recente
2. Entender o contexto antes de implementar
3. Testar sintaxe com `zsh -n work.zsh` após qualquer alteração
4. Atualizar devtrack ao final da sessão com `/devtrack`
