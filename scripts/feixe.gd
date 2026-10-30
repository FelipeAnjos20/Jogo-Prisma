extends RefCounted

## Calculo puro do caminho da luz, sem depender de nodes da cena.
## Usado por light_beam.gd (jogo) e por tests/run_tests.gd (validacao das fases).
##
## Regras:
## - espelho: reflete; divisor: reflete e tambem deixa passar;
## - filtro: luz branca sai com a cor do filtro, luz da mesma cor passa, outra cor e bloqueada;
## - prisma: luz branca vira tres raios (vermelho, verde, azul) em leque; luz colorida atravessa;
## - bloqueio e paredes da sala: interrompem o raio;
## - cristal: acende se a cor for aceita ("any" aceita qualquer cor).

const Geometria = preload("res://scripts/geometria.gd")

## Area jogavel da sala (as paredes bloqueiam o raio).
const SALA := Rect2(40.0, 100.0, 1200.0, 590.0)

## Limites que garantem que o calculo sempre termina (ver docs/adr/003 e 005).
const MAX_REFLEXOES := 12
const MAX_SEGMENTOS := 64
const MAX_RAIOS := 16
const DISTANCIA_MINIMA := 0.5
const AFASTAMENTO := 2.0
const ABERTURA_PRISMA_GRAUS := 30.0

const DONO_PAREDE := -1


## superficies: Array de {"a": Vector2, "b": Vector2, "tipo": "mirror"|"splitter"|"filter"|"obstacle", "cor": String, "dono": int}
## cristais: Array de {"centro": Vector2, "raio": float, "cor": String}
## prismas: Array de {"centro": Vector2, "raio": float}
## Retorna {"segments": [{a, b, color, distance}], "hits": [{position, color, strong}],
##          "lit": Array[bool] por cristal, "energized": Array[int] indices dos prismas atingidos,
##          "reflections": [{position, incoming, outgoing, normal, angle, owner, color}] (espelhos e divisores)}
static func tracar(origem: Vector2, direcao: Vector2, superficies: Array, cristais: Array, prismas: Array, sala := SALA) -> Dictionary:
	var segmentos: Array = []
	var impactos: Array = []
	var acesos: Array = []
	var prismas_ativos: Array = []
	var reflexoes: Array = []
	for _cristal in cristais:
		acesos.append(false)

	var todas := superficies.duplicate()
	var cantos := [sala.position, Vector2(sala.end.x, sala.position.y), sala.end, Vector2(sala.position.x, sala.end.y)]
	for i in range(4):
		todas.append({"a": cantos[i], "b": cantos[(i + 1) % 4], "tipo": "wall", "dono": DONO_PAREDE})

	# O "ignorar" evita que um raio que acabou de sair de uma superficie colida de novo com ela.
	# Superficies usam o proprio "dono" (>= 0); prismas usam -(indice + 2).
	var fila: Array = [{"origem": origem, "direcao": direcao.normalized(), "cor": "white", "ignorar": null, "distancia": 0.0}]
	var raios := 0

	while not fila.is_empty() and raios < MAX_RAIOS and segmentos.size() < MAX_SEGMENTOS:
		var raio: Dictionary = fila.pop_front()
		raios += 1
		var o: Vector2 = raio["origem"]
		var d: Vector2 = raio["direcao"]
		var cor: String = raio["cor"]
		var ignorar = raio["ignorar"]
		var percorrido: float = raio["distancia"]

		for _reflexao in range(MAX_REFLEXOES + 1):
			if segmentos.size() >= MAX_SEGMENTOS:
				break

			var melhor := INF
			var superficie = null
			var cristal := -1
			var prisma := -1

			for s in todas:
				if ignorar != null and s["dono"] == ignorar and s["dono"] != DONO_PAREDE:
					continue
				var t := Geometria.intersecao_raio_segmento(o, d, s["a"], s["b"], DISTANCIA_MINIMA)
				if t < melhor:
					melhor = t
					superficie = s
					cristal = -1
					prisma = -1

			for i in range(cristais.size()):
				var t := Geometria.intersecao_raio_circulo(o, d, cristais[i]["centro"], cristais[i]["raio"], DISTANCIA_MINIMA)
				if t < melhor:
					melhor = t
					superficie = null
					cristal = i
					prisma = -1

			for i in range(prismas.size()):
				if ignorar != null and ignorar == -(i + 2):
					continue
				var t := Geometria.intersecao_raio_circulo(o, d, prismas[i]["centro"], prismas[i]["raio"], DISTANCIA_MINIMA)
				if t < melhor:
					melhor = t
					superficie = null
					cristal = -1
					prisma = i

			if melhor == INF:
				break

			var ponto := o + d * melhor
			segmentos.append({"a": o, "b": ponto, "color": cor, "distance": percorrido})
			percorrido += melhor

			if cristal >= 0:
				if aceita_cor(cristais[cristal]["cor"], cor):
					acesos[cristal] = true
				impactos.append({"position": ponto, "color": cor, "strong": true})
				break

			if prisma >= 0:
				var centro: Vector2 = prismas[prisma]["centro"]
				impactos.append({"position": ponto, "color": cor, "strong": true})
				if not prismas_ativos.has(prisma):
					prismas_ativos.append(prisma)
				if cor == "white":
					var abertura := deg_to_rad(ABERTURA_PRISMA_GRAUS)
					for saida in [["red", -abertura], ["green", 0.0], ["blue", abertura]]:
						fila.append({"origem": centro, "direcao": d.rotated(saida[1]), "cor": saida[0], "ignorar": -(prisma + 2), "distancia": percorrido})
					break
				o = centro
				ignorar = -(prisma + 2)
				continue

			var tipo: String = superficie["tipo"]
			if tipo == "wall" or tipo == "obstacle":
				impactos.append({"position": ponto, "color": cor, "strong": false})
				break

			if tipo == "filter":
				var cor_filtro: String = superficie["cor"]
				if cor != "white" and cor != cor_filtro:
					impactos.append({"position": ponto, "color": cor, "strong": false})
					break
				cor = cor_filtro
				o = ponto + d * AFASTAMENTO
				ignorar = superficie["dono"]
				continue

			var vetor_superficie: Vector2 = superficie["b"] - superficie["a"]
			var refletida := Geometria.refletir(d, vetor_superficie)
			impactos.append({"position": ponto, "color": cor, "strong": true})
			reflexoes.append({
				"position": ponto,
				"incoming": d,
				"outgoing": refletida,
				"normal": Geometria.normal_voltada_para_o_raio(d, vetor_superficie),
				"angle": Geometria.angulo_incidencia(d, vetor_superficie),
				"owner": superficie["dono"],
				"color": cor,
			})
			if tipo == "splitter":
				fila.append({"origem": ponto + refletida * AFASTAMENTO, "direcao": refletida, "cor": cor, "ignorar": superficie["dono"], "distancia": percorrido})
				o = ponto + d * AFASTAMENTO
			else:
				d = refletida
				o = ponto + d * AFASTAMENTO
			ignorar = superficie["dono"]

	return {"segments": segmentos, "hits": impactos, "lit": acesos, "energized": prismas_ativos, "reflections": reflexoes}


## Cristal "any" aceita qualquer cor; os demais so a propria cor.
static func aceita_cor(cor_cristal: String, cor_luz: String) -> bool:
	return cor_cristal == "any" or cor_cristal == cor_luz


## Segmento de um elemento linear (espelho, divisor, filtro) a partir do centro, angulo e meio comprimento.
static func segmento(centro: Vector2, angulo_graus: float, meio_comprimento: float) -> Array:
	var direcao := Vector2.RIGHT.rotated(deg_to_rad(angulo_graus)) * meio_comprimento
	return [centro - direcao, centro + direcao]


## Quatro arestas de um bloco retangular centrado em "centro".
static func arestas_retangulo(centro: Vector2, tamanho: Vector2) -> Array:
	var meio := tamanho * 0.5
	var cantos := [
		centro + Vector2(-meio.x, -meio.y), centro + Vector2(meio.x, -meio.y),
		centro + Vector2(meio.x, meio.y), centro + Vector2(-meio.x, meio.y),
	]
	return [[cantos[0], cantos[1]], [cantos[1], cantos[2]], [cantos[2], cantos[3]], [cantos[3], cantos[0]]]
