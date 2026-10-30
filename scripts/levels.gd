extends RefCounted

# Gerado a partir de levels.json e verificado pelo simulador do feixe.
# Cada fase tem solucao; "par" e o menor numero de rotacoes possivel.


static func get_levels() -> Array:
	return [
		{
			"name": "Primeiro reflexo",
			"objective": "Gire o espelho para levar a luz até o cristal.",
			"hint": "Um espelho a 45° transforma um raio horizontal em vertical.",
			"par": 3,
			"emitter": {"position": Vector2(160, 300), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(640, 580), "color": "any"},
			],
			"mirrors": [
				{"kind": "mirror", "position": Vector2(640, 300), "rotation": 0.0, "can_rotate": true},
			],
			"filters": [
			],
			"obstacles": [
			],
			"prisms": [
			],
			"solution": [45.0],
		},
		{
			"name": "Dois espelhos",
			"objective": "Combine os 2 espelhos para desviar a luz duas vezes.",
			"hint": "Faça a luz descer no primeiro espelho e virar para a direita no segundo.",
			"par": 5,
			"emitter": {"position": Vector2(160, 340), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(960, 590), "color": "any"},
			],
			"mirrors": [
				{"kind": "mirror", "position": Vector2(460, 340), "rotation": 15.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(460, 590), "rotation": 0.0, "can_rotate": true},
			],
			"filters": [
			],
			"obstacles": [
			],
			"prisms": [
			],
			"solution": [45.0, 45.0],
		},
		{
			"name": "Desvio",
			"objective": "O bloco vermelho absorve a luz. Contorne-o com 3 espelhos.",
			"hint": "Desça a luz, atravesse por baixo do bloco e suba até o cristal.",
			"par": 3,
			"emitter": {"position": Vector2(160, 260), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(900, 260), "color": "any"},
			],
			"mirrors": [
				{"kind": "mirror", "position": Vector2(400, 260), "rotation": 30.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(400, 580), "rotation": 60.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(900, 580), "rotation": -30.0, "can_rotate": true},
			],
			"filters": [
			],
			"obstacles": [
				{"position": Vector2(640, 300), "size": Vector2(95, 310)},
			],
			"prisms": [
			],
			"solution": [45.0, 45.0, -45.0],
		},
		{
			"name": "Espelho fixo",
			"objective": "Monte uma escada de luz passando pelo espelho travado.",
			"hint": "O espelho com cadeado não gira. Leve a luz até ele pelo alto.",
			"par": 3,
			"emitter": {"position": Vector2(140, 610), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(1080, 540), "color": "any"},
			],
			"mirrors": [
				{"kind": "mirror", "position": Vector2(340, 610), "rotation": -30.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(340, 320), "rotation": -60.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(780, 320), "rotation": 45.0, "can_rotate": false},
				{"kind": "mirror", "position": Vector2(780, 540), "rotation": 30.0, "can_rotate": true},
			],
			"filters": [
			],
			"obstacles": [
				{"position": Vector2(560, 610), "size": Vector2(95, 150)},
				{"position": Vector2(560, 450), "size": Vector2(120, 80)},
			],
			"prisms": [
			],
			"solution": [-45.0, -45.0, 45.0, 45.0],
		},
		{
			"name": "Divisor de luz",
			"objective": "O vidro divisor parte o raio em dois. Acenda os 2 cristais.",
			"hint": "Um raio segue reto pelo divisor e o outro desce. Cada espelho cuida de um.",
			"par": 6,
			"emitter": {"position": Vector2(160, 380), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(860, 180), "color": "any"},
				{"position": Vector2(1060, 620), "color": "any"},
			],
			"mirrors": [
				{"kind": "splitter", "position": Vector2(480, 380), "rotation": 45.0, "can_rotate": false},
				{"kind": "mirror", "position": Vector2(860, 380), "rotation": 0.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(480, 620), "rotation": 0.0, "can_rotate": true},
			],
			"filters": [
			],
			"obstacles": [
			],
			"prisms": [
			],
			"solution": [45.0, -45.0, 45.0],
		},
		{
			"name": "Filtro vermelho",
			"objective": "Este cristal só aceita luz vermelha. Passe pelo filtro.",
			"hint": "A luz branca direta não acende o cristal vermelho. Suba, passe pelo filtro e desça.",
			"par": 7,
			"emitter": {"position": Vector2(160, 560), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(1000, 560), "color": "red"},
			],
			"mirrors": [
				{"kind": "mirror", "position": Vector2(480, 560), "rotation": 0.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(480, 260), "rotation": -15.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(1000, 260), "rotation": 15.0, "can_rotate": true},
			],
			"filters": [
				{"position": Vector2(740, 260), "rotation": 90.0, "color": "red"},
			],
			"obstacles": [
			],
			"prisms": [
			],
			"solution": [-45.0, -45.0, 45.0],
		},
		{
			"name": "Duas cores",
			"objective": "Divida a luz e pinte cada metade com a cor do seu cristal.",
			"hint": "Luz vermelha não atravessa filtro azul. Acerte o ângulo do divisor primeiro.",
			"par": 8,
			"emitter": {"position": Vector2(140, 400), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(900, 180), "color": "blue"},
				{"position": Vector2(1080, 620), "color": "red"},
			],
			"mirrors": [
				{"kind": "splitter", "position": Vector2(400, 400), "rotation": 30.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(900, 400), "rotation": 0.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(400, 620), "rotation": -15.0, "can_rotate": true},
			],
			"filters": [
				{"position": Vector2(650, 400), "rotation": 90.0, "color": "blue"},
				{"position": Vector2(700, 620), "rotation": 90.0, "color": "red"},
			],
			"obstacles": [
				{"position": Vector2(650, 220), "size": Vector2(90, 120)},
			],
			"prisms": [
			],
			"solution": [45.0, -45.0, 45.0],
		},
		{
			"name": "Três cristais",
			"objective": "Divida, pinte e divida de novo: acenda os 3 cristais ao mesmo tempo.",
			"hint": "Resolva um ramo de cada vez: o de cima fica verde, o de baixo fica vermelho e se divide.",
			"par": 11,
			"emitter": {"position": Vector2(140, 220), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(1080, 470), "color": "green"},
				{"position": Vector2(1080, 620), "color": "red"},
				{"position": Vector2(920, 300), "color": "any"},
			],
			"mirrors": [
				{"kind": "splitter", "position": Vector2(380, 220), "rotation": 45.0, "can_rotate": false},
				{"kind": "mirror", "position": Vector2(760, 220), "rotation": 0.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(760, 470), "rotation": 15.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(380, 620), "rotation": 0.0, "can_rotate": true},
				{"kind": "splitter", "position": Vector2(920, 620), "rotation": 0.0, "can_rotate": true},
			],
			"filters": [
				{"position": Vector2(560, 220), "rotation": 90.0, "color": "green"},
				{"position": Vector2(600, 620), "rotation": 90.0, "color": "red"},
			],
			"obstacles": [
				{"position": Vector2(1000, 220), "size": Vector2(90, 150)},
			],
			"prisms": [
			],
			"solution": [45.0, 45.0, 45.0, 45.0, -45.0],
		},
		{
			"name": "Dispersão",
			"objective": "O prisma separa a luz branca em três cores. Leve cada cor ao seu cristal.",
			"hint": "O vermelho sai para cima, o verde segue reto e o azul desce. Cada espelho cuida de uma cor.",
			"par": 7,
			"emitter": {"position": Vector2(140, 380), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(1100, 230), "color": "red"},
				{"position": Vector2(860, 160), "color": "green"},
				{"position": Vector2(1100, 530), "color": "blue"},
			],
			"mirrors": [
				{"kind": "mirror", "position": Vector2(680, 230), "rotation": -45.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(860, 380), "rotation": 0.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(680, 530), "rotation": 45.0, "can_rotate": true},
			],
			"filters": [
			],
			"obstacles": [
			],
			"prisms": [
				{"position": Vector2(420, 380)},
			],
			"solution": [-15.0, -45.0, 15.0],
		},
		{
			"name": "O Prisma",
			"objective": "O verde do prisma está bloqueado. Use o divisor e o filtro para acender as 3 cores.",
			"hint": "Primeiro acerte o divisor para mandar parte da luz para baixo. Depois o prisma cuida do vermelho e do azul.",
			"par": 10,
			"emitter": {"position": Vector2(140, 380), "rotation": 0.0},
			"crystals": [
				{"position": Vector2(1100, 240), "color": "red"},
				{"position": Vector2(1100, 520), "color": "blue"},
				{"position": Vector2(1100, 620), "color": "green"},
			],
			"mirrors": [
				{"kind": "splitter", "position": Vector2(340, 380), "rotation": 30.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(800, 240), "rotation": 30.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(800, 520), "rotation": -30.0, "can_rotate": true},
				{"kind": "mirror", "position": Vector2(340, 620), "rotation": 0.0, "can_rotate": true},
			],
			"filters": [
				{"position": Vector2(560, 620), "rotation": 90.0, "color": "green"},
			],
			"obstacles": [
				{"position": Vector2(760, 380), "size": Vector2(60, 130)},
			],
			"prisms": [
				{"position": Vector2(560, 380)},
			],
			"solution": [45.0, -15.0, 15.0, 45.0],
		},
	]
