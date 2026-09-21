# 002 - Rotacao em passos de 15 graus

## Status

Aceito.

## Contexto

PRISMA e um jogo serio voltado a ensinar angulo, reflexao e simetria. O
jogador controla espelhos que refletem um feixe de luz, e a forma como esses
espelhos giram afeta diretamente a clareza do conceito geometrico ensinado.

Duas abordagens foram consideradas para a rotacao dos espelhos:

1. Rotacao livre/continua, arrastando o espelho com o mouse.
2. Rotacao discreta, em passos fixos de um numero determinado de graus, via
   teclado (`Q`/`E`).

Rotacao livre da mais liberdade ao jogador, mas dificulta desenhar fases com
solucoes exatas e prejudica a leitura didatica dos angulos (o jogador nao
tem uma nocao clara de "quantos graus" cada espelho esta girado).

## Decisao

Cada espelho gira em passos fixos de 15 graus por acionamento
(`rotate_step_degrees` em `scripts/mirror.gd`, acionado pelas teclas `Q`
sentido anti-horario e `E` sentido horario). Essa regra foi isolada em
`Geometria.proximo_angulo()` (`scripts/geometria.gd`), para poder ser testada
sem depender da cena do Godot.

15 graus foi escolhido por dividir 360 em partes inteiras (24 posicoes
possiveis) e por ser compativel com os angulos usados no desenho das fases
existentes (multiplos de 15: 30, 45, 60 graus).

## Consequencias

- As fases podem ser desenhadas com solucoes exatas e reproduzem o mesmo
  resultado a cada tentativa, o que facilita testar e balancear o puzzle.
- O jogador consegue associar cada acionamento de `Q`/`E` a uma quantidade
  fixa e conhecida de graus, reforcando o conceito ensinado.
- Reduz a expressividade de movimento (nao ha rotacao livre/analogica), o que
  e aceitavel para o publico e objetivo educacional do jogo.
- Qualquer mudanca futura no tamanho do passo deve continuar sendo feita via
  `Geometria.proximo_angulo()`, para manter a regra coberta pelos testes em
  `tests/run_tests.gd`.
