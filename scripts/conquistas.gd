extends RefCounted

# Conquistas do jogador e recompensas por estrelas (visual do Echo).
# Regras puras, sem nodes: usadas pelo jogo e testadas em tests/run_tests.gd.

const LISTA := [
	{"id": "primeira_luz", "titulo": "Primeira luz", "texto": "Conclua a primeira fase."},
	{"id": "sem_dica", "titulo": "Por conta própria", "texto": "Conclua uma fase sem pedir dica."},
	{"id": "na_medida", "titulo": "Na medida", "texto": "Conclua uma fase com exatamente a meta de rotações."},
	{"id": "relampago", "titulo": "Rápido como a luz", "texto": "Conclua uma fase em menos de 15 segundos."},
	{"id": "amigo_echo", "titulo": "Amigo do Echo", "texto": "Converse com o Echo (clique nele ou aperte T)."},
	{"id": "curioso", "titulo": "Curioso", "texto": "Ouça 3 curiosidades do Echo."},
	{"id": "cientista", "titulo": "Cientista", "texto": "Abra \"Por que funcionou?\" depois de uma vitória."},
	{"id": "meio_prisma", "titulo": "Meio prisma", "texto": "Recupere 5 fragmentos."},
	{"id": "prisma_restaurado", "titulo": "Prisma restaurado", "texto": "Recupere os 10 fragmentos."},
	{"id": "ceu_estrelado", "titulo": "Céu estrelado", "texto": "Consiga todas as 30 estrelas."},
]

const CURIOSIDADES_PARA_CONQUISTA := 3
const SEGUNDOS_RELAMPAGO := 15.0

# Visual do Echo liberado pelas estrelas: [id, nome, estrelas necessarias].
const CORES := [
	["azul", "Azul", 0],
	["menta", "Menta", 5],
	["rosa", "Rosa", 10],
	["violeta", "Violeta", 15],
	["dourado", "Dourado", 22],
	["arco_iris", "Arco-íris", 30],
]
const ACESSORIOS := [
	["nenhum", "Nenhum", 0],
	["laco", "Laço", 8],
	["chapeu", "Chapéu de mago", 16],
	["coroa", "Coroa", 26],
]


static func total() -> int:
	return LISTA.size()


static func dados(id: String) -> Dictionary:
	for item in LISTA:
		if item["id"] == id:
			return item
	return {}


# Conquistas ganhas ao concluir uma fase. ctx: fase (indice), estrelas, rotacoes, meta,
# dica (bool), segundos, fragmentos, total_fases, total_estrelas.
static func da_vitoria(ctx: Dictionary) -> Array:
	var ganhas: Array = []
	if int(ctx.get("fase", -1)) == 0:
		ganhas.append("primeira_luz")
	if not bool(ctx.get("dica", true)):
		ganhas.append("sem_dica")
	if int(ctx.get("rotacoes", -1)) == int(ctx.get("meta", -2)):
		ganhas.append("na_medida")
	if float(ctx.get("segundos", 999.0)) < SEGUNDOS_RELAMPAGO:
		ganhas.append("relampago")
	var total_fases := int(ctx.get("total_fases", 10))
	if int(ctx.get("fragmentos", 0)) >= ceili(total_fases / 2.0):
		ganhas.append("meio_prisma")
	if int(ctx.get("fragmentos", 0)) >= total_fases:
		ganhas.append("prisma_restaurado")
	if int(ctx.get("total_estrelas", 0)) >= total_fases * 3:
		ganhas.append("ceu_estrelado")
	return ganhas


# So as que o jogador ainda nao tinha, na ordem da lista.
static func novas(ganhas: Array, ja_tem: Array) -> Array:
	var resultado: Array = []
	for item in LISTA:
		if ganhas.has(item["id"]) and not ja_tem.has(item["id"]):
			resultado.append(item["id"])
	return resultado


static func liberado(opcoes: Array, id: String, estrelas: int) -> bool:
	for opcao in opcoes:
		if opcao[0] == id:
			return estrelas >= int(opcao[2])
	return false


# Proxima recompensa ainda bloqueada (para mostrar "faltam X estrelas"). [] se ja liberou tudo.
static func proxima_recompensa(estrelas: int) -> Array:
	var melhor: Array = []
	for opcao in CORES + ACESSORIOS:
		if estrelas < int(opcao[2]) and (melhor.is_empty() or int(opcao[2]) < int(melhor[2])):
			melhor = opcao
	return melhor
