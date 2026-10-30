class_name Geometria
extends RefCounted

## Regras geometricas puras usadas pelos objetos jogaveis (sem dependencia de nodes da cena),
## para poderem ser testadas isoladamente em tests/run_tests.gd.

const ANGULO_COMPLETO := 360.0
const MEIA_VOLTA := 180.0


## Calcula o proximo angulo (em graus) apos um passo de rotacao em uma direcao.
## direcao: -1 (anti-horario), 1 (horario) ou 0 (nenhuma mudanca).
## O resultado e normalizado para o intervalo [0, 360).
static func proximo_angulo(angulo_atual_graus: float, direcao: int, passo_graus: float) -> float:
	return normalizar_angulo(angulo_atual_graus + passo_graus * float(direcao))


## Normaliza um angulo em graus para o intervalo [0, 360).
static func normalizar_angulo(angulo_graus: float) -> float:
	return fposmod(angulo_graus, ANGULO_COMPLETO)


## Um espelho reflete pelos dois lados, entao 0 e 180 graus sao a mesma orientacao.
static func mesma_orientacao_espelho(angulo_a_graus: float, angulo_b_graus: float) -> bool:
	var diferenca := fposmod(angulo_a_graus - angulo_b_graus, MEIA_VOLTA)
	return diferenca < 0.5 or diferenca > MEIA_VOLTA - 0.5


## Reflete uma direcao em uma superficie definida pelo vetor do segmento (de A para B).
## Angulo de incidencia = angulo de reflexao.
static func refletir(direcao: Vector2, vetor_superficie: Vector2) -> Vector2:
	var normal := Vector2(-vetor_superficie.y, vetor_superficie.x).normalized()
	return direcao - normal * 2.0 * direcao.dot(normal)


## Distancia ao longo do raio ate o segmento [inicio, fim], ou INF se nao houver intersecao.
static func intersecao_raio_segmento(origem: Vector2, direcao: Vector2, inicio: Vector2, fim: Vector2, distancia_minima := 0.5) -> float:
	var segmento := fim - inicio
	var divisor := direcao.cross(segmento)
	if absf(divisor) < 0.0001:
		return INF

	var ate_inicio := inicio - origem
	var distancia := ate_inicio.cross(segmento) / divisor
	var posicao_no_segmento := ate_inicio.cross(direcao) / divisor

	if distancia <= distancia_minima or posicao_no_segmento < 0.0 or posicao_no_segmento > 1.0:
		return INF
	return distancia


## Distancia ao longo do raio ate o circulo (centro, raio), ou INF se nao houver intersecao.
static func intersecao_raio_circulo(origem: Vector2, direcao: Vector2, centro: Vector2, raio: float, distancia_minima := 0.5) -> float:
	var deslocamento := origem - centro
	var b := 2.0 * deslocamento.dot(direcao)
	var c := deslocamento.dot(deslocamento) - raio * raio
	var discriminante := b * b - 4.0 * c
	if discriminante < 0.0:
		return INF

	var raiz := sqrt(discriminante)
	var primeira := (-b - raiz) * 0.5
	var segunda := (-b + raiz) * 0.5
	var distancia := primeira if primeira > distancia_minima else segunda
	return distancia if distancia > distancia_minima else INF


## Estrelas de uma fase: 3 ao bater a meta de rotacoes, 2 ate o dobro, 1 ao concluir.
static func estrelas_por_rotacoes(rotacoes: int, meta: int) -> int:
	if rotacoes <= meta:
		return 3
	if rotacoes <= meta * 2:
		return 2
	return 1
