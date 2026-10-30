extends SceneTree

## Executor de testes automatizados, sem interface grafica:
## godot --headless --script res://tests/run_tests.gd

const Geometria = preload("res://scripts/geometria.gd")
const Feixe = preload("res://scripts/feixe.gd")
const Levels = preload("res://scripts/levels.gd")
const MirrorScript = preload("res://scripts/mirror.gd")
const FilterScript = preload("res://scripts/color_filter.gd")
const CrystalScript = preload("res://scripts/crystal.gd")
const PrismScript = preload("res://scripts/prism.gd")

var _total := 0
var _falhas := 0


func _init() -> void:
	# Rotacao (regra original do prototipo, ADR 002)
	_test_gira_no_sentido_horario()
	_test_gira_no_sentido_anti_horario()
	_test_direcao_zero_mantem_angulo()
	_test_normaliza_apos_passar_de_360_graus()
	_test_normaliza_angulo_negativo()
	_test_normalizar_angulo_direto()

	# Regras geometricas do feixe
	_test_orientacao_do_espelho_ignora_meia_volta()
	_test_reflexao_em_espelho_a_45_graus()
	_test_intersecao_raio_segmento()
	_test_intersecao_raio_circulo()
	_test_estrelas_por_rotacoes()
	_test_normal_voltada_para_o_raio()
	_test_angulo_de_incidencia()
	_test_inclinacao_do_espelho()

	# Regras de luz (feixe.gd)
	_test_filtro_bloqueia_outra_cor()
	_test_prisma_divide_luz_branca()
	_test_feixe_registra_reflexao()

	# Todas as fases: solucao existe, nao comecam resolvidas e a meta confere
	_test_fases()

	if _falhas == 0:
		print("OK: %d/%d testes passaram" % [_total, _total])
		quit(0)
	else:
		print("FALHA: %d de %d testes falharam" % [_falhas, _total])
		quit(1)


func _assert_eq(descricao: String, obtido, esperado) -> void:
	_total += 1

	if obtido == esperado:
		print("OK - %s" % descricao)
	else:
		_falhas += 1
		print("FALHOU - %s (esperado %s, obtido %s)" % [descricao, esperado, obtido])


func _assert_proximo(descricao: String, obtido: float, esperado: float, tolerancia := 0.01) -> void:
	_assert_eq(descricao, absf(obtido - esperado) <= tolerancia, true)


# ---------------------------------------------------------------- rotacao

func _test_gira_no_sentido_horario() -> void:
	var resultado = Geometria.proximo_angulo(30.0, 1, 15.0)
	_assert_eq("gira 15 graus no sentido horario", resultado, 45.0)


func _test_gira_no_sentido_anti_horario() -> void:
	var resultado = Geometria.proximo_angulo(30.0, -1, 15.0)
	_assert_eq("gira 15 graus no sentido anti-horario", resultado, 15.0)


func _test_direcao_zero_mantem_angulo() -> void:
	var resultado = Geometria.proximo_angulo(45.0, 0, 15.0)
	_assert_eq("direcao zero mantem o angulo", resultado, 45.0)


func _test_normaliza_apos_passar_de_360_graus() -> void:
	var resultado = Geometria.proximo_angulo(350.0, 1, 15.0)
	_assert_eq("normaliza apos ultrapassar 360 graus", resultado, 5.0)


func _test_normaliza_angulo_negativo() -> void:
	var resultado = Geometria.proximo_angulo(0.0, -1, 15.0)
	_assert_eq("normaliza angulo negativo para positivo", resultado, 345.0)


func _test_normalizar_angulo_direto() -> void:
	var resultado = Geometria.normalizar_angulo(720.0 + 10.0)
	_assert_eq("normalizar_angulo reduz multiplas voltas", resultado, 10.0)


# ---------------------------------------------------------------- geometria do feixe

func _test_orientacao_do_espelho_ignora_meia_volta() -> void:
	_assert_eq("espelho a 10 e a 190 graus tem a mesma orientacao", Geometria.mesma_orientacao_espelho(10.0, 190.0), true)
	_assert_eq("espelho a -45 e a 135 graus tem a mesma orientacao", Geometria.mesma_orientacao_espelho(-45.0, 135.0), true)
	_assert_eq("espelho a 10 e a 100 graus tem orientacoes diferentes", Geometria.mesma_orientacao_espelho(10.0, 100.0), false)


func _test_reflexao_em_espelho_a_45_graus() -> void:
	# Raio indo para a direita em um espelho a 45 graus (y para baixo) desce.
	var superficie := Vector2.RIGHT.rotated(deg_to_rad(45.0))
	var refletida := Geometria.refletir(Vector2.RIGHT, superficie)
	_assert_proximo("reflexao a 45 graus: x vira 0", refletida.x, 0.0)
	_assert_proximo("reflexao a 45 graus: y vira 1 (desce)", refletida.y, 1.0)


func _test_intersecao_raio_segmento() -> void:
	var distancia := Geometria.intersecao_raio_segmento(Vector2.ZERO, Vector2.RIGHT, Vector2(100, -10), Vector2(100, 10))
	_assert_proximo("raio atinge segmento a 100 px", distancia, 100.0)
	var erro := Geometria.intersecao_raio_segmento(Vector2.ZERO, Vector2.RIGHT, Vector2(100, 20), Vector2(100, 40))
	_assert_eq("raio que passa ao lado do segmento nao atinge", erro, INF)
	var atras := Geometria.intersecao_raio_segmento(Vector2.ZERO, Vector2.RIGHT, Vector2(-100, -10), Vector2(-100, 10))
	_assert_eq("segmento atras da origem nao conta", atras, INF)


func _test_intersecao_raio_circulo() -> void:
	var distancia := Geometria.intersecao_raio_circulo(Vector2.ZERO, Vector2.RIGHT, Vector2(200, 0), 28.0)
	_assert_proximo("raio atinge a borda do circulo", distancia, 172.0)
	var erro := Geometria.intersecao_raio_circulo(Vector2.ZERO, Vector2.RIGHT, Vector2(200, 50), 28.0)
	_assert_eq("raio que passa longe do circulo nao atinge", erro, INF)


func _test_estrelas_por_rotacoes() -> void:
	_assert_eq("3 estrelas ao bater a meta", Geometria.estrelas_por_rotacoes(5, 5), 3)
	_assert_eq("2 estrelas ate o dobro da meta", Geometria.estrelas_por_rotacoes(10, 5), 2)
	_assert_eq("1 estrela acima do dobro da meta", Geometria.estrelas_por_rotacoes(11, 5), 1)


func _test_normal_voltada_para_o_raio() -> void:
	# Superficie vertical, raio vindo da esquerda: a normal aponta de volta para a esquerda.
	var normal := Geometria.normal_voltada_para_o_raio(Vector2.RIGHT, Vector2.DOWN)
	_assert_proximo("normal aponta para o lado de onde o raio chega (x)", normal.x, -1.0)
	_assert_proximo("normal aponta para o lado de onde o raio chega (y)", normal.y, 0.0)


func _test_angulo_de_incidencia() -> void:
	var superficie_45 := Vector2.RIGHT.rotated(deg_to_rad(45.0))
	_assert_proximo("raio horizontal em espelho a 45 graus incide a 45 graus", Geometria.angulo_incidencia(Vector2.RIGHT, superficie_45), 45.0)
	var superficie_vertical := Vector2.DOWN
	_assert_proximo("raio perpendicular ao espelho incide a 0 grau", Geometria.angulo_incidencia(Vector2.RIGHT, superficie_vertical), 0.0)
	var superficie_30 := Vector2.RIGHT.rotated(deg_to_rad(30.0))
	_assert_proximo("raio horizontal em espelho a 30 graus incide a 60 graus", Geometria.angulo_incidencia(Vector2.RIGHT, superficie_30), 60.0)


func _test_inclinacao_do_espelho() -> void:
	# No Godot o eixo y aponta para baixo; na matematica o angulo cresce no sentido anti-horario.
	_assert_proximo("rotacao 0 = inclinacao 0", Geometria.inclinacao_espelho(0.0), 0.0)
	_assert_proximo("rotacao -45 (sobe para a direita) = inclinacao 45", Geometria.inclinacao_espelho(-45.0), 45.0)
	_assert_proximo("rotacao 45 (desce para a direita) = inclinacao 135", Geometria.inclinacao_espelho(45.0), 135.0)
	_assert_proximo("rotacao 270 = inclinacao 90", Geometria.inclinacao_espelho(270.0), 90.0)


# ---------------------------------------------------------------- regras de luz

func _test_filtro_bloqueia_outra_cor() -> void:
	# Branco -> filtro vermelho -> filtro azul: a luz vermelha deve parar no filtro azul.
	var filtro_vermelho := Feixe.segmento(Vector2(300, 400), 90.0, 50.0)
	var filtro_azul := Feixe.segmento(Vector2(600, 400), 90.0, 50.0)
	var superficies := [
		{"a": filtro_vermelho[0], "b": filtro_vermelho[1], "tipo": "filter", "cor": "red", "dono": 0},
		{"a": filtro_azul[0], "b": filtro_azul[1], "tipo": "filter", "cor": "blue", "dono": 1},
	]
	var cristais := [{"centro": Vector2(900, 400), "raio": 28.0, "cor": "any"}]
	var resultado := Feixe.tracar(Vector2(100, 400), Vector2.RIGHT, superficies, cristais, [])
	_assert_eq("luz vermelha nao atravessa filtro azul", resultado["lit"][0], false)


func _test_prisma_divide_luz_branca() -> void:
	# O verde segue reto a partir do prisma e deve acender um cristal verde em frente.
	var cristais := [{"centro": Vector2(900, 400), "raio": 28.0, "cor": "green"}]
	var prismas := [{"centro": Vector2(400, 400), "raio": 30.0}]
	var resultado := Feixe.tracar(Vector2(100, 400), Vector2.RIGHT, [], cristais, prismas)
	_assert_eq("prisma gera o raio verde reto", resultado["lit"][0], true)
	_assert_eq("prisma fica energizado", resultado["energized"], [0])


func _test_feixe_registra_reflexao() -> void:
	# Fase 1 resolvida: o raio horizontal bate no espelho a 45 graus e desce.
	var seg := Feixe.segmento(Vector2(640, 300), 45.0, 60.0)
	var superficies := [{"a": seg[0], "b": seg[1], "tipo": "mirror", "dono": 0}]
	var cristais := [{"centro": Vector2(640, 580), "raio": 28.0, "cor": "any"}]
	var resultado := Feixe.tracar(Vector2(160, 300), Vector2.RIGHT, superficies, cristais, [])
	var reflexoes: Array = resultado["reflections"]
	_assert_eq("feixe registra uma reflexao", reflexoes.size(), 1)
	_assert_proximo("lei da reflexao: angulo de incidencia de 45 graus", reflexoes[0]["angle"], 45.0)
	var saida: Vector2 = reflexoes[0]["outgoing"]
	var normal: Vector2 = reflexoes[0]["normal"]
	var angulo_saida := rad_to_deg(acos(clampf(saida.dot(normal), -1.0, 1.0)))
	_assert_proximo("lei da reflexao: angulo de reflexao igual ao de incidencia", angulo_saida, reflexoes[0]["angle"])
	_assert_eq("reflexao aponta para o espelho certo", reflexoes[0]["owner"], 0)


# ---------------------------------------------------------------- fases

func _test_fases() -> void:
	var fases := Levels.get_levels()
	_assert_eq("o jogo tem 10 fases", fases.size(), 10)

	for indice in range(fases.size()):
		var fase: Dictionary = fases[indice]
		var nome := "fase %d (%s)" % [indice + 1, fase["name"]]
		var espelhos: Array = fase["mirrors"]
		var solucao: Array = fase["solution"]

		_assert_eq("%s: solucao tem um angulo por espelho" % nome, solucao.size(), espelhos.size())

		var iniciais: Array = []
		var custo := 0
		for k in range(espelhos.size()):
			var inicial := float(espelhos[k]["rotation"])
			iniciais.append(inicial)
			if espelhos[k]["can_rotate"]:
				var passos := int(round(fposmod(float(solucao[k]) - inicial, 180.0) / MirrorScript.STEP_DEGREES)) % 12
				custo += mini(passos, 12 - passos)
			else:
				_assert_eq("%s: espelho travado %d nao muda na solucao" % [nome, k + 1], Geometria.mesma_orientacao_espelho(float(solucao[k]), inicial), true)

		_assert_eq("%s: meta de estrelas confere com a solucao" % nome, custo, int(fase["par"]))
		_assert_eq("%s: nao comeca resolvida" % nome, _todos_acesos(fase, iniciais), false)
		_assert_eq("%s: a solucao acende todos os cristais" % nome, _todos_acesos(fase, solucao), true)


func _todos_acesos(fase: Dictionary, angulos: Array) -> bool:
	var superficies: Array = []
	var dono := 0
	for k in range(fase["mirrors"].size()):
		var espelho: Dictionary = fase["mirrors"][k]
		var comprimento: float = MirrorScript.SPLITTER_LENGTH if espelho["kind"] == "splitter" else MirrorScript.MIRROR_LENGTH
		var seg := Feixe.segmento(espelho["position"], float(angulos[k]), comprimento * 0.5)
		superficies.append({"a": seg[0], "b": seg[1], "tipo": espelho["kind"], "dono": dono})
		dono += 1
	for filtro in fase["filters"]:
		var seg := Feixe.segmento(filtro["position"], float(filtro["rotation"]), FilterScript.LENGTH * 0.5)
		superficies.append({"a": seg[0], "b": seg[1], "tipo": "filter", "cor": filtro["color"], "dono": dono})
		dono += 1
	for bloco in fase["obstacles"]:
		for aresta in Feixe.arestas_retangulo(bloco["position"], bloco["size"]):
			superficies.append({"a": aresta[0], "b": aresta[1], "tipo": "obstacle", "dono": dono})
		dono += 1

	var cristais: Array = []
	for cristal in fase["crystals"]:
		cristais.append({"centro": cristal["position"], "raio": CrystalScript.RADIUS, "cor": cristal["color"]})
	var prismas: Array = []
	for prisma in fase.get("prisms", []):
		prismas.append({"centro": prisma["position"], "raio": PrismScript.RADIUS})

	var emissor: Dictionary = fase["emitter"]
	var direcao := Vector2.RIGHT.rotated(deg_to_rad(float(emissor["rotation"])))
	var resultado := Feixe.tracar(emissor["position"], direcao, superficies, cristais, prismas)
	for aceso in resultado["lit"]:
		if not aceso:
			return false
	return true
