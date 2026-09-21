# 001 - Fases como dados em script

## Status

Aceito.

## Contexto

O jogo precisa de multiplas fases (salas de puzzle), cada uma com uma posicao
diferente para o emissor, o cristal, os espelhos (ativos ou nao, giraveis ou
fixos) e os obstaculos. A abordagem mais comum em Godot seria criar uma cena
`.tscn` separada por fase, reaproveitando os mesmos nodes de espelho, cristal
e obstaculo.

Durante o prototipo, o numero de fases e pequeno (tres) e ainda esta mudando
com frequencia enquanto o design de cada sala e ajustado.

## Decisao

Representar cada fase como um dicionario de dados dentro do array `levels`
em `scripts/main.gd`, contendo posicao/rotacao do emissor e do cristal, e a
configuracao (posicao, rotacao, `can_rotate`, `active`) de cada espelho e
obstaculo. Uma unica cena (`scenes/main.tscn`) reutiliza os mesmos nodes para
todas as fases, e `_load_level()` reconfigura esses nodes a cada troca de
fase.

## Consequencias

- Adicionar ou ajustar uma fase e uma mudanca de dados em `main.gd`, sem
  precisar criar ou editar uma nova cena no editor.
- Reduz a duplicacao de nodes e scripts entre fases.
- Limita o numero de espelhos/obstaculos ao que foi pre-alocado na cena
  (atualmente 4 espelhos e 2 obstaculos); fases com mais elementos exigiriam
  aumentar esses arrays na cena e em `main.gd`.
- Torna a edicao das fases menos visual (não da para arrastar espelhos no
  editor e ver o resultado direto); e uma troca aceita para a velocidade de
  iteracao do prototipo.
- Se o numero de fases crescer significativamente, uma cena por fase (como
  cogitado em `README_PROTOTIPO.md`, em `scenes/levels/level_01.tscn`) volta a
  ser uma opcao valida a reavaliar.
