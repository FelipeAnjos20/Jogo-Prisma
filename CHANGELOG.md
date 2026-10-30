# Changelog

Todas as mudancas notaveis deste projeto serao documentadas neste arquivo.

O formato e baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto segue o [Versionamento Semantico](https://semver.org/lang/pt-BR/).

## [3.3.0] - 2026-10-30

Jogo mais interativo e mais bonito, so no visual e na sensacao: as regras das fases, a
matematica do feixe e as solucoes nao mudaram.

### Adicionado

- Previa da luz (`scripts/light_preview.gd`): com o mouse sobre um espelho, um tracejado mostra
  para onde a luz vai no proximo giro. Usa o calculo puro de `feixe.gd` e liga/desliga com `G`.
- Echo que voa: na dica, ele sai da barra superior, voa ate o espelho que precisa girar, fica
  ao lado dele e depois volta.
- Vitoria cinematografica: camera lenta curta, zoom leve no ultimo cristal e um fragmento
  brilhante que voa do cristal ate o prisma do logo antes do painel de vitoria.
- Conquistas (`scripts/conquistas.gd`): 10 conquistas, com aviso de trofeu na fase e a tela
  "Conquistas e Echo" no menu.
- Visual do Echo liberado por estrelas: cores (menta, rosa, violeta, dourado, arco-iris) e
  acessorios (laco, chapeu de mago, coroa).
- Selecao de fases como o Farol de Aurora: as 10 fases sao andares que acendem conforme sao
  concluidos; a lanterna no topo brilha mais a cada fragmento. Setas escolhem e Enter joga.
- Sala que toca: clicar num espaco vazio solta uma onda de luz e toca uma nota da escala.
- Opcao "Reduzir efeitos" (acessibilidade): sem tremor de camera, flash, camera lenta e zoom.
- Testes: 119 verificacoes (conquistas, recompensas, atalhos por fase e nota da sala).

### Alterado

- Balao do Echo mais estreito e posicionado longe das pecas, do espelho selecionado e do raio.
- Atalhos da barra inferior aparecem aos poucos, conforme a fase.
- Cristais da barra superior viram gemas que acendem; objetivo longo quebra em duas linhas.
- Botoes crescem e brilham ao passar o mouse.
- Menu: "Creditos" e "Sair" dividem a ultima linha para caber "Conquistas e Echo".

### Corrigido

- Texto "Bloqueada" sobreposto ao nome da fase na selecao de fases.
- Barra superior que saia da tela no Windows quando o objetivo da fase era longo.

## [3.2.0] - 2026-10-30

Jogo mais interativo com o jogador: a luz vira musica, o Echo vira personagem e os
fragmentos contam uma historia.

### Adicionado

- A luz vira musica (`scripts/musica.gd`): cada cristal aceso toca a proxima nota de um
  acorde, cada posicao do espelho tem um tom e cada fase termina com a sua melodia.
- Cristal "quase la": o cristal apagado treme e brilha fraco quando o raio passa perto.
- Espelho balanca ao girar e a vitoria solta faiscas por todo o caminho da luz.
- Echo na barra superior (`scripts/echo_face.gd`): olha para o mouse, muda de expressao,
  cochila quando o jogador fica parado e acorda quando ele volta.
- Conversa com o Echo (clique nele ou `T`): dica, curiosidade sobre a luz, falar menos/mais.
  Perguntas com botoes de resposta (teclas `1` a `4` tambem respondem).
- Echo pergunta o nome do jogador na primeira partida e passa a usar o nome nas falas.
- Na fase 2, Echo pergunta se o jogador quer pistas ("Sim, me ajuda!" / "Deixa comigo!").
  No modo "Deixa comigo" so comemora e avisa eventos. Opcao tambem em *Opcoes*.
- Historia dos fragmentos (`scripts/historia.gd`): 10 memorias do Farol de Aurora, mostradas
  na vitoria e na tela "Memorias do Prisma"; final com agradecimento do Echo pelo nome.
  Aceita ilustracoes opcionais em `assets/story/fragmento_XX.png`.
- Testes: 103 verificacoes (musica, historia, nome do jogador e modo "Deixa comigo").

### Alterado

- Opcoes em dois cartoes, com o novo cartao "Voce e o Echo".
- `COMO_ABRIR.md`: nome do arquivo da versao mais recente, aviso sobre antivirus e sobre o
  botao "Entrada" do Godot 4.4+.

## [3.1.0] - 2026-10-30

Interatividade com o jogador e parte educativa.

### Adicionado

- Echo que conversa e reage em tempo real (`scripts/echo_brain.gd`): comemora cristal aceso,
  avisa cristal apagado, raio passando perto ("Quase!"), retorno de "quente ou frio", cor errada,
  muitos giros sem progresso e posicao repetida; varias falas por situacao, com prioridade e
  intervalo para nao poluir a tela.
- Fala do Echo com efeito de digitacao, som de "fala" e expressoes (feliz, pensativo, surpreso).
- Guia de angulos (`scripts/angle_guide.gd`, tecla `G`, opcao no menu): inclinacao do espelho
  selecionado e, no ponto de impacto, a normal e os angulos de incidencia e reflexao.
- Caixa de informacao ao parar o mouse sobre qualquer peca.
- Comentario do Echo no painel de vitoria e botao "Por que funcionou?" com a explicacao da
  solucao do jogador (reflexoes, desvio do raio, divisor, filtro e prisma).
- `Feixe.tracar()` passa a devolver as reflexoes (entrada, saida, normal e angulo).
- `Geometria`: normal voltada para o raio, angulo de incidencia e inclinacao do espelho.
- Testes: 79 verificacoes, incluindo a lei da reflexao (incidencia = reflexao).

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
