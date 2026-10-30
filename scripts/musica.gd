extends RefCounted

# A luz vira musica: notas dos cristais, "canto" do espelho ao girar e melodia de vitoria.
# Funcoes puras (sem audio), cobertas por tests/run_tests.gd; o som e gerado em sfx.gd.

# Escala pentatonica de do maior (do, re, mi, sol, la), que soa bem em qualquer combinacao.
const ESCALA := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51]

# Cada cristal aceso sobe uma nota do acorde: do, mi, sol, do agudo, mi agudo.
const ACORDE := [0, 2, 3, 5, 7]

# Semitons da pentatonica em duas oitavas: um para cada uma das 12 posicoes do espelho.
const SEMITONS_DO_ESPELHO := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26]
const PITCH_BASE := 0.5


static func nota_do_cristal(ordem: int) -> float:
	return ESCALA[ACORDE[clampi(ordem, 0, ACORDE.size() - 1)]]


# O espelho "canta": cada posicao (passos de 15 graus) tem um tom diferente.
static func pitch_do_angulo(graus: float) -> float:
	var passo := int(round(fposmod(graus, 180.0) / 15.0)) % SEMITONS_DO_ESPELHO.size()
	return PITCH_BASE * pow(2.0, SEMITONS_DO_ESPELHO[passo] / 12.0)


# Melodia curta de vitoria, diferente para cada fase: 4 notas subindo e um acorde final.
# Retorna uma lista de [frequencia, inicio, duracao], no formato do sintetizador.
static func melodia_da_fase(indice: int) -> Array:
	var notas: Array = []
	var salto := 1 + indice % 3
	for k in range(4):
		var nota: int = (indice + k * salto) % 6
		notas.append([ESCALA[nota], k * 0.12, 0.45])
	var raiz := indice % 3
	for grau in [raiz, raiz + 2, raiz + 4]:
		notas.append([ESCALA[mini(grau, ESCALA.size() - 1)], 0.5, 1.1])
	return notas


# Clicar na sala vazia toca uma nota: da esquerda (grave) para a direita (aguda).
static func nota_da_posicao(x: float, inicio: float, largura: float) -> float:
	var t := clampf((x - inicio) / maxf(largura, 1.0), 0.0, 1.0)
	return ESCALA[mini(int(t * ESCALA.size()), ESCALA.size() - 1)]
