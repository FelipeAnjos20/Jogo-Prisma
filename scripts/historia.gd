extends RefCounted

# Historia do jogo: cada fragmento recuperado devolve uma memoria do Prisma de Luz.
# A ultima fase libera o final. Os textos aceitam {nome} (nome do jogador).

const FRAGMENTOS := [
	{
		"titulo": "O Farol de Aurora",
		"texto": "Antes de tudo, o Prisma ficava no alto do Farol de Aurora. Sua luz atravessava o vale inteiro e guiava quem estivesse perdido.",
	},
	{
		"titulo": "A noite sem estrelas",
		"texto": "Uma noite, uma tempestade apagou o céu. Um raio atingiu o farol e o Prisma se partiu em dez pedaços, que caíram nas salas do subsolo.",
	},
	{
		"titulo": "As salas escuras",
		"texto": "Sem o Prisma, as salas ficaram escuras. Blocos de sombra cresceram nos corredores e passaram a engolir qualquer luz que chegasse perto.",
	},
	{
		"titulo": "Os guardiões travados",
		"texto": "Os antigos guardiões deixaram espelhos presos nas paredes. Eles não giram mais, mas ainda lembram para onde a luz deve ir.",
	},
	{
		"titulo": "O vidro que divide",
		"texto": "Os construtores do farol sabiam que uma luz pode estar em dois lugares ao mesmo tempo. Por isso criaram o vidro roxo, que divide o raio em dois.",
	},
	{
		"titulo": "As cores adormecidas",
		"texto": "Dentro da luz branca dormem todas as cores. Os filtros acordam uma de cada vez, e cada cristal colorido espera pela sua.",
	},
	{
		"titulo": "Cada cor no seu caminho",
		"texto": "Quando o Prisma quebrou, as cores se perderam umas das outras. Para voltar a brilhar juntas, cada uma precisa encontrar o próprio caminho.",
	},
	{
		"titulo": "Uma voz no escuro",
		"texto": "No meio das ruínas, uma faísca continuou acesa e aprendeu a falar. Ela chamou a si mesma de Echo: o eco da luz que existia ali.",
	},
	{
		"titulo": "O segredo de Echo",
		"texto": "Echo não é só um ajudante. Ele é o último brilho do próprio Prisma, e cada fragmento recuperado devolve um pouco da sua memória.",
	},
	{
		"titulo": "O Prisma inteiro",
		"texto": "Com o último fragmento, a luz branca volta a se abrir em todas as cores. O farol acende de novo e Echo, enfim, lembra quem é.",
	},
]

const EPILOGO := "Obrigado, {nome}! Graças a você o Farol de Aurora voltou a brilhar. Sempre que vir um arco-íris, lembre: é a luz contando que encontrou o caminho."

# Ilustracao opcional de cada memoria. Se o arquivo existir, ele aparece junto do texto.
const PASTA_IMAGENS := "res://assets/story/"


static func total() -> int:
	return FRAGMENTOS.size()


static func fragmento(indice: int) -> Dictionary:
	if indice < 0 or indice >= FRAGMENTOS.size():
		return {}
	return FRAGMENTOS[indice]


static func caminho_imagem(indice: int) -> String:
	return PASTA_IMAGENS + "fragmento_%02d.png" % (indice + 1)


static func imagem(indice: int) -> Texture2D:
	var caminho := caminho_imagem(indice)
	if not ResourceLoader.exists(caminho):
		return null
	return load(caminho) as Texture2D
