extends Control
## Interfaccia di Citadel of Blood: menu, creazione del gruppo, labirinto 3D, pannelli e combattimento.

const D = preload("res://scripts/dati.gd")
const FILE_SALVA := "user://citadel_salvataggio.json"

var motore: Motore
var vista: Vista3D
var svc: SubViewportContainer
var sv: SubViewport

var strato_menu: Control
var strato_crea: Control
var strato_gioco: Control
var strato_finestre: Control

# gioco
var barra_alta: PanelContainer
var lbl_info: Label
var col_sinistra: PanelContainer
var box_gruppo: VBoxContainer
var pan_azioni: PanelContainer
var box_azioni: VBoxContainer
var tavola: Tavola
var dadi: Dadi
var crt: TabellaCRT
var _coda_crt: Array = []
var _t_crt := 0.0
var pan_diario: PanelContainer
var txt_diario: RichTextLabel
var pan_tutorial: PanelContainer
var tutorial: Tutorial = null

var modalita_bersaglio := ""          # azione in attesa del bersaglio
var modalita_ordine := false
var _recenti: Array = []
var _coda_dadi: Array = []
var _t_dadi := 0.0
var _anteprima := {}
var _compatto := false
var _tocchi := {}
var _tocco_inizio := Vector2.ZERO
var _tocco_mosso := false
var _pinza_dist := 0.0
var _pinza_ang := 0.0
var _trascina := 0
var _modo_prova := ""

func _ready() -> void:
	theme = Risorse.tema()
	motore = Motore.new()
	_costruisci_3d()
	strato_gioco = Control.new()
	strato_gioco.set_anchors_preset(Control.PRESET_FULL_RECT)
	strato_gioco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strato_gioco)
	_costruisci_gioco()
	strato_menu = Control.new()
	strato_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(strato_menu)
	strato_crea = Control.new()
	strato_crea.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(strato_crea)
	strato_finestre = Control.new()
	strato_finestre.set_anchors_preset(Control.PRESET_FULL_RECT)
	strato_finestre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strato_finestre)
	dadi = Dadi.new()
	dadi.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dadi.custom_minimum_size = Vector2(420, 100)
	strato_finestre.add_child(dadi)
	resized.connect(_layout)
	get_tree().root.size_changed.connect(_scala_schermo)
	_scala_schermo()
	_modo_prova = OS.get_environment("PW_AVVIO")
	mostra_menu()
	_layout()
	if _modo_prova != "":
		call_deferred("_prova", _modo_prova)

# ============================================================================================
# 3D
# ============================================================================================
func _costruisci_3d() -> void:
	svc = SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_preset(Control.PRESET_FULL_RECT)
	svc.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(svc)
	sv = SubViewport.new()
	sv.handle_input_locally = false
	sv.msaa_3d = Viewport.MSAA_2X
	svc.add_child(sv)
	vista = Vista3D.new()
	vista.motore = motore
	sv.add_child(vista)
	svc.gui_input.connect(_input_3d)

func _input_3d(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.device == InputEvent.DEVICE_ID_EMULATION: return
		match ev.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if ev.pressed: vista.zoom(0.9)
			MOUSE_BUTTON_WHEEL_DOWN:
				if ev.pressed: vista.zoom(1.1)
			MOUSE_BUTTON_LEFT:
				if ev.pressed:
					_trascina = 1
					_tocco_inizio = ev.position
					_tocco_mosso = false
				else:
					if not _tocco_mosso: _tocco_su(ev.position)
					_trascina = 0
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_trascina = 2 if ev.pressed else 0
	elif ev is InputEventMouseMotion:
		if ev.device == InputEvent.DEVICE_ID_EMULATION: return
		if _trascina == 1:
			if ev.position.distance_to(_tocco_inizio) > 6: _tocco_mosso = true
			if _tocco_mosso: vista.sposta(ev.relative)
		elif _trascina == 2:
			vista.ruota(-ev.relative.x * 0.008, -ev.relative.y * 0.006)
	elif ev is InputEventMagnifyGesture:
		vista.zoom(1.0 / ev.factor)
	elif ev is InputEventPanGesture:
		vista.sposta(-ev.delta * 8)
	elif ev is InputEventScreenTouch:
		if ev.pressed:
			_tocchi[ev.index] = ev.position
			if _tocchi.size() == 1:
				_tocco_inizio = ev.position
				_tocco_mosso = false
			_misura_pinza()
		else:
			if _tocchi.size() == 1 and not _tocco_mosso:
				_tocco_su(ev.position)
			_tocchi.erase(ev.index)
			_tocco_mosso = true if _tocchi.size() > 0 else _tocco_mosso
			_misura_pinza()
	elif ev is InputEventScreenDrag:
		_tocchi[ev.index] = ev.position
		if _tocchi.size() == 1:
			if ev.position.distance_to(_tocco_inizio) > 8: _tocco_mosso = true
			if _tocco_mosso: vista.sposta(ev.relative)
		elif _tocchi.size() >= 2:
			_tocco_mosso = true
			var k = _tocchi.keys()
			var a: Vector2 = _tocchi[k[0]]
			var b: Vector2 = _tocchi[k[1]]
			var dist = a.distance_to(b)
			var ang = (b - a).angle()
			if _pinza_dist > 0 and dist > 0:
				vista.zoom(_pinza_dist / dist)
				vista.ruota(-(ang - _pinza_ang), 0)
				vista.ruota(0, -ev.relative.y * 0.002)
			_pinza_dist = dist
			_pinza_ang = ang

func _misura_pinza() -> void:
	if _tocchi.size() >= 2:
		var k = _tocchi.keys()
		var a: Vector2 = _tocchi[k[0]]
		var b: Vector2 = _tocchi[k[1]]
		_pinza_dist = a.distance_to(b)
		_pinza_ang = (b - a).angle()
	else:
		_pinza_dist = 0.0

## Tocco sul labirinto: se è una tessera vicina, muove il gruppo
func _tocco_su(pos: Vector2) -> void:
	if motore.s.is_empty() or tutorial_blocca(): return
	var sc: Dictionary = motore.s.get("scelta", {})
	if sc.get("tipo", "") != "rotta": return
	var p = pos * (Vector2(sv.size) / svc.size) if svc.size.x > 0 else pos
	var cella = vista.cella_sotto(p)
	var xy = MotoreBase.da_chiave(motore.s["pos"]["xy"])
	var d = Dati.VETTORI.find(cella - xy)
	if d < 0: return
	for o in sc["opzioni"]:
		if int(o.get("dir", -1)) == d:
			_scegli(o["id"])
			return

# ============================================================================================
# Menu
# ============================================================================================
func mostra_menu() -> void:
	Widget.svuota(strato_menu)
	strato_menu.visible = true
	strato_crea.visible = false
	strato_gioco.visible = false
	var sfondo = TextureRect.new()
	sfondo.texture = Risorse.tex("copertina")
	sfondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sfondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	sfondo.modulate = Color(0.75, 0.7, 0.7)
	strato_menu.add_child(sfondo)
	var velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 0.35)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strato_menu.add_child(velo)
	var centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	strato_menu.add_child(centro)
	var p = Widget.pannello(Color(0.06, 0.03, 0.03, 0.82), Color(0.6, 0.42, 0.2))
	p.custom_minimum_size = Vector2(min(520, size.x - 40), 0)
	centro.add_child(p)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var t = Widget.titolo("Citadel of Blood", 64 if size.y > 600 else 44)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st = Widget.etichetta("Avventura fantastica nella fortezza del Male", 20, Risorse.COL_PERGAMENA, "Maiuscoletto")
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	var st2 = Widget.etichetta("SPI, 1980 · Eric Smith · versione digitale Reborn, solitario", 14, Color(0.8, 0.72, 0.6))
	st2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st2)
	v.add_child(HSeparator.new())
	if FileAccess.file_exists(FILE_SALVA):
		v.add_child(Widget.bottone("Continua la partita", continua, 20))
	v.add_child(Widget.bottone("Nuova partita", mostra_crea, 20))
	v.add_child(Widget.bottone("Tutorial: impara a giocare, passo passo", avvia_tutorial, 20))
	var h = HBoxContainer.new()
	h.add_child(Widget.bottone("Regolamento", func(): apri_regole(), 17))
	h.add_child(Widget.bottone("Tabelle", func(): apri_tabelle(), 17))
	v.add_child(h)

# ============================================================================================
# Creazione del gruppo (4.1)
# ============================================================================================
var _eroi_scelti: Array = []
var _iniziati: Array = []
var _inc_scelti := {}
var _scelta_libera := false
var _rng_crea := RandomNumberGenerator.new()

func mostra_crea() -> void:
	_rng_crea.randomize()
	_eroi_scelti = _pesca_eroi()
	_iniziati = []
	var razze = ["umano", "nano", "elfo"]
	for i in 3:
		var r: String = razze[i]
		var nomi: Array = D.NOMI_INIZIATI[r]
		var fem = _rng_crea.randi_range(0, 1) == 1
		_iniziati.append({"nome": nomi[_rng_crea.randi_range(0, nomi.size() - 1)], "razza": r, "femmina": fem, "arma2": "pugnale",
			"esperienza": "pf", "tiro_pm": _rng_crea.randi_range(1, 6)})
	_inc_scelti = {}
	_ridisegna_crea()

func _pesca_eroi() -> Array:
	var pool = []
	for e in D.EROI: pool.append(e["id"])
	var r = []
	for i in 3:
		var j = _rng_crea.randi_range(0, pool.size() - 1)
		r.append(pool[j])
		pool.remove_at(j)
	return r

func _ridisegna_crea() -> void:
	Widget.svuota(strato_crea)
	strato_menu.visible = false
	strato_crea.visible = true
	var sfondo = ColorRect.new()
	sfondo.color = Risorse.COL_FONDO
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	strato_crea.add_child(sfondo)
	var margine = MarginContainer.new()
	margine.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lato in ["left", "right", "top", "bottom"]:
		margine.add_theme_constant_override("margin_" + lato, 14)
	strato_crea.add_child(margine)
	var v = VBoxContainer.new()
	margine.add_child(v)
	var testa = HBoxContainer.new()
	v.add_child(testa)
	var t = Widget.titolo("Il gruppo di avventurieri", 34)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	testa.add_child(t)
	var b_ind = Widget.bottone("Indietro", mostra_menu)
	b_ind.size_flags_horizontal = Control.SIZE_SHRINK_END
	b_ind.custom_minimum_size.x = 120
	testa.add_child(b_ind)
	var corpo = VBoxContainer.new()
	corpo.add_theme_constant_override("separation", 10)
	v.add_child(Widget.scorrevole(corpo))
	corpo.add_child(Widget.etichetta("In solitario guidi tre Eroi, pescati a caso fra i 23 della Lega, e tre Iniziati che crei tu (4.1). Gli Eroi si pescano coperti: puoi ripescare o, come variante, sceglierli liberamente.", 16, Color(0.85, 0.8, 0.7)))
	# Eroi
	var he = HBoxContainer.new()
	corpo.add_child(he)
	var le = Widget.etichetta("Eroi", 24, Risorse.COL_ORO, "Titoli")
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	he.add_child(le)
	var _cb1 = func():
		_eroi_scelti = _pesca_eroi()
		_ridisegna_crea()
	var b1 = Widget.bottone("Ripesca tre Eroi", _cb1)
	b1.size_flags_horizontal = Control.SIZE_SHRINK_END
	b1.custom_minimum_size.x = 190
	he.add_child(b1)
	var _cb2 = func():
		_scelta_libera = not _scelta_libera
		_ridisegna_crea()
	var b2 = Widget.bottone("Scegli tu" if not _scelta_libera else "Mostra solo i pescati", _cb2)
	b2.size_flags_horizontal = Control.SIZE_SHRINK_END
	b2.custom_minimum_size.x = 190
	he.add_child(b2)
	var griglia = GridContainer.new()
	var largh = size.x - 40
	griglia.columns = clampi(int(largh / 300), 1, 4) if _scelta_libera else clampi(int(largh / 300), 1, 3)
	griglia.add_theme_constant_override("h_separation", 10)
	griglia.add_theme_constant_override("v_separation", 10)
	corpo.add_child(griglia)
	var elenco = []
	if _scelta_libera:
		for e in D.EROI: elenco.append(e["id"])
	else:
		elenco = _eroi_scelti
	for id in elenco:
		griglia.add_child(_carta_eroe(id))
	# Iniziati
	corpo.add_child(Widget.etichetta("Iniziati", 24, Risorse.COL_ORO, "Titoli"))
	corpo.add_child(Widget.etichetta("Elfo: 5 PF, Resistenza 2, +1 con l'arco, +1 Negoziazione · Nano: 6 PF, Resistenza 2, +1 con l'ascia, Disinnesco 1 · Umano: 7 PF, Resistenza 1, +1 con la spada, 1 contro la Porta. Il Potenziale Magico si tira sulla Tabella 4.4.", 15, Color(0.85, 0.8, 0.7)))
	for i in _iniziati.size():
		corpo.add_child(_riga_iniziato(i))
	# avvio
	var fondo = HBoxContainer.new()
	v.add_child(fondo)
	var info = Widget.etichetta("Eroi scelti: %d di 3" % _eroi_scelti.size(), 16, Risorse.COL_ORO)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fondo.add_child(info)
	var bv = Widget.bottone("Entra nella Cittadella", _avvia_da_crea, 20)
	bv.disabled = _eroi_scelti.size() != 3
	bv.custom_minimum_size = Vector2(260, 48)
	bv.size_flags_horizontal = Control.SIZE_SHRINK_END
	fondo.add_child(bv)

func _carta_eroe(id: String) -> Control:
	var e: Dictionary = D.eroe(id)
	var p = Widget.pannello(Color(0.1, 0.06, 0.05, 0.95), Risorse.COL_ORO if id in _eroi_scelti else Color(0.4, 0.3, 0.2))
	p.custom_minimum_size = Vector2(280, 0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h = HBoxContainer.new()
	p.add_child(h)
	h.add_child(Widget.ritratto("h_" + id, 92))
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	v.add_child(Widget.etichetta(e["nome"], 19, Risorse.COL_ORO, "grassetto"))
	v.add_child(Widget.etichetta(e["razza"], 14, Color(0.8, 0.75, 0.65)))
	var armi = []
	for a in e["armi"]:
		var ab = int(e["abil"].get(a, 0))
		armi.append(D.nome_arma(a) + ((" +%d" % ab) if ab > 0 else ""))
	var abil = ""
	if e.has("hellgate"): abil = "Porta %d" % e["hellgate"]
	if e.has("disinnesco"): abil = "Disinnesco %d" % e["disinnesco"]
	if e.has("negoziazione"): abil = "Negoziazione +%d" % e["negoziazione"]
	v.add_child(Widget.etichetta("PF %d · PM %d/%d/%d · VR %d · BC %d" % [e["pf"], e["pm"][0], e["pm"][1], e["pm"][2], e["vr"], e["bc"]], 14))
	v.add_child(Widget.etichetta(", ".join(armi) + " · " + abil, 14))
	if max(e["pm"][0], max(e["pm"][1], e["pm"][2])) > 0 and id in _eroi_scelti:
		var b = Widget.bottone("Incantesimi (%d)" % _n_inc(id, e["pm"]), func(): _scegli_incantesimi_crea(id, e["pm"]), 14)
		b.custom_minimum_size.y = 30
		v.add_child(b)
	if _scelta_libera:
		var _cb3 = func():
			if id in _eroi_scelti:
				_eroi_scelti.erase(id)
			elif _eroi_scelti.size() < 3:
				_eroi_scelti.append(id)
			_ridisegna_crea()
		var sel = Widget.bottone("Togli dal gruppo" if id in _eroi_scelti else "Prendi nel gruppo", _cb3, 14)
		sel.custom_minimum_size.y = 30
		v.add_child(sel)
	return p

func _n_inc(id: String, pm: Array) -> int:
	return int(max(pm[0], max(pm[1], pm[2])))

func _riga_iniziato(i: int) -> Control:
	var ini: Dictionary = _iniziati[i]
	var p = Widget.pannello(Color(0.1, 0.06, 0.05, 0.95), Color(0.4, 0.3, 0.2))
	var h = HFlowContainer.new()
	h.add_theme_constant_override("h_separation", 8)
	h.add_theme_constant_override("v_separation", 6)
	p.add_child(h)
	h.add_child(Widget.ritratto("i_%s_%s" % [ini["razza"], "f" if ini["femmina"] else "m"], 64))
	var nomev = LineEdit.new()
	nomev.text = ini["nome"]
	nomev.custom_minimum_size = Vector2(150, 36)
	nomev.text_changed.connect(func(t): _iniziati[i]["nome"] = t)
	h.add_child(nomev)
	var razza = OptionButton.new()
	for r in ["elfo", "nano", "umano"]:
		razza.add_item(D.RAZZE_INIZIATI[r]["nome"])
	razza.selected = ["elfo", "nano", "umano"].find(ini["razza"])
	razza.custom_minimum_size = Vector2(110, 36)
	var _cb4 = func(k):
		_iniziati[i]["razza"] = ["elfo", "nano", "umano"][k]
		_ridisegna_crea()
	razza.item_selected.connect(_cb4)
	h.add_child(razza)
	var sesso = OptionButton.new()
	sesso.add_item("Uomo")
	sesso.add_item("Donna")
	sesso.selected = 1 if ini["femmina"] else 0
	sesso.custom_minimum_size = Vector2(100, 36)
	var _cb5 = func(k):
		_iniziati[i]["femmina"] = k == 1
		_ridisegna_crea()
	sesso.item_selected.connect(_cb5)
	h.add_child(sesso)
	var arma2 = OptionButton.new()
	var armi = ["pugnale", "pugnale_lancio", "spada", "arco", "ascia", "martello"]
	for a in armi:
		arma2.add_item("Seconda arma: " + D.nome_arma(a))
	arma2.selected = maxi(0, armi.find(ini["arma2"]))
	arma2.custom_minimum_size = Vector2(240, 36)
	arma2.item_selected.connect(func(k): _iniziati[i]["arma2"] = armi[k])
	h.add_child(arma2)
	var esp = OptionButton.new()
	var esps = ["pf", "arma", "abilita"]
	esp.add_item("Esperienza: +1 Punto Ferita")
	esp.add_item("Esperienza: +1 con l'arma della razza")
	esp.add_item("Esperienza: +1 all'abilità della razza")
	esp.selected = esps.find(ini["esperienza"])
	esp.custom_minimum_size = Vector2(300, 36)
	esp.item_selected.connect(func(k): _iniziati[i]["esperienza"] = esps[k])
	h.add_child(esp)
	var pm: Array = D.POTENZIALE[int(ini["tiro_pm"]) - 1]
	var lp = Widget.etichetta("Potenziale Magico (tiro %d): %d/%d/%d" % [int(ini["tiro_pm"]), pm[0], pm[1], pm[2]], 15, Risorse.COL_ORO)
	lp.custom_minimum_size = Vector2(250, 36)
	lp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(lp)
	var id = "ini%d" % (i + 1)
	if _n_inc(id, pm) > 0:
		var b = Widget.bottone("Incantesimi (%d)" % _n_inc(id, pm), func(): _scegli_incantesimi_crea(id, pm), 14)
		b.custom_minimum_size = Vector2(150, 36)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		h.add_child(b)
	return p

func _scegli_incantesimi_crea(id: String, pm: Array) -> void:
	var n = _n_inc(id, pm)
	if not _inc_scelti.has(id):
		_inc_scelti[id] = motore.incantesimi_consigliati({}, n)
	var v = VBoxContainer.new()
	v.add_child(Widget.etichetta("Scegli %d incantesimi (4.1 B6). Ad ogni spedizione il sole dominante deciderà quanti potrai usarne." % n, 16))
	var g = GridContainer.new()
	g.columns = 2 if size.x < 900 else 3
	v.add_child(g)
	for k in D.INCANTESIMI_ORDINE:
		var inc: Dictionary = D.INCANTESIMI[k]
		var cb = CheckBox.new()
		cb.text = "%s (%d PF, %s)" % [inc["nome"], inc["costo"], D.TIPI_INCANTESIMO[inc["tipo"]].to_lower()]
		cb.tooltip_text = inc["testo"]
		cb.button_pressed = k in _inc_scelti[id]
		cb.focus_mode = Control.FOCUS_NONE
		var _cb6 = func(on):
			var l: Array = _inc_scelti[id]
			if on and not k in l:
				if l.size() >= n:
					cb.set_pressed_no_signal(false)
					return
				l.append(k)
			elif not on:
				l.erase(k)
		cb.toggled.connect(_cb6)
		g.add_child(cb)
	finestra("Incantesimi", v, 900)

func _avvia_da_crea() -> void:
	var cfg = {"seme": _rng_crea.randi(), "eroi": _eroi_scelti.duplicate(), "iniziati": [], "incantesimi": {}}
	for i in _iniziati.size():
		cfg["iniziati"].append(_iniziati[i].duplicate())
	for id in _inc_scelti:
		cfg["incantesimi"][id] = _inc_scelti[id]
	tutorial = null
	motore = Motore.new()
	motore.nuova_partita(cfg)
	_entra_in_gioco()

func continua() -> void:
	var f = FileAccess.open(FILE_SALVA, FileAccess.READ)
	if f == null: return
	motore = Motore.new()
	if not motore.importa(f.get_as_text()):
		return
	tutorial = null
	_entra_in_gioco()

func avvia_tutorial() -> void:
	motore = Motore.new()
	tutorial = Tutorial.new()
	tutorial.avvia(motore)
	_entra_in_gioco()

func _entra_in_gioco() -> void:
	strato_menu.visible = false
	strato_crea.visible = false
	strato_gioco.visible = true
	vista.motore = motore
	tavola.motore = motore
	vista.livello_mostrato = -1
	vista.ricostruisci()
	vista.centra_su(int(motore.s["pos"]["liv"]), motore.s["pos"]["xy"])
	_recenti = []
	for e in motore.s.get("diario", []).slice(-6):
		_recenti.append({"t": e["t"], "k": e["k"]})
	motore.eventi.clear()
	aggiorna()

# ============================================================================================
# Schermata di gioco
# ============================================================================================
func _costruisci_gioco() -> void:
	barra_alta = Widget.pannello(Color(0.06, 0.03, 0.03, 0.9), Color(0.5, 0.36, 0.18))
	strato_gioco.add_child(barra_alta)
	var h = HBoxContainer.new()
	barra_alta.add_child(h)
	var t = Widget.titolo("Citadel of Blood", 26)
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.custom_minimum_size.x = 190
	h.add_child(t)
	lbl_info = Widget.etichetta("", 15, Risorse.COL_PERGAMENA)
	lbl_info.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl_info.clip_text = true
	lbl_info.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(lbl_info)
	for coppia in [["Centra", func(): vista.ricentra()], ["Ordine", _apri_ordine], ["Diario", _apri_diario],
			["Regole", func(): apri_regole()], ["Tabelle", func(): apri_tabelle()], ["Menu", _torna_menu]]:
		var b = Widget.bottone(coppia[0], coppia[1], 15)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.custom_minimum_size = Vector2(74, 34)
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		h.add_child(b)
	col_sinistra = Widget.pannello(Color(0.06, 0.03, 0.03, 0.82), Color(0.45, 0.32, 0.16))
	strato_gioco.add_child(col_sinistra)
	box_gruppo = VBoxContainer.new()
	box_gruppo.add_theme_constant_override("separation", 6)
	col_sinistra.add_child(Widget.scorrevole(box_gruppo))
	tavola = Tavola.new()
	strato_gioco.add_child(tavola)
	tavola.carta_premuta.connect(_carta_premuta)
	tavola.posto_premuto.connect(_posto_premuto)
	pan_azioni = Widget.pannello(Color(0.07, 0.04, 0.04, 0.93), Color(0.62, 0.45, 0.22))
	strato_gioco.add_child(pan_azioni)
	box_azioni = VBoxContainer.new()
	box_azioni.add_theme_constant_override("separation", 6)
	pan_azioni.add_child(Widget.scorrevole(box_azioni))
	pan_diario = Widget.pannello(Color(0.06, 0.03, 0.03, 0.95), Color(0.5, 0.36, 0.18))
	pan_diario.visible = false
	strato_gioco.add_child(pan_diario)
	var vd = VBoxContainer.new()
	pan_diario.add_child(vd)
	var hd = HBoxContainer.new()
	vd.add_child(hd)
	var td = Widget.titolo("Diario", 26)
	td.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(td)
	var bc = Widget.bottone("Chiudi", func(): pan_diario.visible = false, 15)
	bc.size_flags_horizontal = Control.SIZE_SHRINK_END
	bc.custom_minimum_size.x = 90
	hd.add_child(bc)
	txt_diario = RichTextLabel.new()
	txt_diario.bbcode_enabled = true
	txt_diario.scroll_following = true
	txt_diario.size_flags_vertical = Control.SIZE_EXPAND_FILL
	txt_diario.add_theme_font_size_override("normal_font_size", 15)
	txt_diario.add_theme_font_size_override("bold_font_size", 15)
	vd.add_child(txt_diario)
	crt = TabellaCRT.new()
	strato_gioco.add_child(crt)
	pan_tutorial = Widget.pannello(Color(0.12, 0.08, 0.03, 0.96), Color(0.95, 0.78, 0.4))
	pan_tutorial.visible = false
	strato_gioco.add_child(pan_tutorial)

func _scala_schermo() -> void:
	## sugli schermi bassi (telefono in orizzontale) l'interfaccia resta leggibile
	var win = get_window()
	if win == null: return
	var reale = DisplayServer.window_get_size()
	var voluta = Vector2i(1280, 800)
	if reale.y > 0 and reale.y < 560:
		voluta = Vector2i(900, 520)
	elif reale.y > 0 and reale.y < 700:
		voluta = Vector2i(1100, 680)
	if win.content_scale_size != voluta:
		win.content_scale_size = voluta

func _layout() -> void:
	var W = size.x
	var H = size.y
	_compatto = W < 1100 or H < 700
	var piccolo = H < 520
	if strato_menu.visible and strato_menu.get_child_count() > 0 and _modo_prova == "":
		pass
	var hb = 46.0 if not piccolo else 40.0
	barra_alta.position = Vector2(0, 0)
	barra_alta.size = Vector2(W, hb)
	var ws = clampf(W * 0.21, 190, 290)
	if piccolo: ws = 170
	var wd = clampf(W * 0.31, 300, 440)
	if piccolo: wd = clampf(W * 0.36, 260, 320)
	# in combattimento (o incontro, o ordine di marcia) la colonna sinistra diventa la tavola:
	# mostri e gruppo schierati per file, senza coprire il labirinto al centro
	var tav_on = tavola != null and tavola.visible
	if tav_on:
		ws = clampf(W * 0.27, 250, 380)
		if piccolo: ws = clampf(W * 0.3, 240, 280)
	col_sinistra.position = Vector2(6, hb + 6)
	col_sinistra.size = Vector2(ws, H - hb - 12)
	if col_sinistra.get_child_count() > 0:
		col_sinistra.get_child(0).visible = not tav_on
	pan_azioni.position = Vector2(W - wd - 6, hb + 6)
	pan_azioni.size = Vector2(wd, H - hb - 12)
	var cx = ws + 16
	var cw = W - ws - wd - 32
	tavola.position = Vector2(14, hb + 12)
	tavola.size = Vector2(ws - 16, H - hb - 24)
	pan_diario.position = Vector2(cx, hb + 6)
	pan_diario.size = Vector2(cw, H - hb - 12)
	if tutorial != null and pan_tutorial.visible:
		var th = clampf(H * 0.36, 170, 300)
		pan_tutorial.position = Vector2(cx, H - th - 6)
		pan_tutorial.size = Vector2(cw, th)
	var wt = minf(cw - 16, 560.0)
	crt.size = Vector2(wt, wt * 0.66)
	crt.position = Vector2(cx + (cw - wt) / 2, hb + 116)
	dadi.position = Vector2((W - 420) / 2, hb + 10)
	dadi.size = Vector2(420, 100)
	for b in barra_alta.get_child(0).get_children():
		if b is Button:
			b.visible = not piccolo or b.text in ["Ordine", "Regole", "Menu", "Diario"]
	if lbl_info: lbl_info.visible = W > 900
	for c in strato_finestre.get_children():
		if c.has_meta("finestra"):
			_dimensiona_finestra(c)
	if tavola: tavola.aggiorna()

## Aggiorna tutto dopo un'azione del motore
func aggiorna() -> void:
	if motore.s.is_empty(): return
	_consuma_eventi()
	_aggiorna_info()
	_aggiorna_gruppo()
	_aggiorna_azioni()
	_aggiorna_tavola()
	vista.ricostruisci()
	_aggiorna_frecce()
	_salva()
	if tutorial != null:
		tutorial.dopo_aggiornamento(self)
	_layout()

func _consuma_eventi() -> void:
	for e in motore.eventi:
		match e["tipo"]:
			"dadi":
				_coda_dadi.append(e)
			"attacco":
				_coda_crt.append(e)
			"log":
				_recenti.append({"t": e["testo"], "k": e["k"]})
				if _recenti.size() > 40: _recenti.remove_at(0)
			"danno", "morte":
				vista.colpo(e["uid"])
			"muovi", "tessera":
				vista.ricostruisci()
				vista.centra_su(int(motore.s["pos"]["liv"]), motore.s["pos"]["xy"])
			"anteprima":
				_anteprima = e
	motore.eventi.clear()
	if motore.s.get("scelta", {}).get("tipo", "") == "orienta" and not _anteprima.is_empty():
		vista.mostra_anteprima(int(_anteprima["liv"]), _anteprima["xy"], int(_anteprima["t"]), _anteprima["lato"], int(_anteprima["rot"][0]))
	else:
		vista.togli_anteprima()
		_anteprima = {}

func _process(delta: float) -> void:
	_t_crt -= delta
	if _t_crt <= 0 and not _coda_crt.is_empty():
		# la tabella mostra un attacco alla volta: riga del totale × colonna dell'arma
		while _coda_crt.size() > 6: _coda_crt.remove_at(0)
		var ec = _coda_crt.pop_front()
		var dur = 1.8 if not _coda_crt.is_empty() else 4.0
		crt.mostra(ec, dur)
		_t_crt = dur - 0.2 if not _coda_crt.is_empty() else 1.6
	_t_dadi -= delta
	if _t_dadi <= 0 and not _coda_dadi.is_empty():
		# mostra gli ultimi tiri, uno dopo l'altro
		while _coda_dadi.size() > 4: _coda_dadi.remove_at(0)
		var e = _coda_dadi.pop_front()
		dadi.mostra(e["valori"], e["testo"])
		_t_dadi = 0.9 if not _coda_dadi.is_empty() else 0.2

func _aggiorna_info() -> void:
	var s = motore.s
	var hg: Dictionary = s["hellgate"]
	var porta = "Porta dell'Inferno: sconosciuta"
	if hg["distrutta"]: porta = "Porta dell'Inferno: distrutta!"
	elif hg["trovata"]: porta = "Porta dell'Inferno: trovata"
	elif int(hg["liv"]) > 0:
		porta = "Porta: livello %d" % int(hg["liv"])
		if int(hg["conto"]) > 0: porta += ", fra %d segmenti nuovi" % int(hg["conto"])
	lbl_info.text = "Spedizione %d · Turno %d · Livello %d · %s · %s" % [int(s["spedizione"]), int(s["turno"]), int(s["pos"]["liv"]), D.NOMI_SOLI[s["sole"]], porta]

func _aggiorna_gruppo() -> void:
	Widget.svuota(box_gruppo)
	var tit = Widget.etichetta("Il gruppo", 22, Risorse.COL_ORO, "Titoli")
	box_gruppo.add_child(tit)
	for id in motore.s["ordine_ids"]:
		box_gruppo.add_child(_carta_pg(id))
	for k in motore.s.get("alleati", {}):
		var m: Dictionary = motore.s["alleati"][k]
		var l = Widget.etichetta("Alleato: %s (PF %d/%d)" % [m["nome"], motore.pf_residui(m), int(m["pf_max"])], 14, Color(0.7, 0.85, 0.7))
		box_gruppo.add_child(l)

func _carta_pg(id: String) -> Control:
	var p: Dictionary = motore.pg(id)
	var stato: String = p.get("stato", "ok")
	var bordo = Color(0.45, 0.33, 0.18)
	var cs: Dictionary = motore.s.get("scelta", {})
	if cs.get("chi", "") == "p:" + id: bordo = Color(0.5, 0.9, 1.0)
	var pan = Widget.pannello(Color(0.1, 0.06, 0.05, 0.95), bordo)
	var btn = Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(func(): apri_scheda(id))
	var h = HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pan.add_child(h)
	var lato = 54 if not _compatto else 44
	var img = Widget.ritratto(p.get("ritratto", ""), lato)
	if stato != "ok": img.modulate = Color(0.45, 0.45, 0.5)
	h.add_child(img)
	var v = VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var nome = Widget.etichetta(p["nome"], 15, Risorse.COL_ORO, "grassetto")
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	nome.clip_text = true
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nome)
	var pf = motore.pf_residui(p)
	var mx = int(p["pf_max"]) + int(p.get("pf_armatura", 0))
	var testo_stato = {"ok": "", "morto": "caduto", "pietra": "pietrificato", "incantato": "incantato", "posseduto": "posseduto", "prigioniero": "prigioniero della Porta"}.get(stato, stato)
	if stato == "ok":
		v.add_child(Widget.barra(float(pf), float(mx), Color(0.3, 0.68, 0.3), 80, 7))
		var a = motore.arma(p)
		var info = Widget.etichetta("PF %d/%d · %s · BC %d" % [pf, mx, D.nome_arma(a["tipo"]), motore.bc_totale(p)], 13)
		info.autowrap_mode = TextServer.AUTOWRAP_OFF
		info.clip_text = true
		info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(info)
		if not p.get("inc_attivi", []).is_empty() and not _compatto:
			var nomi = []
			for k in p["inc_attivi"]: nomi.append(D.INCANTESIMI[k]["nome"])
			var li = Widget.etichetta(", ".join(nomi), 12, Color(0.7, 0.75, 0.95))
			li.autowrap_mode = TextServer.AUTOWRAP_OFF
			li.clip_text = true
			li.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(li)
	else:
		var ls = Widget.etichetta(testo_stato, 13, Color(0.85, 0.4, 0.35))
		ls.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(ls)
	pan.add_child(btn)
	return pan

func _aggiorna_tavola() -> void:
	var c: Dictionary = motore.s.get("comb", {})
	var mostra = (not c.is_empty() and c.get("esito", "") == "") or not motore.s.get("incontro", {}).get("mostri", {}).is_empty() or modalita_ordine
	tavola.visible = mostra and not pan_diario.visible
	tavola.evidenziati = {}
	tavola.posti_validi = []
	tavola.attore = ""
	var sc: Dictionary = motore.s.get("scelta", {})
	if sc.get("tipo", "") == "azione":
		tavola.attore = sc["chi"]
		tavola.titolo = "Round %d · fase del gruppo" % int(c.get("round", 1))
		if modalita_bersaglio != "":
			for o in sc["opzioni"]:
				if o["azione"] == modalita_bersaglio and o.get("bersaglio", "") != "":
					tavola.evidenziati[o["bersaglio"]] = true
	elif sc.get("tipo", "") == "riorg":
		tavola.titolo = "Riorganizzazione: tocca un personaggio e poi un posto libero"
		if tavola.selezionato != "":
			for o in sc["opzioni"]:
				if o["azione"] == "sposta" and o["bersaglio"] == tavola.selezionato:
					tavola.posti_validi.append(Vector2i(int(o["a"][0]), int(o["a"][1])))
	elif modalita_ordine:
		tavola.titolo = "Ordine di marcia: tocca un personaggio e poi il posto dove spostarlo"
		if tavola.selezionato != "":
			for r in 3:
				for col in 3:
					if motore.s["ordine"][r][col] == "": tavola.posti_validi.append(Vector2i(col, r))
	elif not c.is_empty():
		tavola.titolo = "Combattimento"
	else:
		tavola.titolo = "Incontro"
	tavola.aggiorna()

func _aggiorna_frecce() -> void:
	var sc: Dictionary = motore.s.get("scelta", {})
	var dirs = []
	if sc.get("tipo", "") == "rotta":
		for o in sc["opzioni"]:
			if o.has("dir") and not int(o["dir"]) in dirs: dirs.append(int(o["dir"]))
	vista.mostra_uscite(dirs)

# --------------------------------------------------------------------------------------------
# Pannello delle azioni
# --------------------------------------------------------------------------------------------
func _aggiorna_azioni() -> void:
	Widget.svuota(box_azioni)
	var sc: Dictionary = motore.s.get("scelta", {})
	var dim = 16 if not _compatto else 14
	# che cosa è appena successo
	if not _recenti.is_empty():
		var bb = ""
		for e in _recenti.slice(-8):
			bb += _colora(e["t"], e["k"]) + "\n"
		var r = Widget.testo_ricco(bb.strip_edges(), dim - 2)
		box_azioni.add_child(r)
		box_azioni.add_child(HSeparator.new())
	if sc.is_empty():
		if motore.s.get("fine", "") != "":
			box_azioni.add_child(Widget.etichetta("Partita conclusa.", dim + 2, Risorse.COL_ORO, "grassetto"))
			box_azioni.add_child(Widget.bottone("Torna al menu", _torna_menu, dim))
		return
	var testo = Widget.etichetta(sc.get("testo", ""), dim + 2, Risorse.COL_ORO, "grassetto")
	box_azioni.add_child(testo)
	match sc["tipo"]:
		"soli":
			_azioni_soli(sc, dim)
		"azione":
			_azioni_combattimento(sc, dim)
		"riorg":
			_azioni_riorg(sc, dim)
		"fine":
			for o in sc["opzioni"]:
				box_azioni.add_child(Widget.bottone(o["testo"], func(): mostra_crea(), dim))
			box_azioni.add_child(Widget.bottone("Torna al menu", _torna_menu, dim))
		_:
			_azioni_generiche(sc, dim)
	_azioni_fuori_combattimento(dim)

func _colora(t: String, k: String) -> String:
	var tt = t.replace("[", "(").replace("]", ")")
	match k:
		"titolo": return "[b][color=#e6c37a]%s[/color][/b]" % tt
		"comb": return "[color=#f0a080]%s[/color]" % tt
		"morte": return "[color=#ff7060]%s[/color]" % tt
		"magia": return "[color=#a8b8ff]%s[/color]" % tt
		"tesoro": return "[color=#f2d16b]%s[/color]" % tt
		"evento": return "[color=#ffd9a0]%s[/color]" % tt
		"dado": return "[color=#cfc3b0]%s[/color]" % tt
	return tt

func _azioni_generiche(sc: Dictionary, dim: int) -> void:
	var gruppi = []
	var per = {}
	for o in sc["opzioni"]:
		var g: String = o.get("gruppo", "")
		if not per.has(g):
			per[g] = []
			gruppi.append(g)
		per[g].append(o)
	for g in gruppi:
		if g != "" and gruppi.size() > 1:
			box_azioni.add_child(Widget.etichetta(g, dim - 2, Color(0.75, 0.65, 0.5), "Maiuscoletto"))
		for o in per[g]:
			var b = Widget.bottone(o["testo"], func(): _scegli(o["id"]), dim)
			b.set_meta("id_opzione", o["id"])
			if sc["tipo"] == "orienta":
				var _cb7 = func():
					if not _anteprima.is_empty():
						vista.mostra_anteprima(int(_anteprima["liv"]), _anteprima["xy"], int(_anteprima["t"]), _anteprima["lato"], int(o["rot"]))
				b.mouse_entered.connect(_cb7)
			box_azioni.add_child(b)

func _azioni_soli(sc: Dictionary, dim: int) -> void:
	var sel = {}
	for id in sc["maghi"]:
		var p: Dictionary = motore.pg(id)
		var n = motore.pm_sole(p)
		sel[id] = []
		for k in p["inc_noti"]:
			if sel[id].size() < n: sel[id].append(k)
		box_azioni.add_child(Widget.etichetta("%s: %d su %d" % [p["nome"], n, p["inc_noti"].size()], dim, Risorse.COL_ORO, "grassetto"))
		for k in p["inc_noti"]:
			var cb = CheckBox.new()
			cb.text = "%s (%d PF)" % [D.INCANTESIMI[k]["nome"], int(D.INCANTESIMI[k]["costo"])]
			cb.tooltip_text = D.INCANTESIMI[k]["testo"]
			cb.button_pressed = k in sel[id]
			cb.focus_mode = Control.FOCUS_NONE
			cb.add_theme_font_size_override("font_size", dim - 1)
			var _cb8 = func(on):
				var l: Array = sel[id]
				if on and not k in l:
					if l.size() >= n:
						cb.set_pressed_no_signal(false)
						return
					l.append(k)
				elif not on:
					l.erase(k)
			cb.toggled.connect(_cb8)
			box_azioni.add_child(cb)
	var bok = Widget.bottone("Conferma ed entra", func(): _scegli("ok", {"selezione": sel}), dim)
	bok.set_meta("id_opzione", "ok")
	box_azioni.add_child(bok)

func _azioni_combattimento(sc: Dictionary, dim: int) -> void:
	var u = motore.unita(sc["chi"])
	var pos = motore.fila_di(motore.ordine_gruppo(), sc["chi"])
	box_azioni.add_child(Widget.etichetta("Fila %d · arma: %s" % [pos.y + 1, D.nome_arma(motore.arma(u)["tipo"]) if sc["chi"].begins_with("p:") else "naturale"], dim - 1, Color(0.85, 0.8, 0.7)))
	if modalita_bersaglio != "":
		box_azioni.add_child(Widget.etichetta("Scegli il bersaglio sulla tavola (riquadri dorati) o qui:", dim - 1))
		for o in sc["opzioni"]:
			if o["azione"] == modalita_bersaglio:
				var bt = Widget.bottone(o["testo"], func(): _scegli(o["id"]), dim)
				bt.set_meta("id_opzione", o["id"])
				box_azioni.add_child(bt)
		var _cb9 = func():
			modalita_bersaglio = ""
			aggiorna()
		box_azioni.add_child(Widget.bottone("Annulla", _cb9, dim))
		return
	var azioni = []
	var per = {}
	for o in sc["opzioni"]:
		var a: String = o["azione"]
		if not per.has(a):
			per[a] = []
			azioni.append(a)
		per[a].append(o)
	for a in azioni:
		var lista: Array = per[a]
		if lista.size() == 1:
			var o = lista[0]
			var b1 = Widget.bottone(o["testo"], func(): _scegli(o["id"]), dim)
			b1.set_meta("id_opzione", o["id"])
			box_azioni.add_child(b1)
		else:
			var etichetta = _nome_azione(a, lista[0])
			var _cb10 = func():
				modalita_bersaglio = a
				aggiorna()
			var bg = Widget.bottone(etichetta + " (scegli il bersaglio)", _cb10, dim)
			bg.set_meta("azione", a)
			box_azioni.add_child(bg)

func _nome_azione(a: String, o: Dictionary) -> String:
	match a:
		"attacca": return "Attacca"
		"arco": return "Scocca una freccia"
		"lancia": return "Lancia il pugnale"
		"talismano": return "Talismano della Mente"
		"anello_sonno": return "Anello del Sonno"
	if a.begins_with("inc_"):
		var k = a.substr(4)
		return "%s (%d PF)" % [D.INCANTESIMI[k]["nome"], motore.costo_incantesimo(motore.unita(motore.s["scelta"]["chi"]), k)]
	return o["testo"]

func _azioni_riorg(sc: Dictionary, dim: int) -> void:
	box_azioni.add_child(Widget.etichetta("Un solo spostamento per round (9.8): stessa fila senza scavalcare, oppure una fila avanti o indietro, anche in diagonale.", dim - 2, Color(0.85, 0.8, 0.7)))
	for o in sc["opzioni"]:
		if o["azione"] != "sposta":
			var br = Widget.bottone(o["testo"], func(): _scegli(o["id"]), dim)
			br.set_meta("id_opzione", o["id"])
			box_azioni.add_child(br)
	var mostra = Button.new()
	var elenco = VBoxContainer.new()
	elenco.visible = false
	mostra.text = "Mostra tutti gli spostamenti possibili"
	mostra.focus_mode = Control.FOCUS_NONE
	mostra.pressed.connect(func(): elenco.visible = not elenco.visible)
	box_azioni.add_child(mostra)
	box_azioni.add_child(elenco)
	for o in sc["opzioni"]:
		if o["azione"] == "sposta":
			elenco.add_child(Widget.bottone(o["testo"], func(): _scegli(o["id"]), dim - 2))

func _azioni_fuori_combattimento(dim: int) -> void:
	if not motore.puo_agire_fuori_combattimento(): return
	var cose = []
	for id in motore.pg_in_gruppo():
		for x in motore.incantesimi_fuori(id):
			cose.append(id)
			break
		if not motore.oggetti_usabili(id).is_empty() and not id in cose:
			cose.append(id)
	if cose.is_empty(): return
	box_azioni.add_child(HSeparator.new())
	box_azioni.add_child(Widget.etichetta("Fuori dal combattimento puoi curarti e usare oggetti: tocca la scheda di un personaggio (a sinistra).", dim - 3, Color(0.7, 0.75, 0.95)))

func _carta_premuta(uid: String) -> void:
	var sc: Dictionary = motore.s.get("scelta", {})
	if tutorial_blocca(): return
	if sc.get("tipo", "") == "azione" and modalita_bersaglio != "":
		for o in sc["opzioni"]:
			if o["azione"] == modalita_bersaglio and o.get("bersaglio", "") == uid:
				_scegli(o["id"])
				return
		return
	if sc.get("tipo", "") == "azione" and modalita_bersaglio == "":
		# tocco diretto su un bersaglio: se una sola azione lo prevede, la esegue
		var trovate = []
		for o in sc["opzioni"]:
			if o.get("bersaglio", "") == uid: trovate.append(o)
		if trovate.size() >= 1 and trovate[0]["azione"] in ["attacca", "arco", "lancia"]:
			_scegli(trovate[0]["id"])
			return
	if sc.get("tipo", "") == "riorg" or modalita_ordine:
		if uid.begins_with("p:") or uid.begins_with("m:"):
			if modalita_ordine and tavola.selezionato != "" and tavola.selezionato != uid:
				var pos = motore.fila_di(motore.s["ordine"], uid)
				motore.sposta_fuori(tavola.selezionato, pos.x, pos.y)
				tavola.selezionato = ""
				aggiorna()
				return
			tavola.selezionato = uid if tavola.selezionato != uid else ""
			_aggiorna_tavola()
			return
	if uid.begins_with("p:"):
		apri_scheda(uid.substr(2))
	elif uid.begins_with("m:"):
		apri_scheda_mostro(uid)

func _posto_premuto(col: int, riga: int) -> void:
	var sc: Dictionary = motore.s.get("scelta", {})
	if sc.get("tipo", "") == "riorg":
		for o in sc["opzioni"]:
			if o["azione"] == "sposta" and o["bersaglio"] == tavola.selezionato and int(o["a"][0]) == col and int(o["a"][1]) == riga:
				tavola.selezionato = ""
				_scegli(o["id"])
				return
	elif modalita_ordine and tavola.selezionato != "":
		motore.sposta_fuori(tavola.selezionato, col, riga)
		tavola.selezionato = ""
		aggiorna()

func _scegli(id: String, extra: Dictionary = {}) -> void:
	if tutorial != null and not tutorial.consenti(id):
		tutorial.avvisa(self)
		return
	modalita_bersaglio = ""
	tavola.selezionato = ""
	_recenti = []
	motore.scegli(id, extra)
	aggiorna()

func tutorial_blocca() -> bool:
	return tutorial != null and tutorial.blocca_tocchi()

func _salva() -> void:
	if tutorial != null or _modo_prova != "": return
	var f = FileAccess.open(FILE_SALVA, FileAccess.WRITE)
	if f:
		f.store_string(motore.esporta())

func _torna_menu() -> void:
	chiudi_finestre()
	pan_diario.visible = false
	pan_tutorial.visible = false
	modalita_ordine = false
	tutorial = null
	mostra_menu()

func _apri_ordine() -> void:
	if motore.in_combattimento():
		return
	modalita_ordine = not modalita_ordine
	tavola.selezionato = ""
	aggiorna()

func _apri_diario() -> void:
	pan_diario.visible = not pan_diario.visible
	var bb = ""
	for e in motore.s.get("diario", []):
		bb += "[color=#8a7a66]T%d[/color]  %s\n" % [int(e.get("turno", 0)), _colora(e["t"], e["k"])]
	txt_diario.text = bb
	_aggiorna_tavola()

# ============================================================================================
# Finestre: schede, regolamento, tabelle
# ============================================================================================
func finestra(titolo: String, contenuto: Control, larghezza: float = 760, pergamena: bool = false) -> Control:
	var velo = ColorRect.new()
	velo.color = Color(0, 0, 0, 0.6)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.set_meta("finestra", true)
	velo.set_meta("larghezza", larghezza)
	strato_finestre.add_child(velo)
	var p = Widget.pergamena() if pergamena else Widget.pannello(Color(0.08, 0.05, 0.04, 0.98), Risorse.COL_ORO)
	velo.add_child(p)
	var v = VBoxContainer.new()
	p.add_child(v)
	var h = HBoxContainer.new()
	v.add_child(h)
	var t = Widget.titolo(titolo, 30)
	if pergamena:
		t.add_theme_color_override("font_color", Risorse.COL_SANGUE)
		t.add_theme_constant_override("outline_size", 0)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var b = Widget.bottone("Chiudi", func(): velo.queue_free(), 15)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.custom_minimum_size.x = 96
	h.add_child(b)
	v.add_child(Widget.scorrevole(contenuto))
	_dimensiona_finestra(velo)
	strato_finestre.move_child(dadi, -1)
	return velo

func _dimensiona_finestra(velo: Control) -> void:
	var p: Control = velo.get_child(0)
	var w = minf(float(velo.get_meta("larghezza")), size.x - 20)
	var h = size.y - 40
	p.position = Vector2((size.x - w) / 2, 20)
	p.size = Vector2(w, h)

func chiudi_finestre() -> void:
	for c in strato_finestre.get_children():
		if c.has_meta("finestra"):
			c.queue_free()

func apri_scheda(id: String) -> void:
	var p: Dictionary = motore.pg(id)
	if p.is_empty(): return
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var h = HBoxContainer.new()
	v.add_child(h)
	h.add_child(Widget.ritratto(p.get("ritratto", ""), 150 if not _compatto else 110))
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	var ink = Risorse.COL_INCHIOSTRO
	var righe = [
		["Nome", p["nome"]], ["Razza", p["razza"] + (" (Eroe)" if p["tipo"] == "eroe" else " (Iniziato)")],
		["Punti Ferita", "%d su %d%s" % [motore.pf_residui(p), int(p["pf_max"]) + int(p.get("pf_armatura", 0)), (" (+%d armatura)" % int(p["pf_armatura"])) if int(p.get("pf_armatura", 0)) > 0 else ""]],
		["Potenziale Magico", "%d / %d / %d  (rosso / giallo / blu)" % [p["pm"][0], p["pm"][1], p["pm"][2]]],
		["Valore di Resistenza", str(motore.vr_totale(p))],
		["Bonus di Combattimento", str(motore.bc_totale(p))],
	]
	for r in righe:
		col.add_child(_riga_scheda(r[0], r[1], ink))
	var armi = []
	for i in p["armi"].size():
		var a: Dictionary = p["armi"][i]
		var ab = int(p["abil"].get(a["tipo"], 0))
		armi.append("%s%s%s%s" % [D.nome_arma(a["tipo"]), (" magica +%d" % int(a["bonus"])) if int(a.get("bonus", 0)) > 0 else "", (" (abilità +%d)" % ab) if ab > 0 else "", " (impugnata)" if i == int(p.get("arma_att", 0)) else ""])
	v.add_child(_riga_scheda("Armi", "; ".join(armi), ink))
	var abil = []
	if int(p.get("disinnesco", 0)) > 0: abil.append("Disinnesco %d" % int(p["disinnesco"]))
	if int(p.get("hellgate", 0)) > 0: abil.append("contro la Porta %d" % int(p["hellgate"]))
	if int(p.get("negoziazione", 0)) > 0: abil.append("Negoziazione +%d" % int(p["negoziazione"]))
	v.add_child(_riga_scheda("Abilità", ", ".join(abil) if not abil.is_empty() else "nessuna", ink))
	var noti = []
	for k in p.get("inc_noti", []) + p.get("inc_speciali", []):
		var att = k in p.get("inc_attivi", [])
		var extra = ""
		if p.get("usi_cura", {}).has(k): extra = " (%d usi)" % int(p["usi_cura"][k])
		noti.append(("%s%s" % [D.INCANTESIMI[k]["nome"], extra]) + ("" if att else " (non sotto questo sole)"))
	v.add_child(_riga_scheda("Incantesimi", ", ".join(noti) if not noti.is_empty() else "nessuno", ink))
	var ogg = []
	for o in p.get("oggetti", []):
		ogg.append(o.get("nome", "?") + ((" (usato)") if o.get("usato", false) else ""))
	v.add_child(_riga_scheda("Oggetti magici", ", ".join(ogg) if not ogg.is_empty() else "nessuno", ink))
	var gio = []
	for g in p.get("gioielli", []): gio.append(str(g))
	v.add_child(_riga_scheda("Marchi d'oro", str(int(p.get("oro", 0))) + ("  (a casa: %d)" % int(motore.s["casa"].get(id, {}).get("oro", 0)) if motore.s["casa"].has(id) else ""), ink))
	v.add_child(_riga_scheda("Gioielli", ", ".join(gio) if not gio.is_empty() else "nessuno", ink))
	v.add_child(_riga_scheda("Punti esperienza", str(int(p.get("xp", 0))), ink))
	# azioni
	var incs = motore.incantesimi_fuori(id)
	var oggs = motore.oggetti_usabili(id)
	var vel: Control
	if not incs.is_empty() or not oggs.is_empty():
		var tit = Widget.etichetta("Azioni possibili ora", 20, Risorse.COL_SANGUE, "Titoli")
		v.add_child(tit)
		for x in incs:
			var k = x[0]
			for b in x[1]:
				var bp = motore.pg(b)
				var _cb11 = func():
					motore.lancia_fuori(id, k, b)
					chiudi_finestre()
					aggiorna()
				v.add_child(Widget.bottone("%s su %s (%d PF)" % [D.INCANTESIMI[k]["nome"], bp["nome"], motore.costo_incantesimo(p, k)], _cb11, 16))
		for x in oggs:
			var i = x[0]
			var _cb12 = func():
				motore.usa_oggetto(id, i)
				chiudi_finestre()
				aggiorna()
			v.add_child(Widget.bottone(x[1], _cb12, 16))
	if p["armi"].size() > 1 and not motore.in_combattimento():
		var _cb13 = func():
			p["arma_att"] = 1 - int(p.get("arma_att", 0))
			chiudi_finestre()
			aggiorna()
		v.add_child(Widget.bottone("Impugna l'altra arma", _cb13, 16))
	vel = finestra("Scheda del personaggio", v, 760, true)

func _riga_scheda(et: String, val: String, ink: Color) -> Control:
	var h = HBoxContainer.new()
	var a = Widget.etichetta(et, 15, Risorse.COL_SANGUE, "Maiuscoletto")
	a.custom_minimum_size.x = 200
	a.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	h.add_child(a)
	var b = Widget.etichetta(val, 16, ink)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(b)
	return h

func apri_scheda_mostro(uid: String) -> void:
	var m: Dictionary = motore.unita(uid)
	if m.is_empty(): return
	var t: Dictionary = D.MOSTRI.get(m.get("tipo", ""), {})
	var v = VBoxContainer.new()
	var h = HBoxContainer.new()
	v.add_child(h)
	h.add_child(Widget.ritratto(m.get("ritratto", ""), 170))
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(col)
	var ink = Risorse.COL_INCHIOSTRO
	col.add_child(_riga_scheda("Punti Ferita", "%d su %d" % [motore.pf_residui(m), int(m["pf_max"])], ink))
	col.add_child(_riga_scheda("Bonus di Combattimento", str(int(m["bc"]) + int(m.get("idra_bonus", 0))), ink))
	col.add_child(_riga_scheda("Arma", (D.nome_arma(m["arma"]) + ((" +%d" % int(m["bonus_arma"])) if int(m.get("bonus_arma", 0)) > 0 else "")) if m.get("arma", "") != "" else "zanne, artigli e forza", ink))
	col.add_child(_riga_scheda("Resistenza", str(int(m["vr"])), ink))
	col.add_child(_riga_scheda("Negoziazione", str(int(m["vn"])) if int(m["vn"]) >= 0 else "non tratta", ink))
	col.add_child(_riga_scheda("Tesoro", "tipo " + m.get("tesoro", "?"), ink))
	if t.get("spec", "") != "":
		col.add_child(_riga_scheda("Speciale", t["spec"], ink))
	finestra(m["nome"], v, 700, true)

func apri_regole() -> void:
	var v = VBoxContainer.new()
	v.add_child(Regolamento.contenuto())
	finestra("Regolamento", v, 900, true)

func apri_tabelle() -> void:
	var v = VBoxContainer.new()
	v.add_child(Regolamento.tabelle())
	finestra("Tabelle", v, 1000, true)

# ============================================================================================
# Modalità di prova (screenshot automatici)
# ============================================================================================
func _prova(modo: String) -> void:
	match modo:
		"menu": pass
		"crea": mostra_crea()
		"regole":
			apri_regole()
		"tabelle":
			apri_tabelle()
		"tutorial":
			avvia_tutorial()
			for i in 3:
				tutorial.prova_avanti(self)
		_:
			motore = Motore.new()
			motore.nuova_partita({"seme": 4242, "eroi": ["almuric", "gislan", "dalmilandril"], "iniziati": [
				{"nome": "Borin", "razza": "nano", "arma2": "pugnale", "esperienza": "pf", "tiro_pm": 2},
				{"nome": "Lithiel", "razza": "elfo", "femmina": true, "arma2": "pugnale", "esperienza": "arma", "tiro_pm": 6},
				{"nome": "Corrado", "razza": "umano", "arma2": "pugnale_lancio", "esperienza": "abilita", "tiro_pm": 4}]})
			_entra_in_gioco()
			var obiettivo = {"gioco": "rotta", "combattimento": "azione", "scheda": "rotta", "labirinto": "rotta", "fine": "rotta"}.get(modo, "rotta")
			var rng = RandomNumberGenerator.new()
			rng.seed = 99
			var minimo = {"gioco": 6, "combattimento": 1, "scheda": 4, "labirinto": 60, "fine": 4}.get(modo, 4)
			var passi = 0
			while passi < 900 and motore.s.get("fine", "") == "":
				var sc: Dictionary = motore.s.get("scelta", {})
				if sc.is_empty(): break
				if sc["tipo"] == obiettivo and passi >= minimo: break
				var opz: Array = sc["opzioni"]
				var pref = opz.filter(func(o): return o["azione"] in ["esplora", "combatti", "attacca", "arco", "indaga", "ok", "prosegui", "basta", "no", "via"])
				if pref.is_empty(): pref = opz
				motore.scegli(pref[rng.randi_range(0, pref.size() - 1)]["id"], {"selezione": {}})
				motore.eventi.clear()
				passi += 1
			_recenti = []
			for e in motore.s["diario"].slice(-6): _recenti.append({"t": e["t"], "k": e["k"]})
			vista.livello_mostrato = -1
			vista.centra_su(int(motore.s["pos"]["liv"]), motore.s["pos"]["xy"])
			aggiorna()
			if modo == "labirinto":
				vista.zoom(1.8)
			if modo == "combattimento":
				_coda_crt.clear()
				crt.mostra({"testo": "Gislan attacca Idra", "col": "ascia", "riga": D.riga_crt(9), "dado": 5, "mod": 4, "tot": 9, "ferite": 1}, 99.0)
			if modo == "scheda":
				apri_scheda(motore.s["ordine_ids"][0])
			if modo == "fine":
				motore.s["fine"] = "vittoria"
				motore.s["scelta"] = {}
				aggiorna()
