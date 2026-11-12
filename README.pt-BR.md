[English](README.md) | [Português](README.pt-BR.md)

# mise-en-code

Tudo no seu lugar antes de o seu agente de código começar a cozinhar.

*Mise en place* é o hábito de cozinha de preparar e organizar todos os ingredientes antes de cozinhar. O `mise-en-code` faz o mesmo para o [Claude Code](https://claude.com/claude-code): um harness pequeno e opinativo que define convenções, proteções e estado de sessão antes de o agente escrever uma linha de código.

O foco é Django + DRF, React + Vite + TypeScript e fluxos de trabalho no GitHub.

## Princípios

- **Skills planas.** Um diretório por skill em `skills/`, com prefixo de domínio: `wf-` (workflow), `be-` (backend), `fe-` (frontend), `test-`.
- **Hooks em vez de prosa.** Uma regra com resposta sim/não é aplicada por um hook do Claude Code ou por uma checagem de CI, não por uma frase em um prompt.
- **Contexto pequeno.** O `AGENTS.md` fica em cerca de 60 linhas. Cada linha deve evitar um erro real.
- **Estado em arquivos.** O estado entre sessões fica em `feature_list.json`, `progress.md` e commits. Nenhum servidor MCP é obrigatório.
- **Decisões registradas.** Escolhas de arquitetura são ADRs em `docs/decisions/`.

## Estrutura

```
skills/       um diretório plano por skill, cada um com um SKILL.md
agents/       subagentes com modelo fixo e ferramentas mínimas
hooks/        scripts shell para hooks do Claude Code
scripts/      check.sh, as checagens de estrutura que o CI executa
templates/    feature_list.json e progress.md para os seus projetos
docs/decisions/   ADRs
```

## Instalação

```bash
git clone https://github.com/MatheusSlvRibeiro/mise-en-code
cd mise-en-code
./install.sh
```

O `install.sh` cria um symlink de cada skill em `~/.claude/skills/`, de cada agente em `~/.claude/agents/` e de cada hook em `~/.claude/hooks/`. Pode ser executado de novo sem problemas e nunca sobrescreve algo que não seja um link para este repositório.

Os hooks só rodam depois de registrados. Copie as entradas que quiser de [`settings.example.json`](settings.example.json) para o seu `~/.claude/settings.json`.

## Status

O trabalho é acompanhado em [`feature_list.json`](feature_list.json) e [`progress.md`](progress.md). O status segue `pending` → `implemented` → `verified`, e só o mantenedor define `verified`.

## Licença

[MIT](LICENSE)
