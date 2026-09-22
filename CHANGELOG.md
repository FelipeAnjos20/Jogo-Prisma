# Changelog

Todas as mudancas notaveis deste projeto serao documentadas neste arquivo.

O formato e baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto segue o [Versionamento Semantico](https://semver.org/lang/pt-BR/).

## [1.1.1] - 2026-09-22

### Corrigido

- Pipeline de release (`.github/workflows/cd.yml`) nao baixava os export
  templates do Godot, fazendo a exportacao da build Windows Desktop falhar;
  adicionado `include-templates: true` na instalacao do Godot.

## [1.1.0] - 2026-09-22

### Adicionado

- Regras geometricas de rotacao isoladas em `scripts/geometria.gd`, com
  testes automatizados em `tests/run_tests.gd`.
- Pipeline de integracao continua (`.github/workflows/ci.yml`), que roda os
  testes automatizados a cada push/PR na `main`.
- Pipeline de publicacao de release (`.github/workflows/cd.yml`), disparada
  por tags `vMAJOR.MINOR.PATCH`.
- Documentacao de contexto (`docs/contexto.md`), creditos (`docs/creditos.md`)
  e registros de decisao de arquitetura (`docs/adr/`).
- README completo do repositorio, com tabela de controles e estrutura do
  projeto.

### Alterado

- `scripts/mirror.gd` passa a delegar o calculo do proximo angulo de rotacao
  para `Geometria.proximo_angulo()`, mantendo o mesmo comportamento.

### Corrigido

- `GODOT_VERSION` nos workflows de CI/CD, que exigia o formato completo
  `major.minor.patch` (`4.6.3`) para a action `setup-godot@v2`.

## [1.0.0] - 2026-09-21

### Adicionado

- Projeto Godot do PRISMA com as tres fases jogaveis: reflexao basica, desvio
  com obstaculo, e espelho fixo com simetria.
- Espelhos selecionaveis e giraveis em passos de 15 graus.
- Feixe de luz com calculo de reflexao e limite de rebatidas.
- Cristal receptor que ativa ao ser atingido pelo feixe.
- HUD com nome da fase, objetivo, contagem de rotacoes, estado e feedback.
- Musica ambiente no menu e nas fases, com controle de mute.
