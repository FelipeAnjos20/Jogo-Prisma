# 003 - Limite de reflexoes do feixe

## Status

Aceito.

## Contexto

`scripts/light_beam.gd` recalcula o caminho do feixe de luz a cada frame,
lancando um raio a partir do emissor e, a cada espelho atingido, refletindo a
direcao e lancando um novo raio a partir do ponto de impacto.

Sem um limite explicito de reflexoes, um arranjo de espelhos que se aponta
mutuamente (por exemplo, dois espelhos paralelos voltados um para o outro)
faria o calculo entrar em um laco de reflexoes sem fim dentro do mesmo frame,
travando o jogo.

## Decisao

Limitar o numero de reflexoes por frame a `max_reflections = 5`, e limitar
tambem o alcance total de cada segmento do feixe a `max_distance = 1800.0`
pixels (a viewport do jogo e `1280x720`, entao 1800 cobre uma trajetoria bem
mais longa que a diagonal da tela, sem ser ilimitada). Se o feixe nao atingir
o cristal dentro desses limites, o ultimo segmento e desenhado ate
`max_distance` e o feixe "se perde" visualmente, sinalizando ao jogador que o
caminho atual nao fecha o puzzle.

## Consequencias

- O calculo do feixe sempre termina em tempo previsivel a cada frame,
  independente do arranjo de espelhos que o jogador montar.
- Fases devem ser desenhadas de forma que a solucao pretendida exija no
  maximo 5 reflexoes; um design que dependa de mais reflexoes que isso
  precisaria primeiro aumentar `max_reflections`.
- Arranjos "degenerados" (espelhos em loop) nao travam o jogo, apenas
  resultam em um feixe que nao alcanca o cristal.
