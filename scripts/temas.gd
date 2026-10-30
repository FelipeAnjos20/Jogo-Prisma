class_name Temas
extends RefCounted

# Indices de fase comecam em zero. Paletas suaves preservam as cores da luz.
const PALETAS := [
	["Azul frio", Color("101b30"), Color("09111e"), Color("7599c2")],
	["Violeta", Color("24172e"), Color("140e21"), Color("b197c9")],
	["Ambar", Color("2b2018"), Color("19140f"), Color("c9ab80")],
	["Verde-azulado", Color("14282a"), Color("0b191e"), Color("85b9bb")],
	["Dourado", Color("2c281b"), Color("19170f"), Color("d6c38d")],
]


static func cor_da_fase(indice: int) -> Dictionary:
	var fase := clampi(indice, 0, 9)
	var grupo := 0
	if fase >= 9:
		grupo = 4
	elif fase >= 7:
		grupo = 3
	elif fase >= 5:
		grupo = 2
	elif fase >= 3:
		grupo = 1
	var paleta: Array = PALETAS[grupo]
	var acento: Color = paleta[3]
	return {
		"nome": paleta[0],
		"fundo": paleta[1],
		"sala": paleta[2],
		"acento": acento,
		"grade": Color(acento.r, acento.g, acento.b, 0.085),
		"vinheta": Color(0.005, 0.006, 0.012, 0.62),
	}
