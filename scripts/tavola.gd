extends Control
class_name Tavola
## La tavola del combattimento: le file dei mostri in alto e l'ordine di marcia del gruppo in basso,
## come le righe 1-2-3 / A-B-C del regolamento (9.3). Tocca una carta per sceglierla come bersaglio.

signal carta_premuta(uid: String)
signal posto_premuto(col: int, riga: int)

var motore: Motore
var evidenziati := {}            # uid -> true: bersagli validi
var posti_validi := []           # [Vector2i] posti liberi validi (riorganizzazione)
var selezionato := ""
var attore := ""
var titolo := ""
var _carte := {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(aggiorna)

func aggiorna() -> void:
	for c in get_children():
		c.queue_free()
	_carte.clear()
	if motore == null or motore.s.is_empty(): return
	var c: Dictionary = motore.s.get("comb", {})
	var in_comb = not c.is_empty() and c.get("esito", "") == ""
	var mostri: Array = []
	if in_comb:
		mostri = c["ordine_m"]
	elif not motore.s.get("incontro", {}).is_empty():
		var lista: Array = motore.s["incontro"]["mostri"].keys()
		var o2 = [["", "", ""], ["", "", ""], ["", "", ""]]
		for i in lista.size():
			if i < 9: o2[int(i / 3)][i % 3] = lista[i]
		mostri = o2
	var gruppo: Array = motore.ordine_gruppo() if in_comb else motore.s["ordine"]
	var righe_m = 0
	for r in mostri.size():
		var vuota = true
		for x in mostri[r]:
			if x != "": vuota = false
		if not vuota: righe_m = r + 1
	var righe_g = 0
	for r in gruppo.size():
		var vuota2 = true
		for x in gruppo[r]:
			if x != "": vuota2 = false
		if not vuota2: righe_g = r + 1
	if not posti_validi.is_empty():
		for p in posti_validi:
			righe_g = maxi(righe_g, p.y + 1)
	var tot = righe_m + righe_g
	if tot == 0: return
	var spazio = 26.0
	var h_carta = minf((size.y - spazio - 56) / float(tot) - 6, 150)
	var w_carta = minf(h_carta * 0.78, (size.x - 8) / 3.0 - 6)
	h_carta = w_carta / 0.78
	var x0 = (size.x - (w_carta * 3 + 12)) / 2
	var y = 4.0
	if titolo != "":
		var t = Widget.etichetta(titolo, 15, Risorse.COL_ORO, "grassetto")
		t.position = Vector2(0, 0)
		t.size = Vector2(size.x, 44)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(t)
		y += 48
	# mostri: dall'ultima fila alla prima (la prima è la più vicina al gruppo)
	for r in range(righe_m - 1, -1, -1):
		for col in 3:
			var uid: String = mostri[r][col]
			if uid == "": continue
			_carta(uid, Rect2(x0 + col * (w_carta + 6), y, w_carta, h_carta), true)
		y += h_carta + 6
	var linea = ColorRect.new()
	linea.color = Color(0.7, 0.15, 0.1, 0.7)
	linea.position = Vector2(x0, y + spazio / 2 - 1)
	linea.size = Vector2(w_carta * 3 + 12, 2)
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(linea)
	y += spazio
	for r in righe_g:
		for col in 3:
			var uid2: String = gruppo[r][col] if r < gruppo.size() else ""
			var rett = Rect2(x0 + col * (w_carta + 6), y, w_carta, h_carta)
			if uid2 == "":
				if Vector2i(col, r) in posti_validi:
					_posto(rett, col, r)
				continue
			_carta(uid2, rett, false)
		y += h_carta + 6

func _posto(r: Rect2, col: int, riga: int) -> void:
	var b = Button.new()
	b.position = r.position
	b.size = r.size
	b.text = "Qui"
	b.add_theme_stylebox_override("normal", Risorse.box(Color(0.3, 0.22, 0.08, 0.5), Risorse.COL_ORO, 2, 8, 4))
	b.add_theme_stylebox_override("hover", Risorse.box(Color(0.45, 0.32, 0.1, 0.7), Color(1, 0.9, 0.5), 3, 8, 4))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): posto_premuto.emit(col, riga))
	add_child(b)

func _carta(uid: String, r: Rect2, mostro: bool) -> void:
	var u = {}
	var nome = "Porta dell'Inferno"
	var tex = "hellgate"
	if uid != "hellgate":
		u = motore.unita(uid)
		if u.is_empty(): return
		nome = u.get("nome", uid)
		tex = u.get("ritratto", "")
	var b = Button.new()
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	var bordo = Color(0.45, 0.1, 0.08) if mostro else Color(0.55, 0.45, 0.25)
	var spess = 2
	if evidenziati.has(uid):
		bordo = Color(1.0, 0.85, 0.35)
		spess = 4
	if uid == attore:
		bordo = Color(0.5, 0.9, 1.0)
		spess = 4
	if uid == selezionato:
		bordo = Color(0.6, 1.0, 0.6)
		spess = 4
	b.add_theme_stylebox_override("normal", Risorse.box(Color(0.1, 0.06, 0.05, 0.95), bordo, spess, 6, 0))
	b.add_theme_stylebox_override("hover", Risorse.box(Color(0.2, 0.1, 0.08, 0.95), bordo.lightened(0.3), spess, 6, 0))
	b.add_theme_stylebox_override("pressed", Risorse.box(Color(0.2, 0.1, 0.08, 0.95), bordo, spess, 6, 0))
	b.pressed.connect(func(): carta_premuta.emit(uid))
	add_child(b)
	_carte[uid] = b
	var img = Widget.ritratto(tex, r.size.x - 8)
	img.position = Vector2(4, 4)
	img.size = Vector2(r.size.x - 8, r.size.y * 0.62)
	if u.get("dorme", false) or u.get("stato", "ok") == "pietra":
		img.modulate = Color(0.55, 0.6, 0.75)
	b.add_child(img)
	var dim = clampi(int(r.size.x / 8.5), 11, 16)
	var l = Widget.etichetta(nome, dim, Risorse.COL_PERGAMENA, "grassetto")
	l.position = Vector2(4, r.size.y * 0.62 + 6)
	l.size = Vector2(r.size.x - 8, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	if uid == "hellgate": return
	var pf = motore.pf_residui(u)
	var mx = int(u["pf_max"]) + int(u.get("pf_armatura", 0))
	var col = Color(0.75, 0.15, 0.12) if mostro else Color(0.3, 0.7, 0.3)
	var bar = Widget.barra(float(pf), float(mx), col, r.size.x - 16, 8)
	bar.position = Vector2(8, r.size.y * 0.62 + 8 + dim + 6)
	bar.size = Vector2(r.size.x - 16, 8)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bar)
	var info = "PF %d/%d" % [pf, mx]
	if mostro and uid.begins_with("m:"):
		info += "  BC %d" % (int(u["bc"]) + int(u.get("idra_bonus", 0)))
	if u.get("dorme", false): info += "  dorme"
	if u.get("scudo_magico", false): info += "  scudo"
	if int(u.get("armatura_magica", 0)) > 0: info += "  arm.%d" % int(u["armatura_magica"])
	var li = Widget.etichetta(info, dim - 1, Color(0.85, 0.8, 0.7))
	li.position = Vector2(4, r.size.y * 0.62 + 18 + dim + 6)
	li.size = Vector2(r.size.x - 8, 18)
	li.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	li.autowrap_mode = TextServer.AUTOWRAP_OFF
	li.clip_text = true
	li.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(li)

func lampeggia(uid: String) -> void:
	if not _carte.has(uid): return
	var b: Control = _carte[uid]
	var tw = create_tween()
	tw.tween_property(b, "modulate", Color(1.6, 0.5, 0.5), 0.1)
	tw.tween_property(b, "modulate", Color(1, 1, 1), 0.35)
