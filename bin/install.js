#!/usr/bin/env node
'use strict';

const https = require('https');
const http = require('http');
const {
  existsSync,
  mkdirSync,
  writeFileSync,
  readFileSync,
  appendFileSync,
  copyFileSync,
} = require('fs');
const { join } = require('path');
const os = require('os');

const HOME = os.homedir();
const WORK_DIR = process.env.WORK_INSTALL_DIR || join(HOME, 'dev', 'automacoes', 'work');
const ZSHRC = join(HOME, '.zshrc');
const GITHUB_RAW = 'https://raw.githubusercontent.com/eltobsjr/WorkAutomations/main';
const MARKER = '# --- work automation ---';
const SOURCE_LINE = `source "${WORK_DIR}/work.zsh"`;

const ok   = (msg) => console.log(`\x1b[32m✓\x1b[0m ${msg}`);
const info = (msg) => console.log(`\x1b[36m→\x1b[0m ${msg}`);
const warn = (msg) => console.log(`\x1b[33m⚠\x1b[0m  ${msg}`);
const fail = (msg) => { console.error(`\x1b[31m✗\x1b[0m ${msg}`); process.exit(1); };

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = require('fs').createWriteStream(dest);
    const protocol = url.startsWith('https') ? https : http;
    protocol.get(url, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        file.destroy();
        return download(res.headers.location, dest).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        file.destroy();
        return reject(new Error(`HTTP ${res.statusCode} ao baixar ${url}`));
      }
      res.pipe(file);
      file.on('finish', () => file.close(resolve));
      file.on('error', reject);
    }).on('error', reject);
  });
}

async function main() {
  console.log('\n\x1b[1mwork-automations — instalador\x1b[0m\n');

  // avisa se não é zsh
  const shell = process.env.SHELL || '';
  if (!shell.includes('zsh')) {
    warn(`Shell detectado: ${shell || 'desconhecido'}`);
    warn('work requer zsh. Adicione o source no ~/.zshrc manualmente se necessário.');
    console.log('');
  }

  // cria diretório
  mkdirSync(WORK_DIR, { recursive: true });
  ok(`Diretório: ${WORK_DIR}`);

  // work.zsh: usa arquivo local do pacote se disponível, senão baixa
  const localWorkZsh = join(__dirname, '..', 'work.zsh');
  if (existsSync(localWorkZsh)) {
    copyFileSync(localWorkZsh, join(WORK_DIR, 'work.zsh'));
    ok('work.zsh instalado (pacote local)');
  } else {
    info('Baixando work.zsh do GitHub...');
    await download(`${GITHUB_RAW}/work.zsh`, join(WORK_DIR, 'work.zsh'));
    ok('work.zsh baixado do GitHub');
  }

  // projects.json: não sobrescreve se já existe
  const projectsPath = join(WORK_DIR, 'projects.json');
  if (!existsSync(projectsPath)) {
    writeFileSync(projectsPath, '{}\n');
    ok('projects.json criado (vazio)');
  } else {
    ok('projects.json existente preservado');
  }

  // .zshrc
  let zshrc = '';
  try { zshrc = readFileSync(ZSHRC, 'utf8'); } catch {}

  if (zshrc.includes(SOURCE_LINE)) {
    ok('work já estava no .zshrc');
  } else {
    appendFileSync(ZSHRC, `\n${MARKER}\n${SOURCE_LINE}\n`);
    ok('source adicionado ao .zshrc');
  }

  console.log('\n\x1b[32m✓ Instalação concluída!\x1b[0m\n');
  console.log(`  Ative agora: \x1b[1msource ~/.zshrc\x1b[0m\n`);
  console.log('Comandos:');
  console.log('  work new project         — cadastra novo projeto');
  console.log('  work <projeto>           — inicia o projeto');
  console.log('  work <projeto> claude    — inicia com Claude no terminal');
  console.log('  work list                — lista projetos cadastrados');
  console.log('  work help                — ajuda completa');
  console.log('');
}

main().catch((e) => fail(e.message));
