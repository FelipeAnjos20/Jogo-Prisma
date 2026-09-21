class_name Geometria
extends RefCounted

## Regras geometricas puras usadas pelos objetos jogaveis (sem dependencia de nodes da cena),
## para poderem ser testadas isoladamente em tests/run_tests.gd.

const ANGULO_COMPLETO := 360.0


## Calcula o proximo angulo (em graus) apos um passo de rotacao em uma direcao.
## direcao: -1 (anti-horario), 1 (horario) ou 0 (nenhuma mudanca).
## O resultado e normalizado para o intervalo [0, 360).
static func proximo_angulo(angulo_atual_graus: float, direcao: int, passo_graus: float) -> float:
	return normalizar_angulo(angulo_atual_graus + passo_graus * float(direcao))


## Normaliza um angulo em graus para o intervalo [0, 360).
static func normalizar_angulo(angulo_graus: float) -> float:
	return fposmod(angulo_graus, ANGULO_COMPLETO)
