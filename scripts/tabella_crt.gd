extends Control
class_name TabellaCRT
## Compare dopo ogni attacco: la Tabella dei risultati del combattimento con la colonna dell'arma
## e la riga del totale evidenziate; la casella dove si incrociano è il risultato.

const COLONNE := ["pugnale", "pugnale_lancio", "arco", "spada", "martello", "ascia", "mostro"]
const NOMI := {"pugnale": "Pugnale", "pugnale_lancio": "Lancio", "arco": "Arco", "spada": "Spada",
	"martello": "Martello", "ascia": "Ascia", "mostro": "Mostro"}

var dati: Dictionary = {}
var tempo := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0

func mostra(e: Dictionary, durata: float) -> void:
	dati = e
	tempo = durata
	modulate.a = 1.0
	queue_redraw()

func attiva() -> bool:
	return tempo > 0.0

func _process(delta: float) -> void:
	if tempo > 0:
		tempo -= delta
		modulate.a = clamp(tempo / 0.4, 0.0, 1.0)

func _draw() -> void:
	if dati.is_empty() or modulate.a <= 0.01: return
	var f = Risorse.font("Testo")
	var fg = Risorse.font_grassetto()
	var W = size.x
	var H = size.y
	draw_style_box(Risorse.box(Color(0.86, 0.78, 0.6, 0.97), Color(0.35, 0.2, 0.08), 3, 6, 0), Rect2(0, 0, W, H))
	var ink = Color(0.2, 0.1, 0.05)
	var rosso = Color(0.55, 0.08, 0.05)
	var dim = clampi(int(W / 34.0), 11, 16)
	var tit = "Tabella dei risultati del combattimento"
	draw_string(fg, Vector2(10, 8 + dim), tit, HORIZONTAL_ALIGNMENT_CENTER, W - 20, dim + 1, rosso)
	var n = int(dati.get("ferite", 0))
	var esito = "mancato" if n == 0 else ("%d ferit%s" % [n, "a" if n == 1 else "e"])
	var riga_txt = "%s: dado %d %+d = %d, colonna %s: %s" % [dati.get("testo", ""), int(dati.get("dado", 0)), int(dati.get("mod", 0)), int(dati.get("tot", 0)), NOMI.get(dati.get("col", ""), ""), esito]
	draw_string(f, Vector2(10, 14 + dim * 2 + 4), riga_txt, HORIZONTAL_ALIGNMENT_CENTER, W - 20, dim, ink)
	var y0 = 24.0 + dim * 3
	var righe = Dati.CRT_RIGHE.size()
	var hr = (H - y0 - 8) / float(righe + 1)
	var wc0 = W * 0.13
	var wc = (W - 16 - wc0) / float(COLONNE.size())
	var x0 = 8.0
	var col_sel = COLONNE.find(dati.get("col", ""))
	var riga_sel = int(dati.get("riga", -1))
	# fasce evidenziate: colonna e riga
	if col_sel >= 0:
		draw_rect(Rect2(x0 + wc0 + col_sel * wc, y0, wc, hr * (righe + 1)), Color(0.95, 0.75, 0.25, 0.45))
	if riga_sel >= 0:
		draw_rect(Rect2(x0, y0 + hr * (riga_sel + 1), wc0 + wc * COLONNE.size(), hr), Color(0.95, 0.75, 0.25, 0.45))
	# intestazioni
	draw_string(fg, Vector2(x0, y0 + hr * 0.7), "Totale", HORIZONTAL_ALIGNMENT_CENTER, wc0, dim - 1, ink)
	for i in COLONNE.size():
		draw_string(fg, Vector2(x0 + wc0 + i * wc, y0 + hr * 0.7), NOMI[COLONNE[i]], HORIZONTAL_ALIGNMENT_CENTER, wc, dim - 1, ink)
	draw_line(Vector2(x0, y0 + hr), Vector2(W - 8, y0 + hr), ink, 1.5)
	for r in righe:
		var yy = y0 + hr * (r + 1)
		if r % 2 == 1:
			draw_rect(Rect2(x0, yy, W - 16, hr), Color(0.4, 0.25, 0.1, 0.08))
		draw_string(fg, Vector2(x0, yy + hr * 0.72), Dati.CRT_RIGHE[r], HORIZONTAL_ALIGNMENT_CENTER, wc0, dim - 1, ink)
		for i in COLONNE.size():
			var v = int(Dati.CRT[COLONNE[i]][r])
			var t = "-" if v == 0 else str(v)
			var cel = Rect2(x0 + wc0 + i * wc, yy, wc, hr)
			if i == col_sel and r == riga_sel:
				draw_style_box(Risorse.box(Color(0.6, 0.06, 0.04, 1.0), Color(1.0, 0.85, 0.35), 3, 4, 0), cel.grow(1))
				draw_string(fg, Vector2(cel.position.x, yy + hr * 0.74), t, HORIZONTAL_ALIGNMENT_CENTER, wc, dim + 1, Color(1, 0.95, 0.8))
			else:
				draw_string(f, Vector2(cel.position.x, yy + hr * 0.72), t, HORIZONTAL_ALIGNMENT_CENTER, wc, dim - 1, ink)
	draw_line(Vector2(x0 + wc0, y0), Vector2(x0 + wc0, H - 8), ink, 1.0)
