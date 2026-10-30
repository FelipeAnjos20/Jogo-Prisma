# Creditos

## Equipe

Projeto de Aprendizagem Colaborativa Extensionista III — Engenharia de Software,
Centro Universitario Catolica de Santa Catarina (Joinville, 2026).
Professor: Diego Sauter Possamai.

| Integrante | Principal frente |
| --- | --- |
| Vinicius Mesquita | Mecanicas centrais: espelhos, selecao e rotacao, calculo do feixe de luz |
| Felipe dos Anjos | Parte visual e interface: HUD, menus, feedbacks e identidade visual; integracao no Godot e repositorio |
| Eduardo Macedo | Level design: posicionamento dos elementos e progressao de dificuldade das fases |
| Felipe Schwabe | Testes, documentacao e organizacao; planejamento dos efeitos sonoros e do NPC Echo |

## Motor e ferramentas

- [Godot Engine](https://godotengine.org/) 4.6 (licenca MIT).
- GitHub Actions para integracao continua e publicacao de releases.
- Node.js para o simulador de fases (`tools/level_simulator`).
- Assistente de IA (Claude, da Anthropic) como apoio na programacao, revisao de
  codigo, testes automatizados e documentacao, sob orientacao e revisao da equipe.

## Arte

- Todos os elementos visuais (espelhos, divisores, filtros, prismas, cristais,
  bloqueios, emissor, feixe de luz, cenario, menus e icones de interface) sao
  desenhados via codigo (`_draw()` em GDScript), sem imagens externas.
- O icone do projeto (`icon.svg`) e um prisma vetorial feito para o projeto.

## Audio

- Efeitos sonoros: 11 efeitos sintetizados por codigo em `scripts/sfx.gd`, sem
  arquivos externos.
- Musicas: `assets/audio/menu_loop.mp3` (menu), `assets/audio/gameplay_music.mp3`
  (fases) e `assets/audio/prisma_ambient.wav` (ambiente do prototipo original,
  nao usado na versao atual).

> Nota: se as trilhas vierem de um banco de musica de terceiros (ex.: biblioteca
> royalty-free) ou tiverem sido compostas especificamente para o projeto, atualize
> esta secao com a fonte, o autor e a licenca de uso de cada uma antes da
> publicacao final.

## Agradecimentos

- Colegas e professores do curso que revisaram o prototipo durante o
  desenvolvimento.
