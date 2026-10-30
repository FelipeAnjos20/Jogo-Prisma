# 005 - Calculo do feixe puro e testavel

## Status

Aceito (versao 3.0.0).

## Contexto

Na versao 3.0.0 o feixe de luz passou a ter regras bem mais ricas que no prototipo:
divisores (um raio vira dois), filtros de cor, prismas (um raio branco vira tres
coloridos), varios cristais por fase, cristais que exigem cor e paredes da sala.
Ao mesmo tempo, o numero de fases passou de 3 para 10.

Com essa quantidade de regras e de fases, testar cada fase manualmente a cada
alteracao deixou de ser viavel: uma mudanca pequena no calculo do feixe pode
deixar uma fase sem solucao sem que ninguem perceba. O calculo, porem, vivia
dentro de `scripts/light_beam.gd`, misturado com nodes da cena e com o desenho,
o que impedia testa-lo em `tests/run_tests.gd` (que roda sem cena).

## Decisao

Separar o calculo do desenho:

- `scripts/geometria.gd` concentra as regras geometricas basicas (passo de
  rotacao, orientacao do espelho, reflexao, intersecao raio-segmento e
  raio-circulo, regra das estrelas).
- `scripts/feixe.gd` contem `Feixe.tracar()`, uma funcao **pura** que recebe so
  dados (superficies, cristais, prismas, sala) e devolve os segmentos do feixe,
  os pontos de impacto e quais cristais estao acesos. Raios extras (divisor e
  prisma) sao tratados com uma fila de raios.
- `scripts/light_beam.gd` apenas converte os nodes da cena em dados, chama
  `Feixe.tracar()` e desenha o resultado.
- `tests/run_tests.gd` monta cada fase a partir de `scripts/levels.gd` e usa o
  **mesmo** `Feixe.tracar()` para verificar que a fase nao comeca resolvida, que
  a solucao registrada acende todos os cristais e que a meta de estrelas e o
  minimo de rotacoes.

## Consequencias

- O jogo e os testes usam exatamente o mesmo codigo de calculo, entao um teste
  verde garante que todas as fases continuam soluveis no jogo real.
- A CI (`.github/workflows/ci.yml`) passa a validar as 10 fases a cada push.
- O simulador em `tools/level_simulator/sim.js` (Node.js) continua util para
  desenhar fases e calcular a meta minima explorando todas as combinacoes de
  angulos, mas precisa manter as mesmas regras que `feixe.gd`. Os testes de
  fase detectam se os dois divergirem.
- Novas mecanicas de luz devem ser implementadas em `feixe.gd` (com teste) e
  nao diretamente em `light_beam.gd`.
