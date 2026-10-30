# PRISMA — Plano para deixar o jogo mais bonito (versão 3.3)

Cole este arquivo inteiro na conversa com a outra IA. O código mais recente (versão 3.2, tag
`v3.2.0`) já está no GitHub, na branch `main`: comece puxando a versão atual (`git pull origin main`).

---

## PARTE 1 — O pedido (prompt)

Você vai continuar o desenvolvimento do **PRISMA**, um jogo de puzzle de luz em **Godot 4.6**
feito para a faculdade. A entrega é **hoje**, então trabalhe por prioridade: termine e teste a
Prioridade 1 inteira antes de começar a Prioridade 2.

**Objetivo desta versão (3.3.0):** deixar o jogo **mais bonito e mais gostoso de jogar**, só no visual
e na sensação. **Não mexa nas regras das fases, na matemática do feixe nem nas soluções.**
A professora pediu para deixar a matemática de lado por enquanto.

### Prioridade 1 (impacto alto, rápido)

1. **O feixe "nasce" ao entrar na fase.** Hoje o raio aparece pronto. Faça a luz sair do emissor e
   crescer até o fim do caminho em cerca de 0,6 s, com um brilho na ponta. O emissor dá um pulso de
   "carga" antes de disparar.
   - Onde: `scripts/light_beam.gd` (desenho) e `scripts/emitter.gd`. Recorte só o **desenho** dos
     segmentos pela distância percorrida (`segment["distance"]` já existe). **Não altere `trace()` nem
     `scripts/feixe.gd`**, que o jogo e os testes usam.
2. **Vitória cinematográfica.** Quando o último cristal acende: câmera lenta curta (cerca de 0,3 s com
   `Engine.time_scale`, restaurado depois), zoom leve da `Camera2D` no último cristal, e um **fragmento
   brilhante que voa** do cristal até o topo da tela antes de o painel de vitória aparecer.
   - Onde: `scripts/main.gd` (`_complete_level`) e `scripts/game_hud.gd`. O painel já espera 1 s antes
     de aparecer; ajuste esse tempo, se precisar, para caber a animação.
   - Volte `Engine.time_scale` para 1.0 também ao sair da fase, ao reiniciar e ao pausar.
3. **Cada sala com a sua cor.** Hoje toda sala é azul. Dê a cada fase um tom de ambiente (fundo,
   grade e vinheta) que acompanha a história: fases 1–3 azul frio, 4–5 violeta, 6–7 âmbar/laranja,
   8–9 verde-azulado, 10 dourado. Escolha tons que não confundam com o vermelho, o verde e o azul
   das cores de luz.
   - Onde: `scripts/scene_background.gd` (cores) e um campo opcional `"theme"` em `scripts/levels.gd`.
     **Se mexer em `levels.gd`, mude também `tools/level_simulator/levels.json`**, porque um é gerado a
     partir do outro.
4. **Poeira que a luz ilumina.** O fundo já tem partículas de poeira (`scene_background.gd`). Faça as
   partículas que passam perto do feixe brilharem mais forte, na cor daquele trecho do raio.
   Use o `light_beam.segments` do nó `Puzzle/LightBeam`.
5. **Opção "Reduzir efeitos"** em *Opções → Você e o Echo* (ou no primeiro cartão): desliga tremor de
   câmera, flash branco, câmera lenta e zoom. É acessibilidade, para quem sente desconforto com flashes.
   Salve em `GameState` como as outras opções (`save_data` e `load_data`).
6. **Ícone e tela de abertura.** Crie um ícone próprio (prisma com o espectro, no estilo do jogo) e use
   como `icon.svg`, como ícone do `.exe` (`application/icon` em `export_presets.cfg`, que pede `.ico`)
   e como *boot splash* (`application/boot_splash/image` em `project.godot`, fundo `#03050A`).

### Prioridade 2 (se der tempo)

7. **HUD com ícones desenhados.** Troque os textos "Dica (H)" e "Reiniciar (R)" por ícones desenhados
   por código (lâmpada, seta circular) com a tecla pequena embaixo. Mostre os cristais como gemas que
   acendem, em vez de "Cristais: 0 / 3", e as rotações como uma barrinha que muda de cor ao passar da meta.
8. **Menu que reage ao mouse.** No `scripts/menu_art.gd`, o raio de entrada do prisma acompanha
   levemente a posição do mouse, e os fragmentos já recuperados giram devagar em volta do prisma.
9. **Botões com vida.** Botões crescem 3–5% e brilham ao passar o mouse (tween de `scale` com
   `pivot_offset` no centro). Faça isso uma vez só, em `UI.make_button()` (`scripts/ui_kit.gd`).
10. **Transição de luz entre fases.** Troque o fade escuro de `scripts/transition.gd` por uma "íris"
    de luz que fecha e abre a partir do centro (pode ser um shader simples de círculo ou um desenho
    por código).

### Prioridade 3 (só se sobrar tempo)

11. **Seleção de fases como o Farol de Aurora:** as 10 fases como andares de um farol, de baixo para
    cima, iluminando-se conforme são concluídas (`scripts/level_select.gd`).
12. **Fonte própria:** uma fonte livre com licença OFL (por exemplo, Nunito ou Fredoka), com o
    arquivo de licença junto, em `assets/fonts/`. Troque em `UI.font()` (`scripts/ui_kit.gd`).

### Regras obrigatórias

- **Arte por código:** todo o visual do jogo é desenhado com `_draw()`. Continue assim. Não use imagens
  baixadas da internet. Exceções permitidas: ícone/splash criados por você e fonte com licença OFL
  (inclua a licença e cite em `docs/creditos.md`).
- **Não quebre nada:** os **103 testes** precisam continuar passando:
  ```bash
  godot --headless --editor --quit-after 60        # importa o projeto (1ª vez)
  godot --headless --script res://tests/run_tests.gd
  ```
  Esperado: `OK: 103/103 testes passaram` (ou mais, se você criar testes). Crie testes para regras puras
  novas (por exemplo, a função que dá a cor de cada fase).
- **Confira na tela:** rode o jogo, passe pelas 10 fases e veja menu, fase, vitória, opções e tela
  final. Se puder, gere prints com a tela virtual (`xvfb-run`) para conferir.
- **Desempenho:** o jogo usa o renderizador **GL Compatibility** e precisa rodar liso em notebook
  simples. Evite efeitos pesados por quadro e limite partículas.
- **Textos do jogo** em português do Brasil, com acentos. **Comentários no código** em português,
  **sem acentos**, curtos, no mesmo estilo dos arquivos atuais.
- **Documentação:** ao terminar, atualize `CHANGELOG.md` (nova seção `[3.3.0]`), o README (seção
  "Mais interativo" ou uma nova "Mais bonito") e o `docs/GDD.md` (seções 11 *Direção de arte* e
  13 *Acessibilidade*). Troque `v3.2` por `v3.3` no rodapé do menu (`scripts/menu.gd`).
- **Commits:** padrão Conventional Commits em português sem acento (`feat: ...`, `fix: ...`, `docs: ...`),
  autor `Felipe dos Anjos <285692902+FelipeAnjos20@users.noreply.github.com>`, **sem** linha
  `Co-Authored-By`.
- Ao final, me entregue: lista do que foi feito, o que ficou de fora e o resultado dos testes.

---

## PARTE 2 — Contexto do projeto

### Identificação

- **Jogo:** PRISMA — O lugar onde a luz quebrou. Puzzle 2D de luz e espelhos, jogo sério.
- **Disciplina:** PAC Extensionista III, Engenharia de Software, Católica de Santa Catarina.
- **Equipe:** Eduardo Macedo, Felipe dos Anjos, Felipe Schwabe e Vinicius Mesquita.
- **Repositório:** https://github.com/FelipeAnjos20/Jogo-Prisma (branch `main`).
- **Motor:** Godot **4.6.3** (Standard, sem .NET), renderizador **GL Compatibility**, janela 1280×720
  com `stretch_mode = canvas_items`.

### Como o jogo funciona

O jogador gira espelhos (passos de 15°) para levar o raio de luz do **emissor** até **todos os
cristais** da sala ao mesmo tempo. São **10 fases** com elementos novos: espelho travado, bloco que
absorve luz, divisor de feixe (vidro roxo), filtros de cor, cristais que exigem cor e prisma que separa
a luz branca em vermelho, verde e azul. Não existe derrota. Menos rotações dão mais estrelas
(3 por fase, 30 no total). Cada fase recupera um **fragmento** do Prisma de Luz.

**Echo** é o assistente: uma faísca azul com um olho. Ele comenta as ações, dá dicas (`H`), conversa por
botões (clique nele na barra superior ou `T`), pergunta o nome do jogador e se ele quer pistas
("Sim, me ajuda!" / "Deixa comigo!").

**História (v3.2):** o Prisma ficava no **Farol de Aurora**. Uma tempestade o quebrou em dez pedaços,
que caíram nas salas do subsolo. Cada fase devolve uma memória. No fim, descobre-se que Echo é o
último brilho do próprio Prisma.

### O que já existe (não refaça)

- **v3.0:** 10 fases verificadas por simulador, estrelas, recordes, seleção de fases com miniaturas,
  pausa, desfazer (`Z`), dicas em dois níveis, tutorial na fase 1, teclado/mouse/controle,
  navegação dos menus por teclado, cores com forma (▲ ● ■) para daltonismo, efeitos sonoros
  sintetizados por código, CI e CD no GitHub Actions.
- **v3.1:** Echo que reage (quase, quente/frio, cor errada), guia de ângulos (`G`), caixa de
  informação ao passar o mouse, botão "Por que funcionou?" na vitória.
- **v3.2:** a luz vira música (notas por cristal, tom por posição do espelho, melodia por fase),
  cristal "quase lá" que treme, espelho que balança, faíscas na vitória, Echo na barra superior
  (olha o mouse, cochila, clicável), nome do jogador, modo "Deixa comigo", memórias dos fragmentos
  (tela "Memórias do Prisma" no menu) e final personalizado.

### Mapa dos arquivos

| Arquivo | Para que serve |
| --- | --- |
| `project.godot` | Configuração. Cena inicial `scenes/menu.tscn`. Autoloads: `GameState`, `Sfx`, `Transition`. |
| `scenes/menu.tscn` / `scripts/menu.gd` | Menu principal, nome do jogador, Memórias, Como jogar, Opções, Créditos. |
| `scenes/level_select.tscn` / `scripts/level_select.gd` | Seleção de fases (cartões com miniatura). |
| `scenes/main.tscn` / `scripts/main.gd` | Uma fase: monta as peças, entrada do jogador, vitória, falas do Echo. |
| `scenes/game_complete.tscn` / `scripts/game_complete.gd` | Tela final. |
| `scripts/game_hud.gd` | HUD da fase: barra superior, Echo clicável, falas, perguntas, tooltip, vitória, pausa. |
| `scripts/levels.gd` | Dados das 10 fases (gerado de `tools/level_simulator/levels.json`). |
| `scripts/feixe.gd` | **Cálculo puro do caminho da luz.** Usado pelo jogo e pelos testes. Não alterar. |
| `scripts/geometria.gd` | Regras puras: rotação, reflexão, interseções, estrelas. Não alterar. |
| `scripts/light_beam.gd` | Desenha o feixe (camadas com blend aditivo, pulsos, faíscas). |
| `scripts/mirror.gd`, `crystal.gd`, `emitter.gd`, `prism.gd`, `color_filter.gd`, `obstacle.gd` | Peças, cada uma desenhada por código. |
| `scripts/scene_background.gd` | Fundo: gradiente, sala, grade, poeira luminosa e vinheta. |
| `scripts/menu_art.gd` | Prisma animado do menu e da tela final, com os fragmentos. |
| `scripts/ui_kit.gd` | Paleta, fontes, `make_button`, `make_panel`, `make_label`, estrelas e símbolos das cores. |
| `scripts/echo_face.gd` | Rosto do Echo (expressões, olho que segue o mouse). |
| `scripts/echo_brain.gd` | Falas do Echo, `{nome}`, modo "Deixa comigo". |
| `scripts/musica.gd` / `scripts/sfx.gd` | Notas e melodias / síntese de som e música de fundo. |
| `scripts/historia.gd` | As 10 memórias e o final. Ilustrações opcionais em `assets/story/fragmento_XX.png`. |
| `scripts/game_state.gd` | Progresso, opções e salvamento em `user://prisma_save.cfg`. |
| `scripts/transition.gd` | Fade entre cenas e fases. |
| `tests/run_tests.gd` | 103 testes automáticos (regras, 10 fases, música, história, Echo). |
| `.github/workflows/ci.yml` / `cd.yml` | CI roda os testes a cada push na `main`; CD gera o `.exe` e a Release a cada tag `v*.*.*`. |
| `docs/GDD.md`, `README.md`, `CHANGELOG.md`, `COMO_ABRIR.md` | Documentação entregue à professora. |

### Paleta atual (`scripts/ui_kit.gd`)

| Uso | Cor |
| --- | --- |
| Fundo | `#03050A` |
| Painéis | `#090E1A` com borda `#6BB8FF` |
| Texto / texto fraco | `#E0EDFF` / `#99B3D9` |
| Destaque (seleção, estrelas) | `#FFDB5C` |
| Luz branca / vermelha / verde / azul | `#FFED9E` / `#FF4D5C` / `#57FF80` / `#5C9EFF` |

### Cuidados conhecidos

- Os textos do HUD são montados por código (não há cenas `.tscn` para a interface).
- `Engine.time_scale` e `get_tree().paused` afetam tweens e timers: a pausa e as transições usam
  `process_mode = ALWAYS`.
- O jogo pausa sozinho quando a janela perde o foco (`GameState.autopause`).
- O editor do Godot 4.4+ roda o jogo dentro da aba "Jogo". Para clicar no jogo, é preciso ativar o
  botão **Entrada**.
- O `.exe` sem assinatura digital costuma ser marcado como vírus por engano pelo Windows Defender.
