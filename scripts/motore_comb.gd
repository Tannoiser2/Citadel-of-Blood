extends MotoreBase
class_name MotoreComb
## Mostri, ordine di marcia e combattimento (8.0, 9.0, 10.0, 15.0, 16.0).

# --------------------------------------------------------------------------------------------
# Mostri
# --------------------------------------------------------------------------------------------
func crea_mostro(tipo: String, liv: int, errante: bool) -> Dictionary:
	var t: Dictionary = D.MOSTRI[tipo]
	var i = clampi(liv, 1, 3) - 1
	var n = int(s.get("cont_mostri", 0)) + 1
	s["cont_mostri"] = n
	var dadi: float = t["dadi"]
	var pf = 0
	if dadi < 1.0:
		pf = d3()
	else:
		pf = tira(int(dadi))
	pf += int(t["agg"]) + int(D.LIVELLI["ferite"][i])
	pf = max(pf, 1)
	var lettere: String = t["tesoro"]
	var lettera = lettere
	if "/" in lettere:
		lettera = lettere.split("/")[1] if errante else lettere.split("/")[0]
	var m = {
		"uid": "m:%d" % n, "tipo": tipo, "nome": t["nome"], "ritratto": "m_" + tipo,
		"pf_max": pf, "ferite": 0, "bc": int(t["bc"]) + int(D.LIVELLI["bc"][i]), "vr": t["vr"],
		"vn": (int(t["vn"]) + (0 if tipo in ["demone", "x"] else int(D.LIVELLI["vn"][i]))) if int(t["vn"]) >= 0 else -1,
		"arma": t["arma"], "bonus_arma": 0, "tesoro": D.lettera_tesoro(lettera, int(D.LIVELLI["tesoro"][i])),
		"livello": liv, "dorme": false, "stato": "ok", "inc": t["inc"], "troll_fasi": -1, "idra_bonus": 0,
	}
	if t.get("arma_magica", false):
		m["bonus_arma"] = d6()
	return m

func tira_incontro(tabella_stanza: bool, liv: int) -> Array:
	var a = d6()
	var b = d6()
	var voce: Array
	if tabella_stanza:
		voce = D.MOSTRI_STANZA[a - 1][b - 1]
	else:
		voce = D.MOSTRI_ERRANTI[a - 1][int((b - 1) / 2)]
	mostra_dadi([a, b], "Tabella dei mostri %s" % ("della stanza" if tabella_stanza else "erranti"))
	var tipo: String = voce[0]
	var num = tira_codice(voce[1]) * int(D.LIVELLI["numero"][clampi(liv, 1, 3) - 1])
	var lista = []
	for k in num:
		lista.append(crea_mostro(tipo, liv, not tabella_stanza))
	annota("Tabella dei mostri %s: %d e %d → %s × %d%s." % ["della stanza" if tabella_stanza else "erranti", a, b, D.MOSTRI[tipo]["nome"], num,
		" (raddoppiati al livello 3)" if liv == 3 else ""], "dado")
	return lista

# --------------------------------------------------------------------------------------------
# Ordine di marcia
# --------------------------------------------------------------------------------------------
## Ordine del gruppo: s["ordine"] = 3 file × 3 posti di uid ("p:id" o "m:n" per i mostri incantati).
func ordine_gruppo() -> Array:
	var c: Dictionary = s.get("comb", {})
	if not c.is_empty() and c.get("solo", "") != "":
		return c["ordine_solo"]
	return s["ordine"]

func fila_di(ordine: Array, uid: String) -> Vector2i:
	for r in ordine.size():
		for col in 3:
			if ordine[r][col] == uid:
				return Vector2i(col, r)
	return Vector2i(-1, -1)

func togli_da_ordine(ordine: Array, uid: String) -> void:
	for r in ordine.size():
		for col in 3:
			if ordine[r][col] == uid:
				ordine[r][col] = ""

func unita_in(ordine: Array) -> Array:
	var r = []
	for fila in ordine:
		for u in fila:
			if u != "":
				r.append(u)
	return r

func fila_vuota(f: Array) -> bool:
	return f[0] == "" and f[1] == "" and f[2] == ""

## Fa avanzare le file se la prima è vuota (le file non possono restare vuote davanti).
func compatta(ordine: Array) -> void:
	var cambiato = true
	while cambiato:
		cambiato = false
		for r in range(ordine.size() - 1):
			if fila_vuota(ordine[r]) and not fila_vuota(ordine[r + 1]):
				ordine[r] = ordine[r + 1]
				ordine[r + 1] = ["", "", ""]
				cambiato = true
	while ordine.size() < 3:
		ordine.append(["", "", ""])

## Rimette in ordine il gruppo fuori dal combattimento: file da 3, prima fila con almeno 2.
func sistema_ordine() -> void:
	var ids = []
	for u in unita_in(s["ordine"]):
		var x = unita(u)
		if not x.is_empty() and vivo(x) and x.get("stato", "ok") == "ok":
			ids.append(u)
	for id in s.get("ordine_ids", []):
		var uid = "p:" + id
		var p = pg(id)
		if not ids.has(uid) and p.get("stato", "ok") == "ok" and vivo(p):
			ids.append(uid)
	for k in s.get("alleati", {}):
		if not ids.has(k):
			ids.append(k)
	var vecchio: Array = s["ordine"]
	# mantiene le posizioni esistenti dove possibile
	var nuovo = [["", "", ""], ["", "", ""], ["", "", ""]]
	var messi = []
	for r in vecchio.size():
		if r > 2: break
		for col in 3:
			var u: String = vecchio[r][col]
			if u != "" and ids.has(u):
				nuovo[r][col] = u
				messi.append(u)
	for u in ids:
		if messi.has(u): continue
		var posto = false
		for r in 3:
			for col in 3:
				if not posto and nuovo[r][col] == "":
					nuovo[r][col] = u
					posto = true
		messi.append(u)
	compatta(nuovo)
	# prima fila con almeno 2 (se possibile)
	var tot = unita_in(nuovo).size()
	var conta_prima = 0
	for u in nuovo[0]:
		if u != "": conta_prima += 1
	while tot >= 2 and conta_prima < 2:
		var spostato = false
		for r in range(1, 3):
			for col in 3:
				if not spostato and nuovo[r][col] != "":
					for c2 in 3:
						if not spostato and nuovo[0][c2] == "":
							nuovo[0][c2] = nuovo[r][col]
							nuovo[r][col] = ""
							spostato = true
		if not spostato: break
		conta_prima += 1
		compatta(nuovo)
	s["ordine"] = nuovo

func prima_fila(ordine: Array) -> Array:
	compatta(ordine)
	var r = []
	for col in 3:
		if ordine[0][col] != "":
			r.append(ordine[0][col])
	return r

# --------------------------------------------------------------------------------------------
# Bersagli (9.3)
# --------------------------------------------------------------------------------------------
func lato_di(uid: String) -> String:
	var c: Dictionary = s.get("comb", {})
	if c.is_empty(): return ""
	if fila_di(c["ordine_m"], uid).x >= 0: return "mostri"
	if fila_di(ordine_gruppo(), uid).x >= 0: return "gruppo"
	return ""

## Candidati per un attacco in mischia di `uid` (o da seconda fila: tutta la prima fila nemica)
func bersagli(uid: String, da_seconda: bool = false) -> Array:
	var c: Dictionary = s["comb"]
	var mio: Array = c["ordine_m"] if lato_di(uid) == "mostri" else ordine_gruppo()
	var nemico: Array = ordine_gruppo() if lato_di(uid) == "mostri" else c["ordine_m"]
	compatta(nemico)
	var fronte_n = prima_fila(nemico)
	if fronte_n.is_empty():
		return []
	var pos = fila_di(mio, uid)
	if da_seconda or pos.y != 0:
		return fronte_n
	var col = pos.x
	var di_fronte: String = nemico[0][col]
	if di_fronte != "":
		var r = [di_fronte]
		# nemici senza avversario di fronte, di cui sono l'attaccante più vicino
		for c2 in 3:
			var e: String = nemico[0][c2]
			if e == "" or c2 == col: continue
			if mio[0][c2] != "": continue
			var mia_dist = absi(c2 - col)
			var piu_vicino = true
			for c3 in 3:
				if mio[0][c3] != "" and c3 != col and absi(c2 - c3) < mia_dist:
					piu_vicino = false
			if piu_vicino:
				r.append(e)
		return r
	# nessuno di fronte: i nemici più vicini
	var best = 99
	var r2 = []
	for c2 in 3:
		var e2: String = nemico[0][c2]
		if e2 == "": continue
		var dist = absi(c2 - col)
		if dist < best:
			best = dist
			r2 = [e2]
		elif dist == best:
			r2.append(e2)
	return r2

func scegli_a_caso(lista: Array):
	if lista.is_empty(): return null
	if lista.size() == 1: return lista[0]
	var t = d6()
	var i = int((t - 1) * lista.size() / 6)
	return lista[clampi(i, 0, lista.size() - 1)]

# --------------------------------------------------------------------------------------------
# Inizio del combattimento
# --------------------------------------------------------------------------------------------
func disponi_mostri(lista_uid: Array, hellgate: bool) -> Array:
	var ord = [["", "", ""], ["", "", ""], ["", "", ""]]
	var c: Dictionary = s["comb"]
	if hellgate:
		var dem = []
		var x = ""
		for u in lista_uid:
			if c["mostri"][u]["tipo"] == "x": x = u
			elif c["mostri"][u]["tipo"] == "demone": dem.append(u)
		var posti = [[0, 0], [0, 1], [0, 2], [1, 0], [1, 2]]
		for i in dem.size():
			if i < posti.size():
				ord[posti[i][0]][posti[i][1]] = dem[i]
		ord[1][1] = x
		ord[2][1] = "hellgate"
		return ord
	var ordinati = lista_uid.duplicate()
	ordinati.sort_custom(func(a, b): return int(c["mostri"][a]["pf_max"]) > int(c["mostri"][b]["pf_max"]))
	if ordinati.size() == 1:
		ord[0][1] = ordinati[0]
	elif ordinati.size() == 2:
		ord[0][0] = ordinati[0]
		ord[0][2] = ordinati[1]
	else:
		var i = 0
		for u in ordinati:
			var r = int(i / 3)
			while ord.size() <= r:
				ord.append(["", "", ""])
			ord[r][i % 3] = u
			i += 1
	return ord

func inizia_combattimento(mostri: Array, opz: Dictionary) -> void:
	var c = {
		"mostri": {}, "ordine_m": [], "round": 1, "fase": "", "da_agire": [],
		"hellgate": opz.get("hellgate", false), "mostri_primi": opz.get("mostri_primi", false),
		"pf_iniziali": 0, "uccisi": [], "caduti": [], "fasi_mostri": 0, "solo": opz.get("solo", ""),
		"unisci_dal_round": int(opz.get("unisci_dal_round", 0)), "tregua": false, "esito": "",
		"oro_corruzione": int(opz.get("oro_corruzione", 0)), "nausea": [], "senza_tesoro": opz.get("senza_tesoro", false),
		"posseduti": opz.get("posseduti", []),
	}
	s["comb"] = c
	for m in mostri:
		c["mostri"][m["uid"]] = m
		c["pf_iniziali"] += int(m["pf_max"]) - int(m["ferite"])
	c["ordine_m"] = disponi_mostri(c["mostri"].keys(), c["hellgate"])
	for p_uid in c["posseduti"]:
		_metti_in_fila(c["ordine_m"], p_uid, true)
	if c["solo"] != "":
		c["ordine_solo"] = [["", "p:" + c["solo"], ""], ["", "", ""], ["", "", ""]]
	sistema_ordine()
	evento({"tipo": "combattimento", "inizio": true})
	var nomi = []
	for m in mostri:
		nomi.append("%s (%d PF)" % [m["nome"], int(m["pf_max"])])
	annota("Inizia il combattimento contro: %s." % ", ".join(nomi), "comb")
	# Fetore dei Cronk (15.1)
	var ci_sono_cronk = false
	for m in mostri:
		if m["tipo"] == "cronk": ci_sono_cronk = true
	if ci_sono_cronk:
		for uid in unita_in(ordine_gruppo()):
			if uid.begins_with("p:") and not resiste(uid, "il fetore dei Cronk"):
				var p = unita(uid)
				p["bc_temp"] = int(p.get("bc_temp", 0)) - 2
				c["nausea"].append(uid)
				annota("%s è nauseato: −2 al Bonus di Combattimento per questo scontro." % p["nome"])
	_inizia_round()

func _metti_in_fila(ordine: Array, uid: String, davanti: bool) -> void:
	var righe = range(ordine.size()) if davanti else range(ordine.size() - 1, -1, -1)
	for r in righe:
		for col in [1, 0, 2]:
			if ordine[r][col] == "":
				ordine[r][col] = uid
				return
	ordine.append(["", uid, ""])

func _inizia_round() -> void:
	var c: Dictionary = s["comb"]
	# nella bara (13.4) il resto del gruppo si unisce dal secondo round
	if c["solo"] != "" and int(c.get("unisci_dal_round", 0)) > 0 and int(c["round"]) >= int(c["unisci_dal_round"]):
		c["solo"] = ""
		sistema_ordine()
		annota("Il resto del gruppo si unisce al combattimento.", "comb")
	evento({"tipo": "round", "n": c["round"]})
	if c["round"] == 1 and c["mostri_primi"]:
		annota("I mostri attaccano per primi: il gruppo perde la sua prima fase di combattimento.", "comb")
		_fase_mostri()
		return
	_fase_gruppo()

# --------------------------------------------------------------------------------------------
# Fase di combattimento del gruppo
# --------------------------------------------------------------------------------------------
func _fase_gruppo() -> void:
	var c: Dictionary = s["comb"]
	c["fase"] = "gruppo"
	var ord = ordine_gruppo()
	compatta(ord)
	var lista = []
	for r in ord.size():
		for col in 3:
			var u: String = ord[r][col]
			if u == "": continue
			lista.append(u)
	c["da_agire"] = lista
	_prossimo_attore()

func _prossimo_attore() -> void:
	var c: Dictionary = s["comb"]
	if _controlla_fine():
		return
	while not c["da_agire"].is_empty():
		var uid: String = c["da_agire"].pop_front()
		var u = unita(uid)
		if u.is_empty() or not vivo(u) or u.get("dorme", false) or u.get("stato", "ok") in ["pietra", "morto"]:
			continue
		if lato_di(uid) != "gruppo":
			continue
		var opz = opzioni_attacco(uid)
		var utili = opz.filter(func(o): return o["azione"] != "passa" and o.get("utile", true))
		if utili.is_empty():
			continue
		s["scelta"] = {"tipo": "azione", "chi": uid, "testo": "%s: che cosa fa?" % u["nome"], "opzioni": opz}
		return
	_fase_mostri()

func opzioni_attacco(uid: String) -> Array:
	var c: Dictionary = s["comb"]
	var u = unita(uid)
	var pos = fila_di(ordine_gruppo(), uid)
	var opz = []
	var e_pg = uid.begins_with("p:")
	if pos.y == 0:
		var a = arma(u) if e_pg else {"tipo": u.get("arma", ""), "bonus": 0}
		if e_pg and a["tipo"] == "arco":
			pass
		else:
			for b in bersagli(uid):
				opz.append({"id": "att|" + b, "azione": "attacca", "bersaglio": b, "gruppo": "Attacco",
					"testo": "Attacca %s con %s" % [nome(b), D.nome_arma(a["tipo"]) if a["tipo"] != "" else "zanne e artigli"]})
	elif pos.y == 1 and e_pg:
		var a2 = arma(u)
		if a2["tipo"] == "arco":
			for b in prima_fila(c["ordine_m"]):
				opz.append({"id": "arc|" + b, "azione": "arco", "bersaglio": b, "gruppo": "Attacco", "testo": "Scocca una freccia a %s" % nome(b)})
		if a2["tipo"] == "pugnale_lancio" and not u.get("pugnale_lanciato", false):
			for b in prima_fila(c["ordine_m"]):
				opz.append({"id": "lan|" + b, "azione": "lancia", "bersaglio": b, "gruppo": "Attacco", "testo": "Lancia il pugnale a %s" % nome(b)})
		for k in incantesimi_usabili(uid, ["C", "S"]):
			opz += _opzioni_incantesimo(uid, k)
	if e_pg:
		for o in u.get("oggetti", []):
			if o.get("tipo") == "talismano" and o.get("var") == "mente" and int(o.get("usi", 0)) > 0 and pf_residui(u) > 1:
				for b in unita_in(c["ordine_m"]):
					if b == "hellgate": continue
					opz.append({"id": "tal|" + b, "azione": "talismano", "bersaglio": b, "gruppo": "Oggetti", "testo": "Talismano della Mente contro %s (1 PF)" % nome(b)})
			if o.get("tipo") == "anello" and o.get("var") == "sonno" and not o.get("usato", false):
				for b in unita_in(c["ordine_m"]):
					if b == "hellgate" or b.begins_with("p:"): continue
					opz.append({"id": "asn|" + b, "azione": "anello_sonno", "bersaglio": b, "gruppo": "Oggetti", "testo": "Anello del Sonno su %s" % nome(b)})
		if u.get("armi", []).size() > 1:
			var altra: Dictionary = u["armi"][1 - int(u.get("arma_att", 0))]
			var utile = false
			if pos.y == 0: utile = altra["tipo"] != "arco" and arma(u)["tipo"] == "arco"
			elif pos.y == 1: utile = altra["tipo"] == "arco" or (altra["tipo"] == "pugnale_lancio" and not u.get("pugnale_lanciato", false))
			opz.append({"id": "cambia", "azione": "cambia", "bersaglio": "", "gruppo": "Altro", "utile": utile, "testo": "Impugna %s (non attacca)" % D.nome_arma(altra["tipo"])})
	opz.append({"id": "passa", "azione": "passa", "bersaglio": "", "gruppo": "Altro", "testo": "Non fa nulla"})
	return opz

func costo_incantesimo(p: Dictionary, k: String) -> int:
	var costo = int(D.INCANTESIMI[k]["costo"])
	if k == "lt" and p.get("flag", {}).get("fulmine_economico", false):
		costo = 1
	var c: Dictionary = s.get("comb", {})
	if not c.is_empty() and D.INCANTESIMI[k]["tipo"] in ["C", "S"] and p.get("flag", {}).get("alloces", false):
		costo = 0
	return costo

func incantesimi_usabili(uid: String, tipi: Array) -> Array:
	var p = unita(uid)
	var r = []
	if not uid.begins_with("p:") or p.get("stato", "ok") != "ok": return r
	for k in p.get("inc_attivi", []):
		if not D.INCANTESIMI.has(k): continue
		if not D.INCANTESIMI[k]["tipo"] in tipi: continue
		if k == "rs": continue
		var costo = costo_incantesimo(p, k)
		if pf_residui(p) <= costo: continue
		if k in ["he", "rj"] and int(p.get("usi_cura", {}).get(k, 0)) <= 0: continue
		r.append(k)
	return r

func _opzioni_incantesimo(uid: String, k: String) -> Array:
	var c: Dictionary = s["comb"]
	var p = unita(uid)
	var inc: Dictionary = D.INCANTESIMI[k]
	var costo = costo_incantesimo(p, k)
	var testa = "%s (%d PF)" % [inc["nome"], costo]
	var opz = []
	var mostri_tutti = unita_in(c["ordine_m"]).filter(func(x): return x != "hellgate")
	match k:
		"bl", "lt", "ma", "wg":
			for b in prima_fila(c["ordine_m"]):
				if b == "hellgate": continue
				opz.append({"id": "inc|%s|%s" % [k, b], "azione": "inc_" + k, "bersaglio": b, "gruppo": "Incantesimi", "testo": "%s su %s" % [testa, nome(b)]})
		"cm":
			for b in mostri_tutti:
				var pos = fila_di(c["ordine_m"], b)
				if pos.y <= 1 and (b.begins_with("p:") or not unita(b).get("tipo", "") in ["x", "demone"]):
					opz.append({"id": "inc|cm|" + b, "azione": "inc_cm", "bersaglio": b, "gruppo": "Incantesimi", "testo": "%s su %s" % [testa, nome(b)]})
		"sl":
			for b in mostri_tutti:
				if b.begins_with("m:") and unita(b).get("tipo", "") != "x":
					opz.append({"id": "inc|sl|" + b, "azione": "inc_sl", "bersaglio": b, "gruppo": "Incantesimi", "testo": "%s su %s" % [testa, nome(b)]})
		"rd":
			for b in mostri_tutti:
				if b.begins_with("p:"):
					opz.append({"id": "inc|rd|" + b, "azione": "inc_rd", "bersaglio": b, "gruppo": "Incantesimi", "testo": "%s su %s" % [testa, nome(b)]})
		"ms":
			for b in unita_in(ordine_gruppo()):
				if b.begins_with("p:") and not unita(b).get("scudo_magico", false):
					opz.append({"id": "inc|ms|" + b, "azione": "inc_ms", "bersaglio": b, "gruppo": "Incantesimi", "testo": "%s su %s" % [testa, nome(b)]})
		"ex":
			opz.append({"id": "inc|ex", "azione": "inc_ex", "bersaglio": "", "gruppo": "Incantesimi", "testo": testa + ": tutti fanno la Resistenza"})
		"cf":
			if not c["hellgate"]:
				opz.append({"id": "inc|cf", "azione": "inc_cf", "bersaglio": "", "gruppo": "Incantesimi", "testo": testa + ": fine del combattimento"})
	return opz

## Esegue una scelta della fase del gruppo
func esegui_azione(uid: String, o: Dictionary) -> void:
	var c: Dictionary = s["comb"]
	var u = unita(uid)
	var b: String = o.get("bersaglio", "")
	match o["azione"]:
		"attacca":
			attacco(uid, b, "")
		"arco":
			attacco(uid, b, "arco")
		"lancia":
			u["pugnale_lanciato"] = true
			attacco(uid, b, "pugnale_lancio")
		"cambia":
			u["arma_att"] = 1 - int(u.get("arma_att", 0))
			annota("%s impugna %s." % [u["nome"], D.nome_arma(arma(u)["tipo"])])
		"passa":
			pass
		"talismano":
			for t in u["oggetti"]:
				if t.get("tipo") == "talismano" and t.get("var") == "mente":
					t["usi"] = int(t.get("usi", 0)) - 1
					break
			u["ferite"] = int(u["ferite"]) + 1
			annota("%s usa il Talismano della Mente contro %s (1 PF)." % [u["nome"], nome(b)], "magia")
			if not resiste(b, "il Talismano della Mente"):
				var n = d6()
				danneggia(b, n, u["nome"], true)
		"anello_sonno":
			for t in u["oggetti"]:
				if t.get("tipo") == "anello" and t.get("var") == "sonno":
					t["usato"] = true
			annota("%s usa l'Anello del Sonno su %s." % [u["nome"], nome(b)], "magia")
			if not resiste(b, "il Sonno"):
				unita(b)["dorme"] = true
				annota("%s si addormenta." % nome(b))
		_:
			if String(o["azione"]).begins_with("inc_"):
				lancia_incantesimo_comb(uid, String(o["azione"]).substr(4), b)
	_prossimo_attore()

# --------------------------------------------------------------------------------------------
# Attacchi e danni
# --------------------------------------------------------------------------------------------
func attacco(att: String, bers: String, tipo_forzato: String) -> void:
	var a = unita(att)
	var b = unita(bers)
	if a.is_empty() or b.is_empty(): return
	var col = "mostro"
	var mod = 0
	var descr = ""
	if att.begins_with("p:"):
		var w = arma(a)
		var t: String = tipo_forzato if tipo_forzato != "" else w["tipo"]
		col = t
		mod = bc_totale(a) + int(a.get("abil", {}).get(t, 0)) + int(w.get("bonus", 0))
		descr = D.nome_arma(t)
	else:
		if a.get("arma", "") != "":
			col = a["arma"]
		mod = int(a["bc"]) + int(a.get("bonus_arma", 0)) + int(a.get("idra_bonus", 0))
		descr = D.nome_arma(col) if col != "mostro" else "attacco"
	var t1 = d6()
	var tot = t1 + mod
	var n = D.ferite_crt(col, tot)
	mostra_dadi([t1], "%s attacca %s" % [a["nome"], b["nome"]])
	annota("%s attacca %s (%s): tira %d %+d = %d → %s." % [a["nome"], b["nome"], descr, t1, mod, tot,
		"mancato" if n == 0 else ("%d ferit%s" % [n, "a" if n == 1 else "e"])], "dado")
	evento({"tipo": "attacco", "da": att, "a": bers, "ferite": n, "col": col, "riga": D.riga_crt(tot),
		"dado": t1, "mod": mod, "tot": tot, "testo": "%s attacca %s" % [a["nome"], b["nome"]]})
	if n > 0:
		danneggia(bers, n, a["nome"], false)

## Infligge ferite. Restituisce true se il bersaglio muore.
func danneggia(uid: String, n: int, fonte: String, magico: bool) -> bool:
	var u = unita(uid)
	if u.is_empty() or n <= 0: return false
	if uid.begins_with("p:"):
		if magico and u.get("scudo_magico", false):
			annota("Lo Scudo magico protegge %s." % u["nome"], "magia")
			return false
		var arm = int(u.get("armatura_magica", 0))
		if arm > 0:
			var ass = mini(arm, n)
			u["armatura_magica"] = arm - ass
			n -= ass
			annota("L'Armatura magica di %s assorbe %d ferit%s." % [u["nome"], ass, "a" if ass == 1 else "e"], "magia")
			if n <= 0: return false
	u["ferite"] = int(u["ferite"]) + n
	if u.get("tipo", "") == "idra":
		u["idra_bonus"] = int(u.get("idra_bonus", 0)) + n
	if u.get("tipo", "") == "troll" and int(u.get("troll_fasi", -1)) < 0:
		u["troll_fasi"] = 0
	evento({"tipo": "danno", "uid": uid, "n": n})
	if pf_residui(u) <= 0:
		muore(uid, fonte)
		return true
	return false

func muore(uid: String, fonte: String) -> void:
	var u = unita(uid)
	var c: Dictionary = s.get("comb", {})
	u["stato"] = "morto"
	evento({"tipo": "morte", "uid": uid})
	if uid.begins_with("p:"):
		annota("%s è caduto." % u["nome"], "morte")
		if not c.is_empty():
			c["caduti"].append(uid.substr(2))
		_redistribuisci(uid.substr(2))
	else:
		annota("%s è uccis%s." % [u["nome"], "a" if u["nome"].ends_with("a") else "o"], "morte")
		if not c.is_empty():
			c["uccisi"].append(uid)
		if s.get("alleati", {}).has(uid):
			s["alleati"].erase(uid)
		# morto il vampiro, i suoi incantati tornano liberi (15.5)
		if u.get("tipo", "") == "vampiro" and not c.is_empty():
			for p_uid in unita_in(c["ordine_m"]):
				if p_uid.begins_with("p:") and unita(p_uid).get("incantato_da", "") == uid:
					libera_pg(p_uid)
		# morto X, la Porta dell'Inferno si spegne e i demoni svaniscono (16.0)
		if u.get("tipo", "") == "x" and not c.is_empty():
			annota("Con X lo Sconosciuto muore anche il potere della Porta: i demoni svaniscono!", "evento")
			for m_uid in unita_in(c["ordine_m"]):
				if m_uid.begins_with("m:") and unita(m_uid).get("tipo", "") == "demone":
					unita(m_uid)["stato"] = "svanito"
					togli_da_ordine(c["ordine_m"], m_uid)
			togli_da_ordine(c["ordine_m"], "hellgate")
			s["hellgate"]["x_morto"] = true
	if not c.is_empty():
		togli_da_ordine(c["ordine_m"], uid)
	togli_da_ordine(ordine_gruppo(), uid)
	togli_da_ordine(s["ordine"], uid)

func libera_pg(p_uid: String) -> void:
	var c: Dictionary = s.get("comb", {})
	var p = unita(p_uid)
	p["stato"] = "ok"
	p.erase("incantato_da")
	if not c.is_empty():
		togli_da_ordine(c["ordine_m"], p_uid)
		c["posseduti"].erase(p_uid)
	_metti_in_fila(ordine_gruppo(), p_uid, false)
	annota("%s torna in sé e si riunisce al gruppo." % p["nome"], "evento")

func _redistribuisci(id: String) -> void:
	var p = pg(id)
	var vivi = pg_in_gruppo().filter(func(x): return x != id)
	if vivi.is_empty(): return
	var oro = int(p.get("oro", 0))
	if oro > 0:
		var parte = int(oro / vivi.size())
		for i in vivi.size():
			pg(vivi[i])["oro"] = int(pg(vivi[i])["oro"]) + parte + (oro % vivi.size() if i == 0 else 0)
		p["oro"] = 0
	var j = 0
	for g in p.get("gioielli", []):
		pg(vivi[j % vivi.size()])["gioielli"].append(g)
		j += 1
	p["gioielli"] = []
	for o in p.get("oggetti", []):
		var meno = vivi[0]
		for v in vivi:
			if pg(v)["oggetti"].size() < pg(meno)["oggetti"].size(): meno = v
		pg(meno)["oggetti"].append(o)
		_applica_oggetto_passivo(pg(meno), o)
	if not p.get("oggetti", []).is_empty():
		annota("Gli oggetti di %s passano ai compagni." % p["nome"])
	p["oggetti"] = []

func _applica_oggetto_passivo(_p: Dictionary, _o: Dictionary) -> void:
	pass

# --------------------------------------------------------------------------------------------
# Incantesimi in combattimento
# --------------------------------------------------------------------------------------------
func paga(p: Dictionary, k: String) -> bool:
	var costo = costo_incantesimo(p, k)
	if costo > 0:
		p["ferite"] = int(p["ferite"]) + costo
	if pf_residui(p) <= 0:
		muore("p:" + p["id"], "magia")
		return false
	return true

func lancia_incantesimo_comb(uid: String, k: String, b: String) -> void:
	var c: Dictionary = s["comb"]
	var p = unita(uid)
	var inc: Dictionary = D.INCANTESIMI[k]
	annota("%s lancia %s%s." % [p["nome"], inc["nome"], (" su " + nome(b)) if b != "" else ""], "magia")
	evento({"tipo": "incantesimo", "da": uid, "a": b, "k": k})
	if not paga(p, k):
		return
	match k:
		"bl":
			if not resiste(b, inc["nome"]): danneggia(b, 2, p["nome"], true)
		"lt":
			if not resiste(b, inc["nome"]):
				var n = d3() + 2
				danneggia(b, n, p["nome"], true)
		"ma":
			if not resiste(b, inc["nome"]):
				danneggia(b, tira(2) + 2, p["nome"], true)
		"wg":
			if not resiste(b, inc["nome"]):
				danneggia(b, tira(2) + 2, p["nome"], true)
		"ex":
			for x in unita_in(c["ordine_m"]) + unita_in(ordine_gruppo()):
				if x == "hellgate": continue
				var ux = unita(x)
				if ux.is_empty() or not vivo(ux): continue
				if not resiste(x, "l'Esplosione"):
					danneggia(x, 1, p["nome"], true)
		"sl":
			if not resiste(b, inc["nome"]):
				unita(b)["dorme"] = true
				annota("%s crolla addormentat%s." % [nome(b), "a" if nome(b).ends_with("a") else "o"])
		"cm":
			if not resiste(b, inc["nome"]):
				if b.begins_with("p:"):
					libera_pg(b)
				else:
					incanta_mostro(b, p["id"])
		"rd":
			# il redento deve tentare di resistere (13.2)
			if not resiste(b, inc["nome"]):
				libera_pg(b)
		"ms":
			unita(b)["scudo_magico"] = true
			annota("%s è avvolto dallo Scudo magico." % nome(b))
		"cf":
			c["tregua"] = true
			annota("Tregua! Il combattimento finisce come per un Accordo.", "evento")

func incanta_mostro(m_uid: String, da_pg: String) -> void:
	var c: Dictionary = s["comb"]
	var m: Dictionary = c["mostri"][m_uid]
	m["incantato_da"] = da_pg
	if not s.has("alleati"): s["alleati"] = {}
	s["alleati"][m_uid] = m
	c["mostri"].erase(m_uid)
	togli_da_ordine(c["ordine_m"], m_uid)
	_metti_in_fila(ordine_gruppo(), m_uid, false)
	annota("%s è incantato e combatte ora per il gruppo." % m["nome"], "evento")

# --------------------------------------------------------------------------------------------
# Fase dei mostri
# --------------------------------------------------------------------------------------------
func _fase_mostri() -> void:
	var c: Dictionary = s["comb"]
	if _controlla_fine(): return
	c["fase"] = "mostri"
	c["fasi_mostri"] = int(c["fasi_mostri"]) + 1
	var ord: Array = c["ordine_m"]
	compatta(ord)
	var attori = []
	for r in mini(2, ord.size()):
		for col in 3:
			if ord[r][col] != "" and ord[r][col] != "hellgate":
				attori.append([ord[r][col], r])
	for coppia in attori:
		if _controlla_fine_silenzioso(): break
		var uid: String = coppia[0]
		var r: int = coppia[1]
		var u = unita(uid)
		if u.is_empty() or not vivo(u) or u.get("dorme", false) or u.get("stato", "ok") in ["morto", "svanito"]: continue
		if fila_di(ord, uid).x < 0: continue
		r = fila_di(ord, uid).y
		# maghi malvagi e X lanciano il Fulmine se non ne muoiono (15.7)
		if u.get("inc", "") == "lt" and pf_residui(u) > 2 and r <= 1:
			var cand = bersagli(uid) if r == 0 else prima_fila(ordine_gruppo())
			var b = scegli_a_caso(cand)
			if b != null:
				u["ferite"] = int(u["ferite"]) + 2
				annota("%s scaglia un Fulmine contro %s." % [u["nome"], nome(b)], "magia")
				evento({"tipo": "incantesimo", "da": uid, "a": b, "k": "lt"})
				if not resiste(b, "il Fulmine"):
					danneggia(b, d3() + 2, u["nome"], true)
			continue
		if r != 0: continue
		var b2 = scegli_a_caso(bersagli(uid))
		if b2 == null: continue
		# Vampiro: nelle prime due fasi tenta di incantare (15.5)
		if u.get("tipo", "") == "vampiro" and int(c["fasi_mostri"]) <= 2 and String(b2).begins_with("p:"):
			annota("Il Vampiro fissa %s con occhi ipnotici..." % nome(b2), "magia")
			if not resiste(b2, "lo sguardo del Vampiro"):
				var p = unita(b2)
				p["stato"] = "incantato"
				p["incantato_da"] = uid
				togli_da_ordine(ordine_gruppo(), b2)
				_metti_in_fila(ord, b2, true)
				annota("%s è incantato dal Vampiro e passa dalla sua parte!" % p["nome"], "evento")
				continue
		if uid.begins_with("p:"):
			attacco(uid, b2, "")
		else:
			attacco(uid, b2, "")
			# Chimera: soffio di fuoco (15.2)
			if u.get("tipo", "") == "chimera" and unita(b2).get("stato", "ok") != "morto":
				if not resiste(b2, "il soffio della Chimera"):
					danneggia(b2, 1, "il soffio di fuoco", false)
			# Medusa: pietrificazione (15.3)
			if u.get("tipo", "") == "medusa" and String(b2).begins_with("p:") and unita(b2).get("stato", "ok") == "ok":
				var t = d6()
				mostra_dadi([t], "Sguardo della Medusa")
				if t == 6:
					var pp = unita(b2)
					pp["stato"] = "pietra"
					togli_da_ordine(ordine_gruppo(), b2)
					annota("%s è trasformato in pietra dallo sguardo della Medusa!" % pp["nome"], "morte")
	# Troll: rigenerazione ogni terza fase dopo la prima ferita (15.4)
	for uid in c["mostri"]:
		var m: Dictionary = c["mostri"][uid]
		if m["tipo"] == "troll" and m.get("stato", "ok") == "ok" and int(m.get("troll_fasi", -1)) >= 0:
			m["troll_fasi"] = int(m["troll_fasi"]) + 1
			if int(m["troll_fasi"]) % 3 == 0 and int(m["ferite"]) > 0:
				m["ferite"] = int(m["ferite"]) - 1
				annota("Il Troll rigenera 1 ferita.", "evento")
	if _controlla_fine(): return
	_fase_hellgate()

func _fase_hellgate() -> void:
	var c: Dictionary = s["comb"]
	if c["hellgate"] and not s["hellgate"].get("x_morto", false):
		c["fase"] = "hellgate"
		annota("La Porta dell'Inferno scaglia tre Scariche!", "magia")
		for i in 3:
			var vivi = unita_in(ordine_gruppo()).filter(func(x): return x.begins_with("p:"))
			var b = scegli_a_caso(vivi)
			if b == null: break
			evento({"tipo": "incantesimo", "da": "hellgate", "a": b, "k": "bl"})
			if not resiste(b, "la Scarica della Porta"):
				danneggia(b, 2, "la Porta dell'Inferno", true)
		if _controlla_fine(): return
	_fase_riorganizzazione()

# --------------------------------------------------------------------------------------------
# Riorganizzazione (9.8)
# --------------------------------------------------------------------------------------------
func spostamenti_validi() -> Array:
	var ord = ordine_gruppo()
	compatta(ord)
	var n_prima = 0
	for x in ord[0]:
		if x != "": n_prima += 1
	var n_altri = unita_in(ord).size() - n_prima
	var r = []
	for row in ord.size():
		for col in 3:
			var u: String = ord[row][col]
			if u == "": continue
			for r2 in [row - 1, row, row + 1]:
				if r2 < 0 or r2 > 2: continue
				for c2 in 3:
					if r2 == row and c2 == col: continue
					if r2 < ord.size() and ord[r2][c2] != "": continue
					if r2 == row:
						# nella stessa fila senza scavalcare nessuno
						var libero = true
						for cc in range(mini(col, c2) + 1, maxi(col, c2)):
							if ord[row][cc] != "": libero = false
						if not libero: continue
					elif absi(c2 - col) > 1:
						continue
					# vincoli
					if n_prima == 1 and n_altri > 0 and not (row > 0 and r2 == 0):
						continue
					if row == 0 and r2 > 0 and n_prima <= 2:
						continue
					r.append({"uid": u, "da": Vector2i(col, row), "a": Vector2i(c2, r2)})
	return r

func _fase_riorganizzazione() -> void:
	var c: Dictionary = s["comb"]
	c["fase"] = "riorg"
	var mosse = spostamenti_validi()
	var obbligo = false
	var ord = ordine_gruppo()
	var n_prima = 0
	for x in ord[0]:
		if x != "": n_prima += 1
	if n_prima == 1 and unita_in(ord).size() > 1:
		obbligo = true
	if mosse.is_empty():
		_fase_riorganizzazione_mostri()
		return
	var opz = []
	for m in mosse:
		opz.append({"id": "sp|%s|%d|%d" % [m["uid"], m["a"].x, m["a"].y], "azione": "sposta", "bersaglio": m["uid"], "gruppo": "Riorganizzazione",
			"a": [m["a"].x, m["a"].y], "testo": "Sposta %s in fila %d, posto %d" % [nome(m["uid"]), m["a"].y + 1, m["a"].x + 1]})
	if not obbligo:
		opz.append({"id": "prosegui", "azione": "prosegui", "bersaglio": "", "gruppo": "Altro", "testo": "Nessuno spostamento: prossimo round"})
	s["scelta"] = {"tipo": "riorg", "testo": "Riorganizzazione: puoi spostare un personaggio%s." % (" (obbligatorio: in prima fila ne è rimasto uno solo)" if obbligo else ""), "opzioni": opz}

func esegui_riorg(o: Dictionary) -> void:
	if o["azione"] == "sposta":
		var ord = ordine_gruppo()
		var uid: String = o["bersaglio"]
		var a: Array = o["a"]
		togli_da_ordine(ord, uid)
		ord[int(a[1])][int(a[0])] = uid
		annota("%s si sposta in fila %d." % [nome(uid), int(a[1]) + 1])
		evento({"tipo": "ordine"})
	_fase_riorganizzazione_mostri()

func _fase_riorganizzazione_mostri() -> void:
	var c: Dictionary = s["comb"]
	var ord: Array = c["ordine_m"]
	compatta(ord)
	var vuoti0 = []
	for col in 3:
		if ord[0][col] == "": vuoti0.append(col)
	if not vuoti0.is_empty() and ord.size() > 1 and not fila_vuota(ord[1]):
		_avanza_mostro(ord, 1, vuoti0)
	elif vuoti0.is_empty() and ord.size() > 2 and not fila_vuota(ord[2]):
		var vuoti1 = []
		for col in 3:
			if ord[1][col] == "": vuoti1.append(col)
		if not vuoti1.is_empty():
			_avanza_mostro(ord, 2, vuoti1)
	c["round"] = int(c["round"]) + 1
	# alla fine di ogni round le pozioni della Forza continuano fino a fine scontro
	_inizia_round()

func _avanza_mostro(ord: Array, da_fila: int, vuoti: Array) -> void:
	for col in [1, 0, 2]:
		var u: String = ord[da_fila][col]
		if u == "" or u == "hellgate": continue
		var possibili = vuoti.filter(func(v): return absi(v - col) <= 1)
		if possibili.is_empty(): continue
		var dest = possibili[0] if possibili.size() == 1 else scegli_a_caso(possibili)
		ord[da_fila - 1][dest] = u
		ord[da_fila][col] = ""
		annota("%s avanza in prima fila." % nome(u))
		return

# --------------------------------------------------------------------------------------------
# Fine del combattimento
# --------------------------------------------------------------------------------------------
func _controlla_fine_silenzioso() -> bool:
	var c: Dictionary = s.get("comb", {})
	if c.is_empty(): return true
	if c.get("tregua", false): return true
	var ostili = _ostili_svegli()
	var gruppo = unita_in(ordine_gruppo()).filter(func(x): return x.begins_with("p:") and unita(x).get("stato", "ok") == "ok")
	return ostili.is_empty() or gruppo.is_empty()

func _ostili_svegli() -> Array:
	var c: Dictionary = s["comb"]
	var r = []
	for u in unita_in(c["ordine_m"]):
		if u == "hellgate": continue
		var x = unita(u)
		if x.is_empty() or not vivo(x) or x.get("stato", "ok") in ["morto", "svanito"]: continue
		if x.get("dorme", false): continue
		r.append(u)
	return r

func _controlla_fine() -> bool:
	var c: Dictionary = s.get("comb", {})
	if c.is_empty(): return true
	if c.get("tregua", false):
		fine_combattimento("tregua")
		return true
	var gruppo = unita_in(ordine_gruppo()).filter(func(x): return x.begins_with("p:") and unita(x).get("stato", "ok") == "ok")
	if gruppo.is_empty():
		fine_combattimento("sconfitta")
		return true
	if _ostili_svegli().is_empty():
		# i dormienti vengono uccisi senza tiro (10.5 Sonno)
		for u in unita_in(c["ordine_m"]):
			if u == "hellgate": continue
			var x = unita(u)
			if x.get("dorme", false) and u.begins_with("m:"):
				annota("%s, addormentat%s, viene finit%s." % [x["nome"], "a" if x["nome"].ends_with("a") else "o", "a" if x["nome"].ends_with("a") else "o"])
				muore(u, "")
		fine_combattimento("vittoria")
		return true
	return false

## Implementata nel motore completo (flusso del turno)
func fine_combattimento(_esito: String) -> void:
	pass
