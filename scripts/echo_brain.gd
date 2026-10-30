extends RefCounted

# Falas do assistente Echo. Cada situacao tem varias variacoes; Echo sorteia uma e evita
# repetir a ultima fala usada naquela situacao. Os textos aceitam valores com "%" e o
# marcador {nome}, trocado pelo nome do jogador (ou removido, se ele nao quis dizer).

const NOME_MAX := 16

# Falas de ajuda que somem quando o jogador escolhe "Deixa comigo!".
const FALAS_DE_AJUDA := ["near_miss", "warmer", "colder", "struggle", "revisit", "idle"]

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
	"pet": [
		"Hehe, faz cócegas! O que você quer, {nome}?",
		"Oi, {nome}! Como posso ajudar?",
		"Estou aqui! Escolha uma opção.",
	],
	"curiosity": [
		"Sabia? A luz do Sol leva cerca de 8 minutos para chegar até a Terra.",
		"O arco-íris é a luz do Sol separada pelas gotas de chuva, igualzinho ao prisma deste jogo!",
		"Vaga-lumes fazem luz fria: quase nada da energia deles vira calor.",
		"Periscópios de submarino usam dois espelhos para enxergar acima da água.",
		"A internet viaja como luz dentro de fibras de vidro, refletindo milhares de vezes pelo caminho.",
		"O céu é azul porque o ar espalha mais a luz azul do que a vermelha.",
		"Faróis antigos usavam espelhos e lentes para que sua luz fosse vista a quilômetros no mar.",
	],
	"help_yes": [
		"Combinado, {nome}! Se você travar, eu dou uma pista.",
	],
	"help_no": [
		"Respeito! Vou ficar quietinho e só comemorar com você. Se mudar de ideia, clique em mim.",
	],
	"wake": [
		"Opa! Acho que cochilei. Vamos continuar?",
		"Hã? Ah, você voltou! Bora acender esses cristais.",
	],
	"bye": [
		"Tá bom! Estou aqui em cima se precisar.",
		"Beleza! Qualquer coisa, é só clicar em mim.",
	],
	"win_perfect": [
		"Perfeito, {nome}! Exatamente a meta de rotações.",
		"Impecável! Nenhum giro a mais.",
		"Uau, solução perfeita!",
	],
	"win_no_hint": [
		"Sem nenhuma dica! Que orgulho.",
		"Resolveu sozinho, sem dica. Mandou bem, {nome}!",
	],
	"win_record": [
		"Novo recorde! Você está ficando craque, {nome}.",
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
var player_name := ""


func say(key: String, values: Array = []) -> String:
	var options: Array = LINES.get(key, [""])
	var index := randi() % options.size()
	if options.size() > 1 and _last.get(key, -1) == index:
		index = (index + 1) % options.size()
	_last[key] = index
	var text: String = options[index]
	return personalizar(text % values if not values.is_empty() else text, player_name)


# Troca {nome} pelo nome do jogador. Sem nome, o marcador some sem deixar virgula sobrando.
static func personalizar(texto: String, nome: String) -> String:
	if nome.strip_edges() != "":
		return texto.replace("{nome}", nome.strip_edges())
	return texto.replace(", {nome}", "").replace(" {nome}", "").replace("{nome}, ", "").replace("{nome}", "")


# Limpa o nome digitado: sem espacos sobrando, sem simbolos de formatacao e no maximo 16 letras.
static func limpar_nome(texto: String) -> String:
	var limpo := texto
	for simbolo in ["%", "{", "}", "[", "]", "\n", "\t"]:
		limpo = limpo.replace(simbolo, "")
	while limpo.contains("  "):
		limpo = limpo.replace("  ", " ")
	return limpo.strip_edges().left(NOME_MAX).strip_edges()


# "sozinho": o jogador pediu para resolver sem pistas, entao o Echo so comemora e avisa eventos.
static func fala_permitida(chave: String, modo: String) -> bool:
	return modo != "sozinho" or not FALAS_DE_AJUDA.has(chave)


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
