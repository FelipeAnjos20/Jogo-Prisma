# PRISMA - Prototipo Godot 4.x

Este projeto contem uma versao simples e funcional do core loop de PRISMA:

Observar o puzzle -> selecionar espelho -> girar -> alterar o caminho da luz -> acertar o cristal -> receber feedback -> reiniciar/repetir.

## Estrutura recomendada

- `scenes/main.tscn`: cena principal jogavel.
- `scripts/main.gd`: controla HUD, selecao, rotacoes, vitoria e reinicio.
- `scripts/light_beam.gd`: calcula e desenha o raio de luz com reflexoes.
- `scripts/mirror.gd`: espelho selecionavel e giravel.
- `scripts/crystal.gd`: cristal receptor que ativa quando recebe luz.
- `scripts/scene_background.gd`: desenha o cenario da sala com grade, paineis e luzes.
- `scripts/music_controller.gd`: controla a musica ambiente e o mute.
- `assets/`: pasta reservada para artes futuras.
- `assets/audio/prisma_ambient.wav`: trilha ambiente simples do prototipo.
- `ui/`: pasta reservada para temas, fontes e elementos de interface futuros.

## Como montar a cena no Godot

1. Abra o projeto no Godot 4.x.
2. Abra `scenes/main.tscn`.
3. Rode a cena com F6 ou rode o projeto com F5.
4. Clique em um espelho.
5. Use `1`, `2` ou `Tab` para escolher qual espelho controlar.
6. Nas fases seguintes, use tambem `3` e `4` para espelhos extras.
7. Use `Q` para girar para a esquerda e `E` para girar para a direita.
8. Use `R` para reiniciar.
9. Ao ativar o cristal, use `N` para avancar para a proxima fase.
10. Use `M` para ligar/desligar a musica.
11. Use `Esc` para voltar ao menu.

## Configuracao dos objetos

### Emissor

- Tipo: `Node2D`.
- Posicao inicial: `Vector2(120, 360)`.
- Direcao: usa a rotacao do proprio node. Com rotacao `0`, o raio sai para a direita.
- Visual: `Polygon2D` triangular simples.

### Espelhos

- Tipo: `StaticBody2D`.
- Script: `scripts/mirror.gd`.
- Colisor: `CollisionShape2D` com `RectangleShape2D`, tamanho `120 x 12`.
- Interacao: clique esquerdo seleciona o espelho.
- Atalhos: `1` seleciona o primeiro espelho, `2` seleciona o segundo, `Tab` alterna.
- Fases avancadas usam `3` e `4` para espelhos extras.
- Rotacao: `Q` e `E`, em passos de 15 graus.
- Reflexao: o raio usa a normal retornada pelo `intersect_ray`.

### Obstaculos

- Tipo: `StaticBody2D`.
- Script: `scripts/obstacle.gd`.
- Colisor: `CollisionShape2D` com `RectangleShape2D`.
- Funcao: bloqueiam o feixe de luz, exigindo que o jogador contorne o caminho.

### Cristal

- Tipo: `Area2D`.
- Script: `scripts/crystal.gd`.
- Colisor: `CollisionShape2D` com `CircleShape2D`, raio `32`.
- Quando o raio encosta nele, chama `activate_from_light()` e dispara a vitoria.

### Feixe de luz

- Tipo: `Node2D`.
- Script: `scripts/light_beam.gd`.
- Usa `PhysicsRayQueryParameters2D`.
- `collide_with_bodies = true` para espelhos.
- `collide_with_areas = true` para o cristal.
- Limite de reflexoes: `5`.

### Cenario

- O cenario e desenhado por `scripts/scene_background.gd`.
- A sala tem grade, paineis de piso, marcadores de prisma e luzes nos cantos.
- O visual continua simples, mas agora apresenta uma identidade mais clara de laboratorio de luz.

### Interface

- HUD principal: nome da fase, objetivo, rotacoes, estado e feedback.
- Painel lateral: fragmentos recuperados, estado da musica, controles e legenda dos elementos.
- Tela de conclusao: mensagem final, prisma e efeito visual de celebracao.

### Musica

- O menu usa `assets/audio/menu_loop.mp3` em loop.
- As fases usam `assets/audio/gameplay_music.mp3`.
- `MusicPlayer` toca automaticamente nas cenas.
- A tecla `M` alterna entre musica ligada e desligada durante o jogo.
- O menu possui tela de opcoes com controle de volume.

## Cenas necessarias

Para este prototipo, apenas uma cena e obrigatoria. As fases sao configuradas por dados no `main.gd`:

- `scenes/main.tscn`

Em uma segunda versao, voce pode separar:

- `scenes/mirror.tscn`
- `scenes/crystal.tscn`
- `scenes/light_emitter.tscn`
- `scenes/levels/level_01.tscn`

## Scripts necessarios

- `main.gd`
- `light_beam.gd`
- `mirror.gd`
- `crystal.gd`
- `obstacle.gd`
- `scene_background.gd`
- `music_controller.gd`

## Exportar uma build executavel

1. No Godot, abra `Project > Export`.
2. Clique em `Add...`.
3. Escolha a plataforma, por exemplo `Windows Desktop` ou `Web`.
4. Se o Godot pedir templates de exportacao, clique para baixar/instalar.
5. Em Windows, defina o caminho do arquivo `.exe`.
6. Em Web, defina uma pasta de exportacao e gere os arquivos HTML/WASM.
7. Clique em `Export Project`.

## Texto para o documento do prototipo

Este prototipo demonstra o core game loop de PRISMA em uma sala unica. O jogador observa a posicao do emissor, dos espelhos e do cristal receptor; seleciona espelhos com o mouse; usa as teclas Q/E para alterar seus angulos; observa imediatamente o novo caminho do raio de luz; e conclui a sala ao refletir o feixe ate o cristal. O HUD apresenta objetivo, quantidade de rotacoes e estado da fase, enquanto a ativacao do cristal fornece feedback textual de sucesso. A tecla R permite reiniciar a sala e repetir o ciclo.

A versao atual tambem demonstra progressao simples de dificuldade em tres fases. A primeira ensina reflexao basica com dois espelhos; a segunda introduz obstaculos que bloqueiam a luz; e a terceira combina mais espelhos com um espelho fixo, incentivando planejamento espacial e simetria sem transformar a experiencia em exercicio formal.

## Melhorias opcionais para uma segunda versao

- Obstaculos que bloqueiam a luz.
- Segundo nivel com outro arranjo geometrico.
- Espelhos fixos e espelhos moveis.
- Limite de movimentos para incentivar planejamento.
- Galeria de fragmentos recuperados.
- Personagem Echo oferecendo dicas curtas e contextuais.
- Animacao ou som quando o cristal ativa.
