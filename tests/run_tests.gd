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
const Musica = preload("res://scripts/musica.gd")
const Historia = preload("res://scripts/historia.gd")
const EchoBrain = preload("res://scripts/echo_brain.gd")
const Conquistas = preload("res://scripts/conquistas.gd")
const UIKit = preload("res://scripts/ui_kit.gd")

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
	# --- v3.3 visual ---
	_test_visual_temas()
	_test_visual_recorte()
	_test_visual_poeira()
	_test_visual_mouse()

	# Interatividade (v3.2): musica, historia e conversa com o Echo
	_test_notas_dos_cristais()
	_test_espelho_canta()
	_test_melodia_de_vitoria()
	_test_historia()
	_test_nome_do_jogador()
	_test_modo_deixa_comigo()
	_test_falas_do_echo()

	# Interatividade (v3.3): conquistas, visual do Echo e atalhos que aparecem aos poucos
	_test_conquistas_da_vitoria()
	_test_conquistas_novas()
	_test_recompensas_por_estrelas()
	_test_atalhos_por_fase()
	_test_nota_da_sala()
	_test_clima_das_salas()
	_test_cartoes_de_peca_nova()

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


# ---------------------------------------------------------------- interatividade

func _test_notas_dos_cristais() -> void:
	var anterior := 0.0
	var subindo := true
	for ordem in range(5):
		var nota := Musica.nota_do_cristal(ordem)
		subindo = subindo and nota > anterior and Musica.ESCALA.has(nota)
		anterior = nota
	_assert_eq("cada cristal aceso toca uma nota mais aguda da escala", subindo, true)
	_assert_eq("ordem acima do acorde repete a nota mais aguda", Musica.nota_do_cristal(9), Musica.nota_do_cristal(4))


func _test_espelho_canta() -> void:
	_assert_proximo("espelho a 0 e a 180 graus tem o mesmo tom", Musica.pitch_do_angulo(0.0), Musica.pitch_do_angulo(180.0))
	var tons := {}
	var dentro := true
	for passo in range(12):
		var tom := Musica.pitch_do_angulo(passo * 15.0)
		tons[snappedf(tom, 0.001)] = true
		dentro = dentro and tom >= 0.5 and tom <= 2.5
	_assert_eq("as 12 posicoes do espelho tem tons diferentes", tons.size(), 12)
	_assert_eq("os tons do espelho ficam numa faixa audivel", dentro, true)


func _test_melodia_de_vitoria() -> void:
	var melodia := Musica.melodia_da_fase(3)
	_assert_eq("melodia de vitoria tem 4 notas e um acorde de 3", melodia.size(), 7)
	_assert_eq("a melodia de uma fase e sempre a mesma", melodia, Musica.melodia_da_fase(3))
	_assert_eq("fases diferentes tem melodias diferentes", Musica.melodia_da_fase(0) == Musica.melodia_da_fase(1), false)
	var na_escala := true
	for indice in range(Levels.get_levels().size()):
		for nota in Musica.melodia_da_fase(indice):
			na_escala = na_escala and Musica.ESCALA.has(nota[0])
	_assert_eq("todas as melodias usam notas da escala", na_escala, true)


func _test_historia() -> void:
	_assert_eq("cada fase devolve uma memoria da historia", Historia.total(), Levels.get_levels().size())
	var completas := true
	for indice in range(Historia.total()):
		var fragmento := Historia.fragmento(indice)
		completas = completas and str(fragmento.get("titulo", "")) != "" and str(fragmento.get("texto", "")) != ""
	_assert_eq("toda memoria tem titulo e texto", completas, true)
	_assert_eq("indice fora da historia devolve vazio", Historia.fragmento(99), {})
	_assert_eq("caminho da ilustracao opcional", Historia.caminho_imagem(0), "res://assets/story/fragmento_01.png")


func _test_nome_do_jogador() -> void:
	_assert_eq("Echo chama o jogador pelo nome", EchoBrain.personalizar("Oi, {nome}!", "Ana"), "Oi, Ana!")
	_assert_eq("sem nome, a frase fica correta", EchoBrain.personalizar("Oi, {nome}!", ""), "Oi!")
	_assert_eq("sem nome, o final da historia fica correto", EchoBrain.personalizar(Historia.EPILOGO, "").begins_with("Obrigado! "), true)
	_assert_eq("nome sem espacos sobrando", EchoBrain.limpar_nome("   Felipe   dos  Anjos "), "Felipe dos Anjos")
	_assert_eq("nome com no maximo 16 letras", EchoBrain.limpar_nome("Maria Eduarda da Silva").length() <= 16, true)
	_assert_eq("nome sem simbolos de formatacao", EchoBrain.limpar_nome("{Bia}%"), "Bia")


func _test_modo_deixa_comigo() -> void:
	_assert_eq("no modo ajuda o Echo da pistas", EchoBrain.fala_permitida("near_miss", "ajuda"), true)
	_assert_eq("no modo deixa comigo o Echo nao da pistas", EchoBrain.fala_permitida("near_miss", "sozinho"), false)
	_assert_eq("no modo deixa comigo o Echo continua comemorando", EchoBrain.fala_permitida("crystal_on", "sozinho"), true)


func _test_falas_do_echo() -> void:
	var echo = EchoBrain.new()
	var sem_marcador := true
	for chave in EchoBrain.LINES.keys():
		for fala in EchoBrain.LINES[chave]:
			var texto: String = fala
			sem_marcador = sem_marcador and not EchoBrain.personalizar(texto, "").contains("{") and not EchoBrain.personalizar(texto, "Bia").contains("{")
	_assert_eq("nenhuma fala do Echo fica com marcador sobrando", sem_marcador, true)
	echo.player_name = "Bia"
	_assert_eq("a curiosidade do Echo nunca vem vazia", echo.say("curiosity") != "", true)


# ---------------------------------------------------------------- conquistas e recompensas (v3.3)

func _test_conquistas_da_vitoria() -> void:
	var primeira := Conquistas.da_vitoria({"fase": 0, "rotacoes": 3, "meta": 3, "dica": false, "segundos": 9.0, "fragmentos": 1, "total_fases": 10, "total_estrelas": 3})
	_assert_eq("fase 1 sem dica, na meta e rapida da 4 conquistas", primeira, ["primeira_luz", "sem_dica", "na_medida", "relampago"])
	var com_dica := Conquistas.da_vitoria({"fase": 4, "rotacoes": 9, "meta": 6, "dica": true, "segundos": 80.0, "fragmentos": 5, "total_fases": 10, "total_estrelas": 12})
	_assert_eq("com dica e acima da meta so ganha meio prisma", com_dica, ["meio_prisma"])
	var final := Conquistas.da_vitoria({"fase": 9, "rotacoes": 12, "meta": 10, "dica": true, "segundos": 60.0, "fragmentos": 10, "total_fases": 10, "total_estrelas": 30})
	_assert_eq("ultimo fragmento e 30 estrelas dao as conquistas finais", final.has("prisma_restaurado") and final.has("ceu_estrelado"), true)


func _test_conquistas_novas() -> void:
	_assert_eq("conquista ja ganha nao aparece de novo", Conquistas.novas(["sem_dica", "na_medida"], ["sem_dica"]), ["na_medida"])
	var ids := {}
	var completas := true
	for item in Conquistas.LISTA:
		ids[item["id"]] = true
		completas = completas and str(item["titulo"]) != "" and str(item["texto"]) != ""
	_assert_eq("toda conquista tem id unico, titulo e texto", completas and ids.size() == Conquistas.total(), true)
	_assert_eq("conquista desconhecida devolve vazio", Conquistas.dados("nao_existe"), {})


func _test_recompensas_por_estrelas() -> void:
	_assert_eq("cor azul e liberada desde o inicio", Conquistas.liberado(Conquistas.CORES, "azul", 0), true)
	_assert_eq("arco-iris so com 30 estrelas", Conquistas.liberado(Conquistas.CORES, "arco_iris", 29), false)
	_assert_eq("coroa liberada com estrelas suficientes", Conquistas.liberado(Conquistas.ACESSORIOS, "coroa", 26), true)
	_assert_eq("com 0 estrelas a proxima recompensa e a mais barata", int(Conquistas.proxima_recompensa(0)[2]), 5)
	_assert_eq("com 30 estrelas nao falta nenhuma recompensa", Conquistas.proxima_recompensa(30), [])


func _test_atalhos_por_fase() -> void:
	var fase1 := UIKit.atalhos_da_fase(0)
	var fase4 := UIKit.atalhos_da_fase(3)
	_assert_eq("fase 1 mostra so os atalhos basicos", fase1.contains("H: dica") and not fase1.contains("Z: desfazer"), true)
	_assert_eq("fases seguintes mostram todos os atalhos", fase4.contains("Z: desfazer") and fase4.contains("T: falar com o Echo") and fase4.contains("M: música"), true)


func _test_nota_da_sala() -> void:
	var esquerda := Musica.nota_da_posicao(40.0, 40.0, 1200.0)
	var direita := Musica.nota_da_posicao(1240.0, 40.0, 1200.0)
	_assert_eq("clique a esquerda da sala toca a nota mais grave", esquerda, Musica.ESCALA[0])
	_assert_eq("clique a direita da sala toca a nota mais aguda", direita, Musica.ESCALA.back())
	_assert_eq("clique fora da sala continua dentro da escala", Musica.ESCALA.has(Musica.nota_da_posicao(-500.0, 40.0, 1200.0)), true)

# --- v3.3 visual ---
func _test_visual_temas() -> void:
	var temas := preload("res://scripts/temas.gd")
	var expected := ["Azul frio", "Azul frio", "Azul frio", "Violeta", "Violeta", "Ambar", "Ambar", "Verde-azulado", "Verde-azulado", "Dourado"]
	for i in range(10):
		var theme: Dictionary = temas.cor_da_fase(i)
		_assert_eq("tema da fase %d" % (i + 1), theme["nome"], expected[i])
		var room: Color = theme["sala"]
		_assert_eq("fundo da fase %d preserva contraste do feixe" % (i + 1), room.get_luminance() < 0.12, true)
	_assert_eq("tema limita indice negativo", temas.cor_da_fase(-1), temas.cor_da_fase(0))
	_assert_eq("tema limita indice acima do fim", temas.cor_da_fase(50), temas.cor_da_fase(9))
	var changed: Dictionary = temas.cor_da_fase(0)
	changed["nome"] = "alterado"
	_assert_eq("tema retorna dados independentes", temas.cor_da_fase(0)["nome"], "Azul frio")


func _test_visual_recorte() -> void:
	var beam := preload("res://scripts/light_beam.gd")
	var segment := {"a": Vector2(100, 0), "b": Vector2(100, 120), "distance": 200.0, "color": "red"}
	var original := segment.duplicate(true)
	_assert_proximo("ramo nao nasce antes da distancia acumulada", beam.visible_length(segment, 180.0), 0.0)
	_assert_proximo("ramo comeca na distancia acumulada", beam.visible_length(segment, 200.0), 0.0)
	_assert_proximo("ramo cresce pelo proprio comprimento", beam.visible_length(segment, 245.0), 45.0)
	_assert_proximo("ramo para no fim do trecho", beam.visible_length(segment, 900.0), 120.0)
	_assert_proximo("intro concluida mostra trecho completo", beam.visible_length(segment, INF), 120.0)
	_assert_eq("recorte nao altera dados do calculo", segment, original)
	var empty := {"a": Vector2.ONE, "b": Vector2.ONE, "distance": 0.0}
	_assert_proximo("trecho sem comprimento nao desenha ponta", beam.visible_length(empty, INF), 0.0)
	var incoming := {"a": Vector2.ZERO, "b": Vector2(200, 0), "distance": 0.0}
	_assert_proximo("tronco ja chegou ao divisor", beam.visible_length(incoming, 245.0), 200.0)
	var second_branch := {"a": Vector2(200, 0), "b": Vector2(300, 0), "distance": 200.0}
	_assert_proximo("ramos do divisor crescem juntos", beam.visible_length(second_branch, 245.0), 45.0)


func _test_visual_poeira() -> void:
	var background := preload("res://scripts/scene_background.gd")
	var segments := [{"a": Vector2.ZERO, "b": Vector2(100, 0), "distance": 0.0, "color": "red"}]
	var original := segments.duplicate(true)
	var lit: Color = background.luz_no_ponto(Vector2(50, 0), segments)
	_assert_proximo("poeira sobre o raio recebe brilho", lit.a, 1.0)
	_assert_eq("poeira recebe cor do trecho", lit.r > lit.b and lit.r > lit.g, true)
	var near: Color = background.luz_no_ponto(Vector2(50, 24), segments)
	_assert_proximo("brilho da poeira cai com distancia", near.a, 0.25)
	var far: Color = background.luz_no_ponto(Vector2(50, 49), segments)
	_assert_proximo("poeira distante fica apagada", far.a, 0.0)
	var ahead: Color = background.luz_no_ponto(Vector2(100, 0), segments, 40.0)
	_assert_proximo("poeira espera a ponta da intro chegar", ahead.a, 0.0)
	var hidden: Color = background.luz_no_ponto(Vector2.ZERO, segments, 0.0)
	_assert_proximo("carga do emissor nao ilumina poeira", hidden.a, 0.0)
	_assert_eq("poeira nao altera os segmentos", segments, original)
	var no_beam: Color = background.luz_no_ponto(Vector2.ZERO, [])
	_assert_proximo("sala sem feixe nao ilumina poeira", no_beam.a, 0.0)
	segments.append({"a": Vector2(0, 10), "b": Vector2(100, 10), "distance": 0.0, "color": "blue"})
	var blue: Color = background.luz_no_ponto(Vector2(50, 10), segments)
	_assert_eq("poeira prefere trecho mais proximo", blue.b > blue.r, true)
	segments.reverse()
	var reordered: Color = background.luz_no_ponto(Vector2(50, 10), segments)
	_assert_eq("cor da poeira independe da ordem de trechos", reordered, blue)


func _test_visual_mouse() -> void:
	var art := preload("res://scripts/menu_art.gd")
	_assert_eq("raio do menu centralizado sem deslocamento", art.mouse_offset(Vector2.ZERO), Vector2.ZERO)
	_assert_eq("movimento do mouse tem limite", art.mouse_offset(Vector2(5000, -5000)), Vector2(18, -28))
	_assert_eq("movimento do mouse tem limite oposto", art.mouse_offset(Vector2(-5000, 5000)), Vector2(-18, 28))
	_assert_eq("movimento do mouse e proporcional", art.mouse_offset(Vector2(320, 180)), Vector2(9, 14))


func _test_clima_das_salas() -> void:
	var temas := preload("res://scripts/temas.gd")
	_assert_eq("fase 1 tem poeira", temas.cor_da_fase(0)["clima"], "poeira")
	_assert_eq("fases 6-7 tem faiscas", temas.cor_da_fase(5)["clima"], "faiscas")
	_assert_eq("fases 8-9 tem vaga-lumes", temas.cor_da_fase(8)["clima"], "vagalumes")
	_assert_eq("fase 10 tem po dourado", temas.cor_da_fase(9)["clima"], "po_dourado")


# O cartao de peca nova aparece exatamente na primeira fase que tem aquela peca.
func _test_cartoes_de_peca_nova() -> void:
	var fases := Levels.get_levels()
	var corretos := true
	for indice in UIKit.PECAS_NOVAS.keys():
		var peca: String = UIKit.PECAS_NOVAS[indice]["peca"]
		var primeira := -1
		for i in range(fases.size()):
			if _fase_tem_peca(fases[i], peca):
				primeira = i
				break
		corretos = corretos and primeira == int(indice)
	_assert_eq("cada cartao de peca nova esta na primeira fase com a peca", corretos, true)


func _fase_tem_peca(fase: Dictionary, peca: String) -> bool:
	match peca:
		"bloco":
			return not fase["obstacles"].is_empty()
		"filtro":
			return not fase["filters"].is_empty()
		"prisma":
			return not fase.get("prisms", []).is_empty()
	for espelho in fase["mirrors"]:
		if peca == "divisor" and espelho["kind"] == "splitter":
			return true
		if peca == "travado" and espelho["kind"] == "mirror" and not espelho["can_rotate"]:
			return true
	return false
