# Changelog

Todas as mudancas notaveis deste projeto serao documentadas neste arquivo.

O formato e baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto segue o [Versionamento Semantico](https://semver.org/lang/pt-BR/).

## [3.0.0] - 2026-10-29

Versao entregue na N1. A versao 2.0 foi uma iteracao intermediaria (8 fases)
distribuida apenas como arquivo compactado, fora do repositorio.

### Adicionado

- 7 novas fases (total de 10), com uma mecanica nova por fase.
- Novos elementos: espelho travado, divisor de feixe, filtros de cor, cristais
  que exigem cor e prisma que separa a luz branca em vermelho, verde e azul.
- Progressao: estrelas por meta de rotacoes, recordes, fragmentos do Prisma de
  Luz, desbloqueio de fases e salvamento automatico (`user://prisma_save.cfg`).
- Telas: selecao de fases com miniaturas, menu de pausa, painel de vitoria,
  Como jogar, Opcoes (volume de musica e efeitos, tela cheia) e Creditos.
- Assistente Echo com apresentacao de cada mecanica e dica em dois niveis
  (texto e contorno do angulo certo de um espelho).
- Tutorial visual na fase 1.
- Controles: arrastar para girar, roda do mouse, clique direito, desfazer (`Z`),
  suporte a controle (gamepad) e navegacao dos menus por teclado/controle.
- Acessibilidade: formas para cada cor (triangulo, circulo, quadrado), pausa
  automatica ao perder o foco da janela.
- Identidade visual nova desenhada por codigo (brilho aditivo, particulas,
  transicoes) e 11 efeitos sonoros sintetizados.
- `scripts/feixe.gd`: calculo puro do caminho da luz, usado pelo jogo e pelos
  testes (ADR 005).
- Testes de todas as fases em `tests/run_tests.gd` (66 verificacoes) e novas
  regras puras em `scripts/geometria.gd`.
- Simulador de fases em `tools/level_simulator` (Node.js).
- GDD em `docs/GDD.md` e `docs/GDD_PRISMA.pdf`, manual de reconstrucao, video
  de gameplay e README com guia completo de instalacao, execucao e uso.

### Alterado

- Fases movidas de `scripts/main.gd` para `scripts/levels.gd`; objetos da fase
  criados por codigo, sem limite de espelhos/obstaculos na cena (ADR 001).
- Espelho mantem o angulo normalizado via `Geometria.proximo_angulo()` e anima
  o giro pelo menor caminho (ADR 002).
- Limites do feixe passam a ser por raio, total de raios e segmentos; paredes
  da sala substituem o alcance maximo (ADR 003).
- Janela com escala automatica (`canvas_items`) e tema visual unico.

### Corrigido

- Cor dos trechos refletidos do feixe ficava escondida por uma linha extra.
- Volume voltava para 70% ao abrir o menu e nao era salvo.
- HUD sobreposto a area do puzzle e feixe atravessando as paredes da sala.
- Pipeline de release (`cd.yml`) falhava ao publicar por falta de permissao
  `contents: write` para o `GITHUB_TOKEN`.

### Removido

- `scripts/music_controller.gd` (a musica agora e controlada pelo autoload `Sfx`).

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
