# ─── work.zsh — workspace launcher ──────────────────────────────────────
# Gerenciado em ~/dev/automacoes/work/
# Para instalar: bash ~/dev/automacoes/work/install.sh

WORK_DIR="${WORK_DIR:-$HOME/dev/automacoes/work}"
WORK_PROJECTS="$WORK_DIR/projects.json"

# ── output helpers ────────────────────────────────────────────────────────

_w_ok()   { printf "\033[32m✓\033[0m %s\n" "$*"; }
_w_err()  { printf "\033[31m✗\033[0m %s\n" "$*" >&2; }
_w_warn() { printf "\033[33m⚠\033[0m  %s\n" "$*"; }
_w_info() { printf "\033[36m→\033[0m %s\n" "$*"; }
_w_sep()  { printf '\033[2m─────────────────────────────────────────────────────\033[0m\n'; }

# ── helpers internos ──────────────────────────────────────────────────────

_work_expand() {
  printf '%s' "${1/#\~/$HOME}"
}

_work_has_cmd() {
  command -v "$1" &>/dev/null
}

_work_valid_json() {
  [[ -f "$WORK_PROJECTS" ]] && jq empty "$WORK_PROJECTS" &>/dev/null
}

# Busca projeto: retorna 0 (exato), 2 (fuzzy), 1 (não encontrado)
_work_find_project() {
  local name="$1"
  local exact
  exact=$(jq -r --arg n "$name" 'if has($n) then $n else empty end' "$WORK_PROJECTS" 2>/dev/null)
  if [[ -n "$exact" ]]; then
    printf '%s' "$exact"
    return 0
  fi
  local fuzzy
  fuzzy=$(jq -r --arg n "$name" 'keys[] | select(test($n; "i"))' "$WORK_PROJECTS" 2>/dev/null | head -1)
  if [[ -n "$fuzzy" ]]; then
    printf '%s' "$fuzzy"
    return 2
  fi
  return 1
}

# ── abertura de processos ─────────────────────────────────────────────────

_work_open_tab() {
  local title="$1" dir="$2" cmd="$3"
  local dir_exp
  dir_exp="$(_work_expand "$dir")"
  if [[ ! -d "$dir_exp" ]]; then
    _w_err "Pasta não existe: $dir_exp  (aba \"$title\" ignorada)"
    return 1
  fi
  # ptyxis usa GApplication/DBus — env vars não são herdadas, por isso usamos arquivo temporário
  local tmpf
  tmpf=$(mktemp --suffix=.zsh)
  printf '%s\n' "$cmd" > "$tmpf"
  ptyxis --tab -T "$title" -d "$dir_exp" \
    -- zsh -ic "source '$tmpf'; rm -f '$tmpf'; exec zsh" &
  sleep 0.4
}

_work_open_window() {
  local title="$1" dir="$2" cmd="$3"
  local dir_exp
  dir_exp="$(_work_expand "$dir")"
  if [[ ! -d "$dir_exp" ]]; then
    _w_err "Pasta não existe: $dir_exp  (janela \"$title\" ignorada)"
    return 1
  fi
  local tmpf
  tmpf=$(mktemp --suffix=.zsh)
  printf '%s\n' "$cmd" > "$tmpf"
  ptyxis --new-window -T "$title" -d "$dir_exp" \
    -- zsh -ic "source '$tmpf'; rm -f '$tmpf'; exec zsh" &
  sleep 0.4
}

# ── comandos de gestão ────────────────────────────────────────────────────

_work_list() {
  if ! _work_valid_json; then
    _w_err "projects.json não encontrado ou inválido: $WORK_PROJECTS"
    _w_info "Use: work new project"
    return 1
  fi
  local count
  count=$(jq 'keys | length' "$WORK_PROJECTS")
  if [[ "$count" -eq 0 ]]; then
    _w_warn "Nenhum projeto cadastrado."
    _w_info "Use: work new project"
    return 0
  fi
  echo ""
  printf "\033[1mProjetos disponíveis:\033[0m\n"
  jq -r 'to_entries[] | [.key, .value.root, (.value.ai // "0")] | @tsv' "$WORK_PROJECTS" \
    | while IFS=$'\t' read -r pname proot pai; do
        local ai_label=""
        case "$pai" in
          1) ai_label="  \033[2m[claude]\033[0m" ;;
          2) ai_label="  \033[2m[copilot]\033[0m" ;;
          3) ai_label="  \033[2m[claude|copilot]\033[0m" ;;
        esac
        printf "  \033[36m•\033[0m \033[1m%-20s\033[0m \033[2m%s\033[0m%b\n" "$pname" "$proot" "$ai_label"
      done
  echo ""
}

_work_info() {
  local project="$1"
  if ! _work_valid_json; then
    _w_err "projects.json inválido."
    return 1
  fi
  if ! jq -e --arg n "$project" 'has($n)' "$WORK_PROJECTS" &>/dev/null; then
    _w_err "Projeto \"$project\" não encontrado."
    _work_list
    return 1
  fi

  local data
  data=$(jq --arg n "$project" '.[$n]' "$WORK_PROJECTS")

  echo ""
  _w_sep
  printf "\033[1m  Projeto: %s\033[0m\n" "$project"
  _w_sep

  local root editor ai ai_dir
  root=$(printf '%s' "$data" | jq -r '.root')
  editor=$(printf '%s' "$data" | jq -r '.editor // ""')
  ai=$(printf '%s' "$data" | jq -r '.ai // "0"')
  ai_dir=$(printf '%s' "$data" | jq -r '.ai_dir // .root')

  local root_status=""
  [[ ! -d "$(_work_expand "$root")" ]] && root_status=" \033[31m(não existe!)\033[0m"
  printf "  \033[2mRaiz:\033[0m   %b%b\n" "$root" "$root_status"
  printf "  \033[2mEditor:\033[0m %s\n" "${editor:-(nenhum)}"

  local ai_label
  case "$ai" in
    0) ai_label="nenhum" ;;
    1) ai_label="claude" ;;
    2) ai_label="copilot" ;;
    3) ai_label="claude e copilot" ;;
  esac
  printf "  \033[2mIA:\033[0m     %s  \033[2m(pasta: %s)\033[0m\n" "$ai_label" "$ai_dir"

  echo ""
  printf "  \033[1mProcessos:\033[0m\n"
  local i=0 pn pc pd po where dir_warn
  while IFS= read -r proc; do
    i=$((i+1))
    dir_warn=""
    pn=$(printf '%s' "$proc" | jq -r '.name')
    pc=$(printf '%s' "$proc" | jq -r '.command')
    pd=$(printf '%s' "$proc" | jq -r '.dir')
    po=$(printf '%s' "$proc" | jq -r '.open')
    case "$po" in
      tab)    where="nova aba" ;;
      window) where="nova janela" ;;
      here)   where="terminal atual" ;;
      *)      where="$po" ;;
    esac
    [[ ! -d "$(_work_expand "$pd")" ]] && dir_warn=" \033[31m← pasta não existe!\033[0m"
    printf "  %d. \033[36m%s\033[0m \033[2m(%s)\033[0m\n" "$i" "$pn" "$where"
    printf "     \033[2mpasta:\033[0m   %b%b\n" "$pd" "$dir_warn"
    printf "     \033[2mcomando:\033[0m %s\n" "$pc"
  done < <(printf '%s' "$data" | jq -c '.processes[]')

  _w_sep
  echo ""
  printf "\033[2mComo usar:\033[0m\n"
  printf "  work %s\n" "$project"
  [[ "$ai" == "1" || "$ai" == "3" ]] && printf "  work %s claude\n"   "$project"
  [[ "$ai" == "2" || "$ai" == "3" ]] && printf "  work %s copilot\n"  "$project"
  echo ""
}

_work_delete() {
  local project="$1"
  if ! _work_valid_json; then
    _w_err "projects.json inválido."
    return 1
  fi
  if ! jq -e --arg n "$project" 'has($n)' "$WORK_PROJECTS" &>/dev/null; then
    _w_err "Projeto \"$project\" não encontrado."
    _work_list
    return 1
  fi
  _w_warn "Isso vai remover \"$project\" de projects.json."
  printf "Confirmar remoção? [s/N]: "
  read -r confirm
  if [[ "${confirm:l}" != "s" ]]; then
    echo "↺ Cancelado."
    return 0
  fi
  local tmp
  tmp=$(mktemp)
  if jq --arg n "$project" 'del(.[$n])' "$WORK_PROJECTS" > "$tmp" \
      && jq empty "$tmp" &>/dev/null; then
    mv "$tmp" "$WORK_PROJECTS"
    _w_ok "Projeto \"$project\" removido."
  else
    rm -f "$tmp"
    _w_err "Falha ao salvar. Nada foi alterado."
    return 1
  fi
}

# ── help ──────────────────────────────────────────────────────────────────

_work_help() {
  echo ""
  printf "\033[1mwork\033[0m — workspace launcher\n"
  echo ""
  printf "\033[1mComandos:\033[0m\n"
  printf "  work \033[36m<projeto>\033[0m \033[2m[claude|copilot]\033[0m   inicia o projeto\n"
  printf "  work \033[36mnew project\033[0m                  cadastra novo projeto\n"
  printf "  work \033[36mlist\033[0m                         lista projetos cadastrados\n"
  printf "  work \033[36minfo\033[0m \033[36m<projeto>\033[0m               mostra detalhes e avisa problemas\n"
  printf "  work \033[36mdelete\033[0m \033[36m<projeto>\033[0m             remove projeto\n"
  printf "  work \033[36mhelp\033[0m                         esta mensagem\n"
  echo ""
  if _work_valid_json; then
    printf "\033[2mProjetos:\033[0m "
    jq -r '[keys[]] | join(", ")' "$WORK_PROJECTS"
    echo ""
  fi
}

# ── wizard: work new project ──────────────────────────────────────────────

_work_new_project() {
  echo ""
  printf "\033[1m╔══════════════════════════════════╗\033[0m\n"
  printf "\033[1m║       work — novo projeto        ║\033[0m\n"
  printf "\033[1m╚══════════════════════════════════╝\033[0m\n"
  printf "\033[2m  Ctrl+C a qualquer momento para cancelar.\033[0m\n"

  # ─ [1/4] Nome ──────────────────────────────────────────────────────────
  echo ""
  local name
  while true; do
    printf "\033[1m[1/4]\033[0m Nome do projeto: "
    read -r name

    if [[ -z "$name" ]]; then
      _w_err "Nome não pode ser vazio."; continue
    fi
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      _w_err "Use apenas letras, números, - e _  (sem espaços)"; continue
    fi
    if _work_valid_json && jq -e --arg n "$name" 'has($n)' "$WORK_PROJECTS" &>/dev/null; then
      _w_warn "Projeto \"$name\" já existe."
      printf "     Sobrescrever? [s/N]: "
      read -r ow
      [[ "${ow:l}" != "s" ]] && { echo "     ↺ Escolha outro nome."; continue; }
    fi
    break
  done
  _w_ok "Nome: $name"

  # ─ [2/4] Pasta raiz ────────────────────────────────────────────────────
  echo ""
  local root
  while true; do
    printf "\033[1m[2/4]\033[0m Pasta raiz \033[2m[~/dev/%s]\033[0m: " "$name"
    read -r root
    root="${root:-~/dev/$name}"

    local root_exp
    root_exp="$(_work_expand "$root")"

    if [[ ! -d "$root_exp" ]]; then
      _w_warn "\"$root_exp\" não existe."
      printf "     Criar a pasta? [s/N]: "
      read -r mk
      if [[ "${mk:l}" == "s" ]]; then
        if mkdir -p "$root_exp"; then
          _w_ok "Pasta criada."
        else
          _w_err "Não foi possível criar. Informe outro caminho."
          continue
        fi
      else
        echo "     ↺ Informe outra pasta."; continue
      fi
    fi
    break
  done
  _w_ok "Raiz: $root"

  echo ""
  printf "     Abrir VS Code ao iniciar? [s/N]: "
  read -r use_editor
  local editor_cmd=""
  if [[ "${use_editor:l}" == "s" ]]; then
    if ! _work_has_cmd code; then
      _w_warn "\"code\" não encontrado no PATH. Será configurado mesmo assim."
    fi
    editor_cmd="code"
  fi

  # ─ [3/4] Processos ─────────────────────────────────────────────────────
  echo ""
  local num_procs
  while true; do
    printf "\033[1m[3/4]\033[0m Quantos processos paralelos? \033[2m[1]\033[0m: "
    read -r num_procs
    num_procs="${num_procs:-1}"
    if [[ "$num_procs" =~ ^[1-9][0-9]*$ ]] && [[ "$num_procs" -le 10 ]]; then
      break
    fi
    _w_err "Informe um número entre 1 e 10."
  done

  local processes_json="[]"
  local has_here=0
  local i pn pc pd po bin

  for i in $(seq 1 "$num_procs"); do
    echo ""
    printf "     \033[1m— Processo %d/%d —\033[0m\n" "$i" "$num_procs"

    printf "     Nome da aba  : "
    read -r pn
    pn="${pn:-Processo $i}"

    while true; do
      printf "     Comando      : "
      read -r pc
      if [[ -z "$pc" ]]; then
        _w_err "Comando não pode ser vazio."; continue
      fi
      # Avisa se o binário não existe (ignora caminhos absolutos, $VAR, e env=val)
      bin="${pc%% *}"
      if [[ "$bin" != /* ]] && [[ "$bin" != '$'* ]] && [[ "$bin" != '~'* ]] && [[ "$bin" != *=* ]]; then
        if ! _work_has_cmd "$bin"; then
          _w_warn "\"$bin\" não encontrado no PATH agora."
          printf "     Continuar mesmo assim? \033[2m[S/n]\033[0m: "
          read -r cont
          [[ "${cont:l}" == "n" ]] && continue
        fi
      fi
      break
    done

    while true; do
      printf "     Pasta        \033[2m(Enter = pasta raiz)\033[0m: "
      read -r pd
      pd="${pd:-$root}"
      local pd_exp
      pd_exp="$(_work_expand "$pd")"
      if [[ ! -d "$pd_exp" ]]; then
        _w_warn "\"$pd_exp\" não existe."
        printf "     Criar? [s/N]: "
        read -r mkd
        if [[ "${mkd:l}" == "s" ]]; then
          if mkdir -p "$pd_exp"; then
            _w_ok "Pasta criada."
          else
            _w_err "Não foi possível criar."
            pd="$root"
            _w_info "Usando pasta raiz: $root"
          fi
        else
          pd="$root"
          _w_info "Usando pasta raiz: $root"
        fi
      fi
      break
    done

    printf "     Abrir em     : \033[36m[1]\033[0m nova aba   \033[36m[2]\033[0m nova janela   \033[36m[3]\033[0m aqui (terminal atual)\n"
    while true; do
      printf "     → escolha \033[2m[1]\033[0m: "
      read -r po
      po="${po:-1}"
      case "$po" in
        1) po="tab";    break ;;
        2) po="window"; break ;;
        3)
          if [[ $has_here -eq 1 ]]; then
            _w_err "Só um processo pode usar o terminal atual. Escolha 1 ou 2."
            continue
          fi
          po="here"; has_here=1; break ;;
        *) _w_err "Escolha 1, 2 ou 3." ;;
      esac
    done

    processes_json=$(printf '%s' "$processes_json" | jq \
      --arg n "$pn" --arg c "$pc" --arg d "$pd" --arg o "$po" \
      '. + [{"name":$n,"command":$c,"dir":$d,"open":$o}]')

    _w_ok "Processo $i configurado: \"$pn\" → $po"
  done

  # ─ [4/4] IA ────────────────────────────────────────────────────────────
  echo ""
  printf "\033[1m[4/4]\033[0m Assistente de IA?\n"
  printf "     \033[36m[0]\033[0m Nenhum   \033[36m[1]\033[0m Claude   \033[36m[2]\033[0m Copilot   \033[36m[3]\033[0m Ambos\n"
  local ai_choice
  while true; do
    printf "     → escolha \033[2m[0]\033[0m: "
    read -r ai_choice
    ai_choice="${ai_choice:-0}"
    [[ "$ai_choice" =~ ^[0-3]$ ]] && break
    _w_err "Escolha 0, 1, 2 ou 3."
  done

  local ai_dir=""
  if [[ "$ai_choice" != "0" ]]; then
    if [[ $has_here -eq 1 ]]; then
      _w_warn "Um processo já ocupa o terminal atual."
      _w_info "O assistente abrirá em nova aba nesse caso."
    fi

    # avisa se binários não existem
    [[ "$ai_choice" == "1" || "$ai_choice" == "3" ]] && ! _work_has_cmd claude  \
      && _w_warn "\"claude\" não encontrado no PATH."
    [[ "$ai_choice" == "2" || "$ai_choice" == "3" ]] && ! _work_has_cmd copilot \
      && _w_warn "\"copilot\" não encontrado no PATH."

    printf "     Pasta do assistente \033[2m(Enter = pasta raiz)\033[0m: "
    read -r ai_dir
    ai_dir="${ai_dir:-$root}"

    if [[ ! -d "$(_work_expand "$ai_dir")" ]]; then
      _w_warn "\"$ai_dir\" não existe — usando pasta raiz."
      ai_dir="$root"
    fi
  fi

  # ─ Resumo ───────────────────────────────────────────────────────────────
  echo ""
  _w_sep
  printf "\033[1m  Resumo — work %s\033[0m\n" "$name"
  _w_sep
  [[ -n "$editor_cmd" ]] && printf "  \033[2meditor:\033[0m   VS Code → %s\n" "$root"

  while IFS= read -r proc; do
    local _n _c _d _o _where
    _n=$(printf '%s' "$proc" | jq -r '.name')
    _c=$(printf '%s' "$proc" | jq -r '.command')
    _d=$(printf '%s' "$proc" | jq -r '.dir')
    _o=$(printf '%s' "$proc" | jq -r '.open')
    case "$_o" in
      tab)    _where="nova aba" ;;
      window) _where="nova janela" ;;
      here)   _where="terminal atual" ;;
    esac
    printf "  \033[36m%-16s\033[0m → %-15s\n" "$_n" "$_where"
    printf "  \033[2m%-16s   pasta:   %s\033[0m\n" "" "$_d"
    printf "  \033[2m%-16s   comando: %s\033[0m\n" "" "$_c"
  done < <(printf '%s' "$processes_json" | jq -c '.[]')

  if [[ "$ai_choice" != "0" ]]; then
    local ai_label
    case "$ai_choice" in
      1) ai_label="claude" ;;
      2) ai_label="copilot" ;;
      3) ai_label="claude / copilot" ;;
    esac
    local _ai_where="terminal atual"
    [[ $has_here -eq 1 ]] && _ai_where="nova aba (se conflito)"
    printf "  \033[36m%-16s\033[0m → %s → \033[2m%s\033[0m\n" "$ai_label" "$_ai_where" "$ai_dir"
  fi
  _w_sep
  echo ""

  printf "Confirmar e salvar? [s/N]: "
  read -r confirm_final
  if [[ "${confirm_final:l}" != "s" ]]; then
    echo "↺ Cancelado. Nada foi salvo."
    return 0
  fi

  # ─ Salvar com validação ────────────────────────────────────────────────
  mkdir -p "$WORK_DIR"

  local new_entry
  new_entry=$(jq -n \
    --arg root "$root" \
    --arg editor "$editor_cmd" \
    --argjson procs "$processes_json" \
    --arg ai "$ai_choice" \
    --arg ai_dir "${ai_dir:-$root}" \
    '{root:$root, editor:$editor, processes:$procs, ai:$ai, ai_dir:$ai_dir}')

  local tmp_file
  tmp_file=$(mktemp)

  local ok=0
  if [[ -f "$WORK_PROJECTS" ]]; then
    jq --arg n "$name" --argjson p "$new_entry" '.[$n] = $p' \
      "$WORK_PROJECTS" > "$tmp_file" && ok=1
  else
    jq -n --arg n "$name" --argjson p "$new_entry" '{($n): $p}' \
      > "$tmp_file" && ok=1
  fi

  if [[ $ok -eq 0 ]] || ! jq empty "$tmp_file" &>/dev/null; then
    rm -f "$tmp_file"
    _w_err "JSON gerado é inválido. Nada foi salvo."
    return 1
  fi

  mv "$tmp_file" "$WORK_PROJECTS"

  echo ""
  _w_ok "Projeto \"$name\" salvo!"
  printf "\033[2mComandos:\033[0m\n"
  printf "  work %s\n" "$name"
  [[ "$ai_choice" == "1" || "$ai_choice" == "3" ]] && printf "  work %s claude\n"   "$name"
  [[ "$ai_choice" == "2" || "$ai_choice" == "3" ]] && printf "  work %s copilot\n"  "$name"
  echo ""
}

# ── função principal ──────────────────────────────────────────────────────

function work() {
  if ! _work_has_cmd jq; then
    _w_err "jq não instalado. Rode: sudo dnf install jq"
    return 1
  fi

  case "${1:-}" in
    ""|help)
      _work_help
      return 0 ;;
    list)
      _work_list
      return 0 ;;
    info)
      if [[ -z "${2:-}" ]]; then
        _w_err "Uso: work info <projeto>"
        _work_list; return 1
      fi
      _work_info "$2"; return ;;
    delete)
      if [[ -z "${2:-}" ]]; then
        _w_err "Uso: work delete <projeto>"
        _work_list; return 1
      fi
      _work_delete "$2"; return ;;
    new)
      if [[ "${2:-}" != "project" ]]; then
        _w_err "Comando inválido. Quis dizer: work new project?"
        return 1
      fi
      _work_new_project; return ;;
  esac

  local project="$1"
  local modifier="${2:-}"

  # Valida JSON
  if ! _work_valid_json; then
    _w_err "projects.json não encontrado ou corrompido: $WORK_PROJECTS"
    _w_info "Use: work new project"
    return 1
  fi

  # Busca projeto com fuzzy
  local found find_status
  found=$(_work_find_project "$project")
  find_status=$?

  if [[ $find_status -eq 1 ]]; then
    _w_err "Projeto \"$project\" não encontrado."
    _work_list
    return 1
  fi

  if [[ $find_status -eq 2 ]]; then
    printf "\033[33m⚠\033[0m  \"%s\" não encontrado. Você quis dizer \033[1m%s\033[0m?\n" "$project" "$found"
    printf "Iniciar \"%s\"? [S/n]: " "$found"
    read -r confirm
    [[ "${confirm:l}" == "n" ]] && return 0
  fi

  project="$found"

  # Valida modifier
  local run_ai=""
  if [[ -n "$modifier" ]]; then
    case "$modifier" in
      claude|copilot) run_ai="$modifier" ;;
      *)
        _w_err "\"$modifier\" não é um modificador válido."
        _w_info "Uso: work $project claude   ou   work $project copilot"
        return 1 ;;
    esac
  fi

  local data root editor_cmd ai ai_dir
  data=$(jq --arg n "$project" '.[$n]' "$WORK_PROJECTS")
  root=$(printf '%s' "$data" | jq -r '.root')
  editor_cmd=$(printf '%s' "$data" | jq -r '.editor // ""')
  ai=$(printf '%s' "$data" | jq -r '.ai // "0"')
  ai_dir=$(printf '%s' "$data" | jq -r '.ai_dir // .root')

  # Valida modifier contra config do projeto (avisa, não bloqueia)
  if [[ -n "$run_ai" ]]; then
    local supported=0
    case "$run_ai" in
      claude)  [[ "$ai" == "1" || "$ai" == "3" ]] && supported=1 ;;
      copilot) [[ "$ai" == "2" || "$ai" == "3" ]] && supported=1 ;;
    esac
    if [[ $supported -eq 0 ]]; then
      _w_warn "\"$run_ai\" não estava configurado para \"$project\"."
      printf "Iniciar mesmo assim? [S/n]: "
      read -r cont
      [[ "${cont:l}" == "n" ]] && return 0
    fi
    # Verifica se o binário existe
    if ! _work_has_cmd "$run_ai"; then
      _w_err "\"$run_ai\" não encontrado no PATH. Verifique se está instalado."
      return 1
    fi
  fi

  # Verifica editor
  if [[ -n "$editor_cmd" ]]; then
    if ! _work_has_cmd "$editor_cmd"; then
      _w_warn "Editor \"$editor_cmd\" não encontrado. Pulando."
      editor_cmd=""
    else
      local root_exp
      root_exp="$(_work_expand "$root")"
      if [[ -d "$root_exp" ]]; then
        "$editor_cmd" "$root_exp" &
      else
        _w_warn "Pasta raiz não existe: $root_exp  (editor não foi aberto)"
      fi
    fi
  fi

  # Abre processos
  local has_here=0 here_cmd="" here_dir="" pn pc pd po

  while IFS= read -r proc; do
    pn=$(printf '%s' "$proc" | jq -r '.name')
    pc=$(printf '%s' "$proc" | jq -r '.command')
    pd=$(printf '%s' "$proc" | jq -r '.dir')
    po=$(printf '%s' "$proc" | jq -r '.open')
    case "$po" in
      tab)    _work_open_tab    "$pn" "$pd" "$pc" ;;
      window) _work_open_window "$pn" "$pd" "$pc" ;;
      here)   has_here=1; here_cmd="$pc"; here_dir="$pd" ;;
    esac
  done < <(printf '%s' "$data" | jq -c '.processes[]')

  # Abre IA no terminal atual (ou em tab se "here" ocupado)
  if [[ -n "$run_ai" ]]; then
    local ai_exp
    ai_exp="$(_work_expand "$ai_dir")"
    if [[ ! -d "$ai_exp" ]]; then
      _w_warn "Pasta do assistente não existe: $ai_exp — usando diretório atual."
      ai_exp="$PWD"
    fi

    if [[ $has_here -eq 1 ]]; then
      _work_open_tab "$run_ai" "$ai_dir" "$run_ai"
    else
      local orig="$PWD"
      cd "$ai_exp"
      "$run_ai"
      cd "$orig"
      return
    fi
  fi

  # Executa processo "here" (se não há IA tomando o terminal)
  if [[ $has_here -eq 1 ]]; then
    local here_exp
    here_exp="$(_work_expand "$here_dir")"
    if [[ ! -d "$here_exp" ]]; then
      _w_warn "Pasta do processo \"here\" não existe: $here_exp — usando diretório atual."
      here_exp="$PWD"
    fi
    local orig="$PWD"
    cd "$here_exp"
    eval "$here_cmd"
    cd "$orig"
  fi
}
