extends SceneTree

## Executor de testes automatizados, sem interface grafica:
## godot --headless --script res://tests/run_tests.gd

const Geometria = preload("res://scripts/geometria.gd")

var _total := 0
var _falhas := 0


func _init() -> void:
	_test_gira_no_sentido_horario()
	_test_gira_no_sentido_anti_horario()
	_test_direcao_zero_mantem_angulo()
	_test_normaliza_apos_passar_de_360_graus()
	_test_normaliza_angulo_negativo()
	_test_normalizar_angulo_direto()

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
