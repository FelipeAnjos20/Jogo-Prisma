extends RefCounted

# Falas do assistente Echo. Cada situacao tem varias variacoes; Echo sorteia uma e evita
# repetir a ultima fala usada naquela situacao. Os textos aceitam valores com "%".

const LINES := {
	"crystal_on": [
		"Isso! Um cristal aceso. %s",
		"Boa! Esse já brilhou. %s",
		"Acertou um! %s",
	],
	"crystal_off": [
		"Ops, esse cristal apagou. A luz deixou de chegar nele.",
		"Opa, perdemos um cristal. Algum giro tirou a luz dele.",
		"Esse cristal apagou. Desfazer (Z) volta o último giro, se quiser.",
	],
	"near_miss": [
		"Quase! O raio passou a %d px do cristal. Mais um passo de 15° pode resolver.",
		"Uau, passou a só %d px do cristal! Está no caminho certo.",
		"Tão perto! Faltaram só %d px. Tente ajustar o último espelho.",
	],
	"warmer": [
		"Está esquentando! O raio chegou mais perto do cristal.",
		"Mais quente! Esse giro aproximou a luz do cristal.",
		"Isso, está chegando perto. Continue nessa direção!",
	],
	"colder": [
		"Esfriou... o raio se afastou do cristal.",
		"Hmm, ficou mais longe. Que tal girar para o outro lado?",
	],
	"wrong_color": [
		"A luz chegou, mas este cristal só acende com luz %s %s.",
		"Chegou luz, mas da cor errada. Este cristal quer luz %s %s.",
	],
	"struggle": [
		"Está difícil? Tudo bem! Aperte H e eu te mostro um caminho.",
		"Puzzle teimoso, né? Uma dica (H) pode ajudar a destravar.",
	],
	"revisit": [
		"Você já testou essa posição antes. Que tal girar outro espelho?",
		"Hmm, essa configuração já apareceu. Experimente começar pelo espelho mais perto do emissor.",
	],
	"idle": [
		"Travou? Aperte H (ou o botão Dica) e eu te dou uma pista.",
		"Pensando bastante? Passe o mouse sobre as peças: eu explico o que cada uma faz.",
	],
	"angles_on": ["Guia de ângulos ligado. Selecione um espelho para ver os ângulos."],
	"angles_off": ["Guia de ângulos desligado. Aperte G para ligar de novo."],
	"win_perfect": [
		"Perfeito! Exatamente a meta de rotações.",
		"Impecável! Nenhum giro a mais.",
		"Uau, solução perfeita!",
	],
	"win_no_hint": [
		"Sem nenhuma dica! Que orgulho.",
		"Resolveu sozinho, sem dica. Mandou bem!",
	],
	"win_record": [
		"Novo recorde! Você está ficando craque.",
		"Bateu o próprio recorde. Isso é evoluir!",
	],
	"win_fast": [
		"Rápido como a luz! Só %d segundos.",
	],
	"win_improve": [
		"Conseguiu! Dá para resolver com %d rotações. Quer tentar de novo?",
		"Feito! A meta é %d rotações. Topa o desafio das 3 estrelas?",
	],
	"win_with_hint": [
		"Juntos conseguimos! Da próxima vez, tente sem dica.",
		"Missão cumprida! As dicas ajudaram, hein?",
	],
}

var _last := {}


func say(key: String, values: Array = []) -> String:
	var options: Array = LINES.get(key, [""])
	var index := randi() % options.size()
	if options.size() > 1 and _last.get(key, -1) == index:
		index = (index + 1) % options.size()
	_last[key] = index
	var text: String = options[index]
	return text % values if not values.is_empty() else text


# Escolhe o comentario do Echo para o painel de vitoria.
func victory_comment(stars: int, rotations: int, par: int, hint_used: bool, record: bool, seconds: float) -> String:
	if record:
		return say("win_record")
	if stars == 3 and rotations == par:
		return say("win_perfect")
	if stars == 3 and not hint_used and seconds < 12.0:
		return say("win_fast", [int(seconds)])
	if stars == 3 and not hint_used:
		return say("win_no_hint")
	if hint_used:
		return say("win_with_hint")
	return say("win_improve", [par])
