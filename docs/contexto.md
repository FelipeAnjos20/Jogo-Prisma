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

A versao atual (3.0.0) tem **10 fases** com dificuldade crescente. Cada fase apresenta
um conceito novo e a seguinte o combina com os anteriores:

1. **Primeiro reflexo** — um espelho a 45 graus (com tutorial visual).
2. **Dois espelhos** — encadear reflexoes.
3. **Desvio** — bloqueios absorvem a luz.
4. **Espelho fixo** — usar um espelho que nao gira.
5. **Divisor de luz** — um raio vira dois; dois cristais.
6. **Filtro vermelho** — cristal que exige cor.
7. **Duas cores** — filtro bloqueia luz de outra cor.
8. **Tres cristais** — dividir, colorir e dividir de novo.
9. **Dispersao** — o prisma separa a luz branca em vermelho, verde e azul.
10. **O Prisma** — desafio final combinando prisma, divisor e filtro.

Alem das fases, o jogo tem estrelas por meta de rotacoes, fragmentos do Prisma de
Luz como progressao narrativa, assistente Echo com dicas em dois niveis, salvamento
automatico, selecao de fases, suporte a teclado, mouse e controle, e acessibilidade
para daltonismo (cada cor tambem tem uma forma).

As fases sao descritas como dados em `scripts/levels.gd` (ver
[ADR 001](adr/001-fases-como-dados-em-script.md)) e validadas automaticamente pelos
testes (ver [ADR 005](adr/005-calculo-do-feixe-puro-e-testavel.md)).
O game design completo esta no [GDD](GDD.md).

## Publico e proposito

O projeto foi criado como um jogo serio de apoio ao ensino de geometria basica
(angulos, reflexao e simetria) para estudantes do ensino fundamental/medio,
como parte de um trabalho academico do curso. O objetivo nao e simular
otica com precisao fisica, e sim tornar tangivel e interativa a relacao entre
o angulo de um espelho e a trajetoria resultante da luz.

## Escopo tecnico

- Engine: Godot 4.6 (perfil de compatibilidade `GL Compatibility`).
- Toda a geometria do feixe e calculada em GDScript, sem usar a fisica da engine:
  as regras ficam em `scripts/geometria.gd` e `scripts/feixe.gd` (codigo puro) e
  `scripts/light_beam.gd` apenas desenha o resultado.
- As regras geometricas e as 10 fases sao testadas de forma automatizada em
  `tests/run_tests.gd`.
- Integracao continua roda os testes automatizados a cada push/PR na `main`
  (`.github/workflows/ci.yml`); a publicacao de builds ocorre ao criar uma tag
  de versao (`.github/workflows/cd.yml`).

## Documentos relacionados

- [Registros de decisao de arquitetura (ADRs)](adr/)
- [Creditos](creditos.md)
- [GDD](GDD.md)
- [README do prototipo original (PAC III)](Prototipo_PAC_III_README.md)
- [CHANGELOG](../CHANGELOG.md)
