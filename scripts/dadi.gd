extends Control
class_name Dadi
## Mostra i dadi tirati: facce disegnate a mano (niente simboli di font), con una breve animazione.

var valori: Array = []
var testo := ""
var tempo := 0.0
var rotolo := 0.0
const LATO := 46.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0

func mostra(v: Array, t: String) -> void:
	valori = v.duplicate()
	testo = t
	tempo = 2.4
	rotolo = 0.35
	modulate.a = 1.0
	queue_redraw()

func _process(delta: float) -> void:
	if tempo > 0:
		tempo -= delta
		rotolo = maxf(0.0, rotolo - delta)
		modulate.a = clamp(tempo / 0.5, 0.0, 1.0)
		queue_redraw()

func _draw() -> void:
	if valori.is_empty() or modulate.a <= 0.01: return
	var f = Risorse.font("Testo")
	var tw = f.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var w = maxf(valori.size() * (LATO + 12) + 24, tw + 30)
	var x0 = (size.x - w) / 2
	draw_style_box(Risorse.box(Color(0.08, 0.04, 0.04, 0.9), Risorse.COL_ORO, 2, 8, 6), Rect2(x0, 0, w, LATO + 44))
	draw_string(f, Vector2(x0 + (w - tw) / 2, 22), testo, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Risorse.COL_PERGAMENA)
	var xd = (size.x - valori.size() * (LATO + 12) + 12) / 2
	for i in valori.size():
		var v = int(valori[i])
		if rotolo > 0:
			v = (int(Time.get_ticks_msec() / 70) + i * 3) % 6 + 1
		_faccia(Vector2(xd + i * (LATO + 12), 32), v)

func _faccia(p: Vector2, v: int) -> void:
	var r = Rect2(p, Vector2(LATO, LATO))
	draw_style_box(Risorse.box(Color(0.93, 0.88, 0.78), Color(0.35, 0.05, 0.05), 2, 8, 0), r)
	var c = p + Vector2(LATO, LATO) / 2
	var d = LATO * 0.26
	var punti = {
		1: [Vector2.ZERO], 2: [Vector2(-1, -1), Vector2(1, 1)], 3: [Vector2(-1, -1), Vector2.ZERO, Vector2(1, 1)],
		4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
		5: [Vector2(-1, -1), Vector2(1, -1), Vector2.ZERO, Vector2(-1, 1), Vector2(1, 1)],
		6: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)],
	}
	for q in punti.get(clampi(v, 1, 6), []):
		draw_circle(c + q * d, LATO * 0.085, Color(0.45, 0.04, 0.05))
