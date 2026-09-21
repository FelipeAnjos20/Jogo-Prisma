# Contexto do projeto

PRISMA e um jogo serio de puzzle geometrico, desenvolvido em Godot 4, que ensina
conceitos de angulo, reflexao e simetria atraves de um mecanismo central de
espelhos giratorios e um feixe de luz.

## Ideia central

O jogador observa um emissor de luz, um conjunto de espelhos e um cristal
receptor dentro de uma sala. Ao selecionar e girar os espelhos em passos fixos
de 15 graus, o jogador altera o caminho do feixe ate conseguir acerta-lo no
cristal, recebendo feedback imediato (visual e textual) quando o objetivo e
cumprido.

Esse ciclo curto — observar, selecionar, girar, observar o novo caminho,
acertar o alvo — e o core loop do jogo, e permanece o mesmo em todas as fases.

## Estado atual do projeto

O prototipo atual contem tres fases jogaveis, com dificuldade crescente:

1. **Fase 1 - Reflexao basica**: apresenta o mecanismo de espelhos com o
   arranjo mais simples possivel, usando dois espelhos moveis.
2. **Fase 2 - Desvio com obstaculo**: introduz obstaculos que bloqueiam o
   feixe, exigindo que o jogador planeje um caminho mais indireto com tres
   espelhos.
3. **Fase 3 - Espelho fixo e simetria**: combina quatro espelhos, um deles
   fixo (nao giravel), incentivando o jogador a raciocinar sobre simetria e
   angulos complementares.

As fases sao descritas como dados dentro de `scripts/main.gd` (ver
[ADR 001](adr/001-fases-como-dados-em-script.md)), o que permite ajustar ou
adicionar fases sem criar novas cenas.

## Publico e proposito

O projeto foi criado como um jogo serio de apoio ao ensino de geometria basica
(angulos, reflexao e simetria) para estudantes do ensino fundamental/medio,
como parte de um trabalho academico do curso. O objetivo nao e simular
otica com precisao fisica, e sim tornar tangivel e interativa a relacao entre
o angulo de um espelho e a trajetoria resultante da luz.

## Escopo tecnico

- Engine: Godot 4.6 (perfil de compatibilidade `GL Compatibility`).
- Toda a geometria de colisao/desenho dos espelhos, obstaculos e do feixe e
  calculada em GDScript (`scripts/light_beam.gd`, `scripts/mirror.gd`,
  `scripts/obstacle.gd`, `scripts/crystal.gd`), sem depender de fisica de
  particulas de luz da engine.
- A logica de rotacao de angulo foi isolada em `scripts/geometria.gd` para
  poder ser testada de forma automatizada (ver `tests/run_tests.gd`).
- Integracao continua roda os testes automatizados a cada push/PR na `main`
  (`.github/workflows/ci.yml`); a publicacao de builds ocorre ao criar uma tag
  de versao (`.github/workflows/cd.yml`).

## Documentos relacionados

- [Registros de decisao de arquitetura (ADRs)](adr/)
- [Creditos](creditos.md)
- [README do prototipo original](../README_PROTOTIPO.md)
- [CHANGELOG](../CHANGELOG.md)
