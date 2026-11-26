extends MotoreComb
class_name Motore
## Motore completo di Citadel of Blood: sequenza di gioco (5.0), movimento (6.0), trappole (7.0),
## negoziazione e corruzione (8.0), elementi delle stanze (13.0), tesori (14.0),
## Porta dell'Inferno (16.0), vittoria e campagna (12.0, 17.0).
##
## Il motore si ferma ogni volta che serve una decisione del giocatore: la descrive in s["scelta"]
## ({tipo, testo, opzioni:[{id, testo, azione, bersaglio, gruppo}]}) e riparte con scegli(id).

const PRIORITA_INC := ["bl", "lt", "he", "sl", "cm", "ma", "ms", "rj", "or", "cw", "sw", "mr", "np", "ex", "cf", "rd", "hs", "tl", "cj", "dn", "sf", "st", "tf", "lk"]

# ============================================================================================
# Nuova partita
# ============================================================================================
## config: {seme, eroi:[id], iniziati:[{nome, razza, femmina, arma2, esperienza, tiro_pm}], incantesimi:{id:[k]}}
func nuova_partita(config: Dictionary) -> void:
	var seme = int(config.get("seme", Time.get_ticks_usec()))
	rng.seed = seme
	s = {
		"versione": 1, "seme": seme, "turno": 0, "spedizione": 1, "sole": "giallo",
		"gruppo": {}, "ordine_ids": [], "ordine": [["", "", ""], ["", "", ""], ["", "", ""]],
		"tazza": range(tessere.size()), "mappe": {}, "pos": {"liv": 1, "xy": "0,0"}, "prec": {},
		"hellgate": {"liv": 0, "conto": -1, "serve_specchio": false, "trovata": false, "x_morto": false, "distrutta": false},
		"comb": {}, "incontro": {}, "scelta": {}, "diario": [], "fine": "", "seguito": "", "bottino": [],
		"alleati": {}, "casa": {}, "cont_mostri": 0, "tutorial": config.get("tutorial", false),
		"segmenti_esplorati": 0, "statistiche": {"uccisi": 0, "stanze": 0},
	}
	for id in config.get("eroi", []):
		s["gruppo"][id] = nuovo_pg_eroe(id)
		s["ordine_ids"].append(id)
	var n = 0
	for ini in config.get("iniziati", []):
		n += 1
		var id = "ini%d" % n
		var tiro: int = int(ini.get("tiro_pm", 0))
		if tiro <= 0:
			tiro = d6()
		s["gruppo"][id] = nuovo_pg_iniziato(id, ini.get("nome", "Iniziato"), ini.get("razza", "umano"), ini.get("femmina", false),
			ini.get("arma2", "pugnale"), ini.get("esperienza", "pf"), tiro)
		s["ordine_ids"].append(id)
	# incantesimi conosciuti (4.1 B6): tanti quanto il valore più alto del Potenziale Magico
	var scelti: Dictionary = config.get("incantesimi", {})
	for id in s["ordine_ids"]:
		var p = pg(id)
		var nmax = max_pm(p)
		var lista: Array = scelti.get(id, [])
		if lista.is_empty():
			lista = incantesimi_consigliati(p, nmax)
		p["inc_noti"] = lista.slice(0, nmax)
	# ordine di marcia iniziale: i più robusti davanti
	var ids: Array = s["ordine_ids"].duplicate()
	ids.sort_custom(func(a, b): return _forza_mischia(pg(a)) > _forza_mischia(pg(b)))
	var o = [["", "", ""], ["", "", ""], ["", "", ""]]
	for i in ids.size():
		o[int(i / 3)][i % 3] = "p:" + ids[i]
	s["ordine"] = o
	# il Portale del Male (4.1 F)
	var porta = {"t": -1, "lato": "portale", "rot": 0, "x": 0, "y": 0, "uscite": "*WWW", "tipo": "portale", "elemento": "",
		"visitato": true, "elemento_usato": true, "mostri": [], "chiuse": [], "hellgate": false, "ingresso": true, "scala_hub": false}
	mappa(1)["seg"]["0,0"] = porta
	annota("Il gruppo si raduna davanti al Portale del Male. Comincia la spedizione nella Cittadella di X lo Sconosciuto.", "titolo")
	inizio_spedizione()

func _forza_mischia(p: Dictionary) -> int:
	var a = arma(p)
	var f = int(p["bc"]) + int(p["pf_max"]) + int(p.get("abil", {}).get(a["tipo"], 0)) * 2
	if a["tipo"] == "arco": f -= 6
	return f

func incantesimi_consigliati(p: Dictionary, n: int) -> Array:
	var r = []
	for k in PRIORITA_INC:
		if r.size() >= n: break
		r.append(k)
	return r

## All'ingresso: sole dominante (4.1 D), limiti di Guarigione/Rigenerazione (10.6)
func inizio_spedizione() -> void:
	var t = d6()
	s["sole"] = D.SOLI[int((t - 1) / 2)]
	mostra_dadi([t], "Sole dominante")
	annota("Sole dominante: tira %d → %s." % [t, D.NOMI_SOLI[s["sole"]]], "dado")
	for id in s["ordine_ids"]:
		var p = pg(id)
		if p.get("stato", "ok") != "ok": continue
		p["ferite_ingresso"] = p["ferite"]
		var npm = pm_sole(p)
		var attivi = []
		for k in p["inc_noti"]:
			if attivi.size() < npm: attivi.append(k)
		for k in ["wg", "rs"]:
			if k in p.get("inc_speciali", []): attivi.append(k)
		p["inc_attivi"] = attivi
		p["usi_cura"] = {}
		for k in ["he", "rj"]:
			if k in attivi:
				var u = d6()
				p["usi_cura"][k] = u
				annota("%s potrà lanciare %s al massimo %d volte." % [p["nome"], D.INCANTESIMI[k]["nome"], u], "dado")
	_scelta_soli()

func _scelta_soli() -> void:
	var maghi = []
	for id in s["ordine_ids"]:
		var p = pg(id)
		if p.get("stato", "ok") == "ok" and p["inc_noti"].size() > pm_sole(p) and pm_sole(p) > 0:
			maghi.append(id)
	if maghi.is_empty():
		nuovo_turno()
		return
	s["scelta"] = {"tipo": "soli", "testo": "Sotto il %s ogni mago può usare solo una parte dei suoi incantesimi: scegli quali." % D.NOMI_SOLI[s["sole"]].to_lower(),
		"maghi": maghi, "opzioni": [{"id": "ok", "testo": "Conferma gli incantesimi", "azione": "ok", "bersaglio": "", "gruppo": ""}]}

# ============================================================================================
# Scelte
# ============================================================================================
func opzione(id: String) -> Dictionary:
	for o in s.get("scelta", {}).get("opzioni", []):
		if o["id"] == id:
			return o
	return {}

func scegli(id: String, extra: Dictionary = {}) -> void:
	var sc: Dictionary = s.get("scelta", {})
	if sc.is_empty(): return
	var o = opzione(id)
	if o.is_empty():
		push_warning("Opzione inesistente: " + id)
		return
	s["scelta"] = {}
	match sc["tipo"]:
		"soli": _esegui_soli(extra)
		"rotta": _esegui_rotta(o)
		"orienta": _esegui_orienta(o)
		"trappola": _esegui_trappola(o)
		"incontro": _esegui_incontro(o)
		"corruzione": _esegui_corruzione(o)
		"azione": esegui_azione(sc["chi"], o)
		"riorg": esegui_riorg(o)
		"rianima": _esegui_rianima(o)
		"tesoro": _esegui_tesoro(o, sc)
		"arma_sost": _esegui_arma_sost(o, sc)
		"elemento": _esegui_elemento(o)
		"si_no": _esegui_si_no(o, sc)
		"conferma": prosegui()
		"riposo": _esegui_riposo(o)
		"migliora": _esegui_migliora(o)
		"fine": pass
	if s.get("scelta", {}).is_empty() and s.get("fine", "") == "":
		push_warning("Il motore non ha prodotto una nuova scelta dopo " + sc["tipo"])

func _esegui_soli(extra: Dictionary) -> void:
	var sel: Dictionary = extra.get("selezione", {})
	for id in sel:
		var p = pg(id)
		if p.is_empty(): continue
		var lista: Array = sel[id]
		var npm = pm_sole(p)
		var attivi = []
		for k in lista:
			if k in p["inc_noti"] and attivi.size() < npm: attivi.append(k)
		for k in p["inc_attivi"]:
			if k in ["wg", "rs"]: attivi.append(k)
		p["inc_attivi"] = attivi
		for k in ["he", "rj"]:
			if k in attivi and not p["usi_cura"].has(k):
				p["usi_cura"][k] = d6()
	nuovo_turno()

## Il prossimo passo dopo un sotto-flusso concluso (tesoro, combattimento, elemento...)
func prosegui() -> void:
	if s.get("fine", "") != "": return
	if not s.get("bottino", []).is_empty():
		_distribuisci_prossimo()
		return
	var seg_: String = s.get("seguito", "")
	s["seguito"] = ""
	match seg_:
		"elemento":
			fase_elemento()
		"botola_risali":
			_botola_risali()
		_:
			nuovo_turno()

func conferma(testo: String, seguito: String = "") -> void:
	if seguito != "": s["seguito"] = seguito
	s["scelta"] = {"tipo": "conferma", "testo": testo, "opzioni": [{"id": "ok", "testo": "Prosegui", "azione": "ok", "bersaglio": "", "gruppo": ""}]}

# ============================================================================================
# Turno e movimento (5.0 A, 6.0)
# ============================================================================================
func nuovo_turno() -> void:
	if _controlla_sconfitta(): return
	s["turno"] = int(s["turno"]) + 1
	s["incontro"] = {}
	s["comb"] = {}
	sistema_ordine()
	var liv = int(s["pos"]["liv"])
	var seg = seg_attuale()
	var xy = da_chiave(s["pos"]["xy"])
	var opz = []
	for d in 4:
		var u = uscita(seg, d)
		if u == "W": continue
		var vk = chiave(xy + D.VETTORI[d])
		var vic = segmento(liv, vk)
		if vic.is_empty():
			if u == "*":
				opz.append({"id": "esp|%d|D" % d, "azione": "esplora", "bersaglio": "", "gruppo": "Movimento", "dir": d, "testo": "Entra nella Cittadella da una porta"})
				opz.append({"id": "esp|%d|C" % d, "azione": "esplora", "bersaglio": "", "gruppo": "Movimento", "dir": d, "testo": "Entra nella Cittadella da un corridoio"})
			else:
				opz.append({"id": "esp|%d|%s" % [d, u], "azione": "esplora", "bersaglio": "", "gruppo": "Movimento", "dir": d,
					"testo": "Esplora a %s (%s)" % [NOMI_DIR[d], "porta" if u == "D" else "corridoio"]})
		else:
			var ritorno = uscita(vic, (d + 2) % 4)
			if vic.get("ingresso", false): ritorno = "*"
			if ritorno == "W" or (ritorno != "*" and u != "*" and ritorno != u): continue
			var descr = "il Portale" if vic.get("ingresso", false) else ("stanza" if vic["tipo"] == "stanza" else "corridoio")
			opz.append({"id": "vai|%d" % d, "azione": "vai", "bersaglio": "", "gruppo": "Movimento", "dir": d,
				"testo": "Vai a %s (%s già esplorat%s)" % [NOMI_DIR[d], descr, "a" if descr == "stanza" else "o"]})
	if seg.get("elemento", "") == "scala" and seg["tipo"] == "stanza":
		if liv == 1:
			opz.append({"id": "liv|2", "azione": "livello", "bersaglio": "", "gruppo": "Scala", "testo": "Scendi la scala fino al livello 2"})
			opz.append({"id": "liv|3", "azione": "livello", "bersaglio": "", "gruppo": "Scala", "testo": "Scendi la scala fino al livello 3"})
		else:
			opz.append({"id": "liv|1", "azione": "livello", "bersaglio": "", "gruppo": "Scala", "testo": "Risali la scala fino al livello 1"})
	if seg.get("ingresso", false) and int(s["turno"]) > 1:
		opz.append({"id": "esci", "azione": "esci", "bersaglio": "", "gruppo": "Uscita", "testo": "Esci dalla Cittadella"})
	if seg.get("hellgate", false) and s["hellgate"].get("x_morto", false) and not s["hellgate"].get("distrutta", false):
		for id in pg_in_gruppo():
			var p = pg(id)
			if int(p.get("hellgate", 0)) > 0:
				opz.append({"id": "dis|" + id, "azione": "distruggi", "bersaglio": "p:" + id, "gruppo": "Porta dell'Inferno",
					"testo": "%s tenta di distruggere la Porta (abilità %d)" % [p["nome"], int(p["hellgate"])]})
	if opz.is_empty():
		opz.append({"id": "esci", "azione": "esci", "bersaglio": "", "gruppo": "Uscita", "testo": "Nessuna via: torna all'uscita"})
	s["scelta"] = {"tipo": "rotta", "testo": "Turno %d · livello %d: dove va il gruppo?" % [int(s["turno"]), liv], "opzioni": opz}

func _esegui_rotta(o: Dictionary) -> void:
	var parti: PackedStringArray = String(o["id"]).split("|")
	match parti[0]:
		"esp": esplora(int(parti[1]), parti[2])
		"vai":
			var xy = da_chiave(s["pos"]["xy"]) + D.VETTORI[int(parti[1])]
			entra(int(s["pos"]["liv"]), chiave(xy), false, uscita(seg_attuale(), int(parti[1])) == "D")
		"liv": cambia_livello(int(parti[1]))
		"esci": fine_spedizione()
		"dis": tenta_distruzione(parti[1])

## Pesca e piazza una tessera (5.0 A2-A3, 6.1-6.4)
func esplora(d: int, tipo: String) -> void:
	var liv = int(s["pos"]["liv"])
	var xy = da_chiave(s["pos"]["xy"]) + D.VETTORI[d]
	var lato = "fronte" if tipo == "D" else "retro"
	var entrata = (d + 2) % 4
	var rimesse = []
	var scelta_t = -1
	var rot_valide = []
	var tentativi = 0
	while true:
		var t = pesca_tessera()
		if t < 0: break
		tentativi += 1
		var rr = orientamenti(liv, t, lato, xy, entrata, tipo, true)
		# niente vicoli ciechi prima di trovare la Porta (6.4)
		if not s["hellgate"]["trovata"]:
			rr = rr.filter(func(rot): return frontiera_aperta(liv, {chiave(xy): nuovo_segmento(t, lato, rot, xy)}) > 0)
		if not rr.is_empty():
			scelta_t = t
			rot_valide = rr
			break
		rimesse.append(t)
	for t in rimesse: rimetti_tessera(t)
	if scelta_t < 0:
		# nessuna tessera combacia: si usa quella più adatta, i lati che non combaciano sono impraticabili (6.1)
		var tazza: Array = s["tazza"]
		for t in tazza:
			var rr2 = orientamenti(liv, int(t), lato, xy, entrata, tipo, false)
			if not rr2.is_empty():
				scelta_t = int(t)
				rot_valide = rr2
				tazza.erase(t)
				break
		if scelta_t < 0:
			# tazza vuota: si riusa una tessera già piazzata altrove
			scelta_t = 0 if lato == "fronte" else 1
			rot_valide = orientamenti(liv, scelta_t, lato, xy, entrata, tipo, false)
			if rot_valide.is_empty(): rot_valide = [0]
		annota("Nessuna tessera combacia perfettamente: i lati che non combaciano restano chiusi.")
	if tentativi > 1:
		annota("Pescate %d tessere prima di trovarne una che combaci." % tentativi)
	s["pendente"] = {"liv": liv, "xy": chiave(xy), "t": scelta_t, "lato": lato, "porta": tipo == "D"}
	if rot_valide.size() == 1:
		_piazza(rot_valide[0])
		return
	var opz = []
	for rot in rot_valide:
		var u = ruota_uscite(faccia(scelta_t, lato)["uscite"], rot)
		opz.append({"id": "rot|%d" % rot, "azione": "orienta", "bersaglio": "", "gruppo": "Orientamento", "rot": rot,
			"testo": "Uscite: " + descrivi_uscite(u)})
	evento({"tipo": "anteprima", "liv": liv, "xy": chiave(xy), "t": scelta_t, "lato": lato, "rot": rot_valide})
	s["scelta"] = {"tipo": "orienta", "testo": "Hai pescato %s. Come la orienti?" % ("una stanza" if lato == "fronte" else "un corridoio"), "opzioni": opz}

func _esegui_orienta(o: Dictionary) -> void:
	_piazza(int(o["rot"]))

func _piazza(rot: int) -> void:
	var p: Dictionary = s["pendente"]
	var liv = int(p["liv"])
	var xy = da_chiave(p["xy"])
	var seg = nuovo_segmento(int(p["t"]), p["lato"], rot, xy)
	mappa(liv)["seg"][p["xy"]] = seg
	s["segmenti_esplorati"] = int(s.get("segmenti_esplorati", 0)) + 1
	evento({"tipo": "tessera", "liv": liv, "xy": p["xy"]})
	annota("Nuova tessera: %s%s." % ["stanza" if seg["tipo"] == "stanza" else "corridoio",
		(" con " + D.ELEMENTI[seg["elemento"]].to_lower()) if seg["elemento"] != "" else ""])
	s.erase("pendente")
	entra(liv, p["xy"], true, bool(p["porta"]))

func cambia_livello(dest: int) -> void:
	var m = mappa(dest)
	var hub: String = m.get("hub", "")
	var nuovo = false
	if hub == "":
		var t = cerca_scala_in_tazza()
		if t < 0:
			t = seg_attuale().get("t", 36)
		var seg = nuovo_segmento(t, "fronte", 0, Vector2i(0, 0))
		seg["scala_hub"] = true
		m["seg"]["0,0"] = seg
		m["hub"] = "0,0"
		hub = "0,0"
		nuovo = true
		evento({"tipo": "tessera", "liv": dest, "xy": hub})
		annota("Il gruppo scende per la prima volta al livello %d: comincia un nuovo labirinto." % dest if dest > 1 else "Il gruppo risale al livello 1.")
	else:
		annota("Il gruppo %s la scala fino al livello %d." % ["scende" if dest > int(s["pos"]["liv"]) else "risale", dest])
	if int(s["pos"]["liv"]) == 1 and mappa(1).get("hub", "") == "":
		mappa(1)["hub"] = s["pos"]["xy"]
	entra(dest, hub, nuovo, true)

## Entrata in un segmento: trappole (B), movimento e mostri (C)
func entra(liv: int, k: String, nuovo: bool, via_porta: bool) -> void:
	var seg = segmento(liv, k)
	s["entrata"] = {"liv": liv, "xy": k, "nuovo": nuovo, "porta": via_porta, "prima_volta": not seg.get("visitato", false)}
	if seg["tipo"] == "stanza" and not seg.get("visitato", false):
		var t = d6()
		mostra_dadi([t], "Controllo della porta")
		if t == 1:
			annota("La porta è protetta da una trappola!", "evento")
			_scelta_trappola("porta")
			return
		annota("La porta non è protetta da trappole (tiro %d)." % t, "dado")
	_entra_dopo_trappola()

func _scelta_trappola(cosa: String) -> void:
	var opz = []
	for id in pg_in_gruppo():
		var p = pg(id)
		var dis = int(p.get("disinnesco", 0))
		opz.append({"id": "tr|" + id + "|", "azione": "trappola", "bersaglio": "p:" + id, "gruppo": "Chi controlla",
			"testo": "%s %s" % [p["nome"], ("(Disinnesco %d)" % dis) if dis > 0 else "(non sa disinnescare)"]})
		if dis > 0:
			for mago in pg_in_gruppo():
				var pm = pg(mago)
				if "tf" in incantesimi_usabili("p:" + mago, ["NC"]):
					opz.append({"id": "tr|%s|%s" % [id, mago], "azione": "trappola", "bersaglio": "p:" + id, "gruppo": "Con l'incantesimo Ladro",
						"testo": "%s con Ladro di %s (Disinnesco %d, 1 PF)" % [p["nome"], pm["nome"], mini(dis + 3, 8)]})
	s["trappola_su"] = cosa
	s["scelta"] = {"tipo": "trappola", "testo": "Trappola! Chi prova a disinnescarla?", "opzioni": opz}

func _esegui_trappola(o: Dictionary) -> void:
	var parti: PackedStringArray = String(o["id"]).split("|")
	var id = parti[1]
	var mago = parti[2]
	var p = pg(id)
	var dis = int(p.get("disinnesco", 0))
	if mago != "":
		var pm = pg(mago)
		pm["ferite"] = int(pm["ferite"]) + 1
		dis += 3
		annota("%s lancia Ladro su %s." % [pm["nome"], p["nome"]], "magia")
	dis = mini(dis, 8)
	var ok = false
	if dis > 0:
		var t = d6()
		mostra_dadi([t], "Disinnesco di %s" % p["nome"])
		ok = t <= dis
		annota("%s prova a disinnescare: tira %d contro %d → %s." % [p["nome"], t, dis, "disinnescata!" if ok else "scatta!"], "dado")
	else:
		annota("%s non sa disinnescare: la trappola scatta." % p["nome"])
	if not ok:
		scatta_trappola(id)
	var cosa: String = s.get("trappola_su", "porta")
	s.erase("trappola_su")
	if _controlla_sconfitta(): return
	match cosa:
		"porta": _entra_dopo_trappola()
		"forziere": _dopo_forziere()
		"botola": _dopo_trappola_elemento("botola")
		"scrittoio": _dopo_trappola_elemento("scrittoio")

## Tabella delle Trappole (7.1, 7.2)
func scatta_trappola(id: String) -> void:
	var p = pg(id)
	var t = d6()
	var tipo: String = D.TRAPPOLE[t - 1]
	mostra_dadi([t], "Tabella delle trappole")
	annota("Trappola (tiro %d): %s!" % [t, D.NOMI_TRAPPOLE[tipo]], "evento")
	evento({"tipo": "trappola", "uid": "p:" + id, "var": tipo})
	match tipo:
		"freccia", "freccia_avvelenata":
			var t2 = d6()
			var n = D.ferite_crt("arco", t2)
			annota("La freccia (tiro %d sulla colonna Arco) %s." % [t2, "manca %s" % p["nome"] if n == 0 else "colpisce %s: %d ferit%s" % [p["nome"], n, "a" if n == 1 else "e"]], "dado")
			if n > 0:
				danneggia("p:" + id, n, "una freccia", false)
				if tipo == "freccia_avvelenata" and vivo(p):
					avvelena(id, d3(), "la punta avvelenata")
		"gas":
			avvelena(id, d3(), "il gas velenoso")
		"esplosione":
			for x in pg_in_gruppo():
				danneggia("p:" + x, 1, "l'esplosione", false)
			for m in s.get("alleati", {}).keys():
				danneggia(m, 1, "l'esplosione", false)
			annota("L'esplosione ferisce tutto il gruppo (1 ferita ciascuno).")
		"olio":
			danneggia("p:" + id, 1, "l'olio bollente", false)
			annota("%s è ustionato dall'olio bollente (1 ferita)." % p["nome"])
		"doppia":
			annota("Due trappole scattano insieme!")
			if vivo(p): scatta_trappola(id)
			if vivo(p): scatta_trappola(id)

## Veleno: medaglione/anello Neutralizza Veleno o l'incantesimo (10.6)
func avvelena(id: String, n: int, fonte: String) -> void:
	var p = pg(id)
	if ha_oggetto(p, "medaglione", "neutralizza"):
		annota("Il medaglione rende %s immune a %s." % [p["nome"], fonte], "magia")
		return
	for o in p.get("oggetti", []):
		if o.get("tipo") == "anello" and o.get("var") == "neutralizza" and not o.get("usato", false):
			o["usato"] = true
			annota("%s usa l'Anello Neutralizza Veleno contro %s." % [p["nome"], fonte], "magia")
			return
	for mago in pg_in_gruppo():
		var pm = pg(mago)
		if "np" in incantesimi_usabili("p:" + mago, ["NC"]) and pf_residui(pm) > 2:
			pm["ferite"] = int(pm["ferite"]) + 1
			annota("%s lancia subito Neutralizza veleno su %s." % [pm["nome"], p["nome"]], "magia")
			return
	annota("%s subisce %d ferit%s per %s." % [p["nome"], n, "a" if n == 1 else "e", fonte])
	danneggia("p:" + id, n, fonte, false)

func _entra_dopo_trappola() -> void:
	var e: Dictionary = s["entrata"]
	var liv = int(e["liv"])
	var k: String = e["xy"]
	var seg = segmento(liv, k)
	s["prec"] = s["pos"].duplicate()
	s["pos"] = {"liv": liv, "xy": k}
	var era_visitato: bool = seg.get("visitato", false)
	seg["visitato"] = true
	if seg["tipo"] == "stanza" and not era_visitato:
		s["statistiche"]["stanze"] = int(s["statistiche"]["stanze"]) + 1
	evento({"tipo": "muovi", "liv": liv, "xy": k})
	# conto alla rovescia della Porta dell'Inferno (13.7)
	var hg: Dictionary = s["hellgate"]
	if bool(e["nuovo"]) and int(hg["liv"]) == liv and int(hg["conto"]) > 0 and not hg["trovata"]:
		hg["conto"] = int(hg["conto"]) - 1
		if int(hg["conto"]) == 0:
			seg["hellgate"] = true
			hg["trovata"] = true
	if seg.get("hellgate", false) and not hg.get("x_morto", false):
		battaglia_hellgate()
		return
	if seg.get("hellgate", false):
		annota("Il gruppo è davanti alla Porta dell'Inferno spenta.")
		nuovo_turno()
		return
	# mostri lasciati qui in precedenza (6.9)
	if not seg.get("mostri", []).is_empty():
		var lista: Array = seg["mostri"]
		seg["mostri"] = []
		annota("I mostri incontrati qui in precedenza sono ancora presenti.", "evento")
		apri_incontro(lista, "ritorno", via_porta_attuale())
		return
	var t = d6()
	var prima_volta: bool = seg["tipo"] == "stanza" and not era_visitato
	mostra_dadi([t], "Controllo dei mostri")
	if prima_volta and t <= 3:
		annota("Controllo dei mostri: %d → la stanza è abitata!" % t, "dado")
		apri_incontro(tira_incontro(true, liv), "stanza", via_porta_attuale())
		return
	if not prima_volta and t == 1:
		annota("Controllo dei mostri erranti: 1 → arrivano dei mostri!", "dado")
		apri_incontro(tira_incontro(false, liv), "errante", via_porta_attuale())
		return
	annota("Controllo dei mostri: %d → nessun mostro." % t, "dado")
	fase_elemento()

func via_porta_attuale() -> bool:
	return bool(s.get("entrata", {}).get("porta", false))

# ============================================================================================
# Incontri: negoziazione e corruzione (8.4 - 8.9)
# ============================================================================================
func apri_incontro(mostri: Array, origine: String, via_porta: bool, opz: Dictionary = {}) -> void:
	var dict = {}
	for m in mostri:
		dict[m["uid"]] = m
	s["incontro"] = {"mostri": dict, "origine": origine, "porta": via_porta, "negoziato": false, "corrotto": false,
		"oratoria": 0, "sconto": 0, "seguito": opz.get("seguito", "elemento"), "solo": opz.get("solo", ""),
		"no_trattativa": opz.get("no_trattativa", false), "unisci_dal_round": int(opz.get("unisci_dal_round", 0)), "esito": ""}
	evento({"tipo": "incontro", "mostri": dict.keys()})
	_scelta_incontro()

func _mostro_rappresentativo() -> Dictionary:
	var inc: Dictionary = s["incontro"]
	var best = {}
	for k in inc["mostri"]:
		var m: Dictionary = inc["mostri"][k]
		if best.is_empty() or int(m["pf_max"]) > int(best["pf_max"]): best = m
	return best

func _scelta_incontro() -> void:
	var inc: Dictionary = s["incontro"]
	if inc["mostri"].is_empty():
		_chiudi_incontro()
		return
	var m = _mostro_rappresentativo()
	var trattabile: bool = int(m["vn"]) >= 0 and not inc["no_trattativa"]
	var opz = []
	var squadra = pg_in_gruppo() if inc["solo"] == "" else [inc["solo"]]
	var testo_m = _descrivi_mostri()
	if inc["esito"] in ["accordo", "intimidazione"]:
		opz.append({"id": "lascia", "azione": "lascia", "bersaglio": "", "gruppo": "Prosegui", "testo": "Lasciali in pace e prosegui"})
		opz.append({"id": "attacca", "azione": "combatti", "bersaglio": "", "gruppo": "Combatti", "testo": "Attaccali comunque"})
		s["scelta"] = {"tipo": "incontro", "testo": "%s ti lasciano passare." % testo_m, "opzioni": opz}
		return
	if trattabile and not inc["negoziato"]:
		for id in squadra:
			var p = pg(id)
			var bonus = int(p.get("negoziazione", 0)) + int(inc["oratoria"])
			if ha_oggetto(p, "medaglione", "oratoria"): bonus += 3
			opz.append({"id": "neg|" + id, "azione": "negozia", "bersaglio": "p:" + id, "gruppo": "Negozia",
				"testo": "%s negozia (2D6 − %d %+d)" % [p["nome"], int(m["vn"]), bonus]})
		for id in squadra:
			for k in incantesimi_usabili("p:" + id, ["N"]):
				if k == "or" and int(inc["oratoria"]) > 0: continue
				opz.append({"id": "incn|%s|%s" % [id, k], "azione": "inc_" + k, "bersaglio": "", "gruppo": "Incantesimi di negoziazione",
					"testo": "%s lancia %s (%d PF)" % [pg(id)["nome"], D.INCANTESIMI[k]["nome"], costo_incantesimo(pg(id), k)]})
	if trattabile and not inc["corrotto"] and _oro_gruppo() >= 20:
		opz.append({"id": "corr", "azione": "corrompi", "bersaglio": "", "gruppo": "Corrompi", "testo": "Offri dell'oro (oro del gruppo: %d)" % _oro_gruppo()})
		for id in squadra:
			for k in incantesimi_usabili("p:" + id, ["B"]):
				if int(inc["sconto"]) > 0: continue
				opz.append({"id": "incb|%s|%s" % [id, k], "azione": "inc_" + k, "bersaglio": "", "gruppo": "Incantesimi di corruzione",
					"testo": "%s lancia %s (%d PF)" % [pg(id)["nome"], D.INCANTESIMI[k]["nome"], costo_incantesimo(pg(id), k)]})
	# Serratura: richiudere la porta e tornare indietro (10.6)
	if inc["porta"] and inc["solo"] == "" and seg_attuale()["tipo"] == "stanza" and not s.get("prec", {}).is_empty() and inc["origine"] in ["stanza", "errante", "ritorno"]:
		for id in squadra:
			if "lk" in incantesimi_usabili("p:" + id, ["NC"]):
				opz.append({"id": "lock|" + id, "azione": "serratura", "bersaglio": "", "gruppo": "Altri incantesimi",
					"testo": "%s richiude la porta con Serratura (1 PF) e il gruppo torna indietro" % pg(id)["nome"]})
				break
	# Teletrasporto di un mostro (10.6)
	for id in squadra:
		if "tl" in incantesimi_usabili("p:" + id, ["NC"]):
			for k in inc["mostri"]:
				if inc["mostri"][k]["tipo"] in ["x", "demone"]: continue
				opz.append({"id": "tele|%s|%s" % [id, k], "azione": "teletrasporto", "bersaglio": k, "gruppo": "Altri incantesimi",
					"testo": "%s teletrasporta %s altrove (3 PF)" % [pg(id)["nome"], inc["mostri"][k]["nome"]]})
			break
	# pozioni di fascino (14.5)
	for id in squadra:
		var p2 = pg(id)
		for i in p2["oggetti"].size():
			var ob: Dictionary = p2["oggetti"][i]
			if ob.get("tipo") != "pozione": continue
			if ob.get("var") in ["fascino_persone", "fascino_mostri"]:
				for k in inc["mostri"]:
					var mt: String = inc["mostri"][k]["tipo"]
					var persona: bool = mt in ["eroe_m", "mago_m", "orco", "troll"]
					if mt in ["x", "demone"]: continue
					if (ob["var"] == "fascino_persone") == persona:
						opz.append({"id": "poz|%s|%d|%s" % [id, i, k], "azione": "pozione", "bersaglio": k, "gruppo": "Pozioni",
							"testo": "%s beve la %s su %s" % [p2["nome"], D.NOMI_POZIONI[ob["var"]], inc["mostri"][k]["nome"]]})
	opz.append({"id": "comb", "azione": "combatti", "bersaglio": "", "gruppo": "Combatti", "testo": "Combatti!"})
	var info = ""
	if not trattabile and int(m["vn"]) < 0:
		info = " Con demoni e con X lo Sconosciuto non si tratta: si combatte."
	elif inc["negoziato"]:
		info = " La negoziazione è fallita."
	s["scelta"] = {"tipo": "incontro", "testo": "%s!%s Che cosa fa il gruppo?" % [testo_m, info], "opzioni": opz}

func _descrivi_mostri() -> String:
	var inc: Dictionary = s["incontro"]
	var conta = {}
	for k in inc["mostri"]:
		var t: String = inc["mostri"][k]["tipo"]
		conta[t] = int(conta.get(t, 0)) + 1
	var parti = []
	for t in conta:
		parti.append(("%d %s" % [conta[t], D.MOSTRI[t]["plur"]]) if int(conta[t]) > 1 else D.MOSTRI[t]["nome"])
	return ", ".join(parti)

func _oro_gruppo() -> int:
	var t = 0
	for id in pg_in_gruppo():
		t += int(pg(id).get("oro", 0))
	return t

func _togli_oro(n: int) -> void:
	var resto = n
	var ids = pg_in_gruppo()
	ids.sort_custom(func(a, b): return int(pg(a)["oro"]) > int(pg(b)["oro"]))
	for id in ids:
		var p = pg(id)
		var x = mini(int(p["oro"]), resto)
		p["oro"] = int(p["oro"]) - x
		resto -= x
		if resto <= 0: break

func _dai_oro(n: int) -> void:
	var ids = pg_in_gruppo()
	if ids.is_empty() or n <= 0: return
	var parte = int(n / ids.size())
	for i in ids.size():
		pg(ids[i])["oro"] = int(pg(ids[i])["oro"]) + parte + (n % ids.size() if i == 0 else 0)

func _esegui_incontro(o: Dictionary) -> void:
	var inc: Dictionary = s["incontro"]
	var parti: PackedStringArray = String(o["id"]).split("|")
	match parti[0]:
		"neg": negozia(parti[1])
		"incn", "incb":
			var p = pg(parti[1])
			var k = parti[2]
			annota("%s lancia %s." % [p["nome"], D.INCANTESIMI[k]["nome"]], "magia")
			if not paga(p, k):
				_scelta_incontro()
				return
			match k:
				"or":
					inc["oratoria"] = 4
					annota("Oratoria: +4 alla prossima negoziazione.")
					_scelta_incontro()
				"sw":
					inc["sconto"] = 2
					annota("Persuasione: −2 al tiro di corruzione.")
					_scelta_incontro()
				"cj":
					inc["sconto"] = 4
					annota("Lusinga: −4 al tiro di corruzione.")
					_scelta_incontro()
				"cw", "dn":
					inc["negoziato"] = true
					var m = _mostro_rappresentativo()
					if resiste(m["uid"], D.INCANTESIMI[k]["nome"]):
						annota("I mostri non si lasciano intimorire.")
						_scelta_incontro()
					else:
						if k == "dn":
							annota("Soggiogati, i mostri consegnano tutto il loro tesoro!", "evento")
							_tesoro_da_incontro(1.0)
						else:
							annota("Intimoriti, i mostri cedono un quarto del loro oro.", "evento")
							_tesoro_da_incontro(0.25)
						inc["esito"] = "intimidazione"
						prosegui_o(_scelta_incontro)
		"corr": _scelta_corruzione()
		"comb": _combatti_incontro(false)
		"attacca":
			inc["esito"] = ""
			_combatti_incontro(false)
		"lascia":
			_lascia_mostri()
			_chiudi_incontro()
		"lock":
			var p2 = pg(parti[1])
			p2["ferite"] = int(p2["ferite"]) + 1
			var prec: Dictionary = s["prec"]
			var da = da_chiave(prec["xy"])
			var a = da_chiave(s["pos"]["xy"])
			var d = D.VETTORI.find(a - da)
			if d >= 0 and int(prec["liv"]) == int(s["pos"]["liv"]):
				var sp = segmento(int(prec["liv"]), prec["xy"])
				sp["chiuse"].append(d)
				seg_attuale()["chiuse"].append((d + 2) % 4)
			_lascia_mostri()
			s["pos"] = prec.duplicate()
			evento({"tipo": "muovi", "liv": int(prec["liv"]), "xy": prec["xy"]})
			annota("%s sigilla la porta con Serratura: i mostri restano chiusi dentro per sempre." % p2["nome"], "magia")
			s["incontro"] = {}
			nuovo_turno()
		"tele":
			var p3 = pg(parti[1])
			var k2 = parti[2]
			if not paga(p3, "tl"):
				_scelta_incontro()
				return
			var m2: Dictionary = inc["mostri"][k2]
			inc["mostri"].erase(k2)
			var dest = _segmento_a_caso_visitato()
			if dest != "":
				segmento(int(s["pos"]["liv"]), dest)["mostri"].append(m2)
			annota("%s teletrasporta %s in un'altra parte del labirinto." % [p3["nome"], m2["nome"]], "magia")
			_scelta_incontro()
		"poz":
			var p4 = pg(parti[1])
			var ob: Dictionary = p4["oggetti"][int(parti[2])]
			p4["oggetti"].remove_at(int(parti[2]))
			var m3: Dictionary = inc["mostri"][parti[3]]
			inc["mostri"].erase(parti[3])
			if not s.has("alleati"): s["alleati"] = {}
			m3["incantato_da"] = p4["id"]
			s["alleati"][m3["uid"]] = m3
			annota("%s beve la %s: %s ora combatte per il gruppo!" % [p4["nome"], D.NOMI_POZIONI[ob["var"]], m3["nome"]], "magia")
			sistema_ordine()
			_scelta_incontro()

func prosegui_o(f: Callable) -> void:
	if not s.get("bottino", []).is_empty():
		s["seguito_incontro"] = true
		_distribuisci_prossimo()
	else:
		f.call()

func _segmento_a_caso_visitato() -> String:
	var lista = []
	var seg: Dictionary = mappa(int(s["pos"]["liv"]))["seg"]
	for k in seg:
		if seg[k].get("visitato", false) and k != s["pos"]["xy"] and not seg[k].get("ingresso", false):
			lista.append(k)
	if lista.is_empty(): return ""
	return lista[rng.randi_range(0, lista.size() - 1)]

func negozia(id: String) -> void:
	var inc: Dictionary = s["incontro"]
	inc["negoziato"] = true
	var p = pg(id)
	var m = _mostro_rappresentativo()
	var a = d6()
	var b = d6()
	var bonus = int(p.get("negoziazione", 0)) + int(inc["oratoria"])
	if ha_oggetto(p, "medaglione", "oratoria"): bonus += 3
	var tot = a + b - int(m["vn"]) + bonus
	var esito = D.esito_negoziazione(tot)
	mostra_dadi([a, b], "Negoziazione")
	annota("%s negozia: %d+%d − %d (Valore di Negoziazione) %+d = %d → %s." % [p["nome"], a, b, int(m["vn"]), bonus, tot,
		{"fallimento": "Fallimento", "accordo": "Accordo", "intimidazione": "Intimidazione"}[esito]], "dado")
	inc["oratoria"] = 0
	match esito:
		"fallimento":
			_scelta_incontro()
		"accordo":
			inc["esito"] = "accordo"
			annota("Accordo: i mostri lasciano in pace il gruppo.", "evento")
			_scelta_incontro()
		"intimidazione":
			inc["esito"] = "intimidazione"
			annota("I mostri sono intimiditi e cedono un quarto del loro oro.", "evento")
			_tesoro_da_incontro(0.25)
			prosegui_o(_scelta_incontro)

func _tesoro_da_incontro(frazione: float) -> void:
	var inc: Dictionary = s["incontro"]
	var oro = 0
	for k in inc["mostri"]:
		var t = genera_tesoro(inc["mostri"][k]["tesoro"])
		if frazione >= 1.0:
			_aggiungi_tesoro(t)
		else:
			oro += int(t["oro"])
	if frazione < 1.0:
		var parte = int(oro * frazione)
		_dai_oro(parte)
		annota("Il gruppo riceve %d marchi d'oro." % parte)

func _scelta_corruzione() -> void:
	var m = _mostro_rappresentativo()
	var v = int(m["pf_max"]) - int(m["ferite"]) + int(m["vn"])
	var col = D.colonna_corruzione(v)
	var oro = _oro_gruppo()
	var opz = []
	for i in D.CORRUZIONE_OFFERTE.size():
		var off: int = D.CORRUZIONE_OFFERTE[i]
		if off > oro: break
		var serve: int = D.CORRUZIONE[i][col]
		var sconto = int(s["incontro"]["sconto"])
		var prob = clampi(serve + sconto, 0, 6)
		opz.append({"id": "off|%d" % off, "azione": "offri", "bersaglio": "", "gruppo": "Offerta",
			"testo": "Offri %d marchi (riesce con %s: %d su 6)" % [off, ("1D6 ≤ %d" % serve) + (" (−%d)" % sconto if sconto > 0 else ""), prob]})
	opz.append({"id": "annulla", "azione": "annulla", "bersaglio": "", "gruppo": "Altro", "testo": "Non offrire nulla"})
	s["scelta"] = {"tipo": "corruzione", "testo": "Corruzione: %s ha %d PF + %d di Negoziazione = %d (colonna %s). Quanto offri?" % [m["nome"], int(m["pf_max"]) - int(m["ferite"]), int(m["vn"]), v, D.CORRUZIONE_COLONNE[col]],
		"opzioni": opz, "colonna": col}

func _esegui_corruzione(o: Dictionary) -> void:
	var inc: Dictionary = s["incontro"]
	if o["id"] == "annulla":
		_scelta_incontro()
		return
	inc["corrotto"] = true
	var off = int(String(o["id"]).split("|")[1])
	var m = _mostro_rappresentativo()
	var v = int(m["pf_max"]) - int(m["ferite"]) + int(m["vn"])
	var col = D.colonna_corruzione(v)
	var serve: int = D.CORRUZIONE[D.CORRUZIONE_OFFERTE.find(off)][col]
	var t = d6()
	var tot = t - int(inc["sconto"])
	_togli_oro(off)
	mostra_dadi([t], "Corruzione")
	annota("Il gruppo offre %d marchi: tira %d%s = %d contro %d → %s." % [off, t, (" − %d" % int(inc["sconto"])) if int(inc["sconto"]) > 0 else "", tot, serve,
		"accettano!" if tot <= serve else "rifiutano e attaccano!"], "dado")
	if tot <= serve:
		inc["esito"] = "accordo"
		inc["oro_dato"] = off
		_scelta_incontro()
	else:
		_combatti_incontro(true, off)

func _lascia_mostri() -> void:
	var inc: Dictionary = s["incontro"]
	var seg = seg_attuale()
	for k in inc["mostri"]:
		seg["mostri"].append(inc["mostri"][k])

func _combatti_incontro(mostri_primi: bool, oro_corruzione: int = 0) -> void:
	var inc: Dictionary = s["incontro"]
	var lista = []
	for k in inc["mostri"]:
		lista.append(inc["mostri"][k])
	var opz = {"mostri_primi": mostri_primi, "oro_corruzione": oro_corruzione, "solo": inc.get("solo", ""),
		"unisci_dal_round": inc.get("unisci_dal_round", 0)}
	_inizia_con_esitazione(lista, opz)

## Esitazione (10.5): prima del combattimento si possono usare cure. Si offre se qualcuno la conosce.
func _inizia_con_esitazione(lista: Array, opz: Dictionary) -> void:
	s["comb_attesa"] = {"mostri": lista, "opz": opz}
	var maghi = []
	for id in pg_in_gruppo():
		if "hs" in incantesimi_usabili("p:" + id, ["C"]):
			maghi.append(id)
	var feriti = pg_in_gruppo().filter(func(x): return int(pg(x)["ferite"]) > 0)
	if not maghi.is_empty() and not feriti.is_empty() and opz.get("solo", "") == "":
		var o = [{"id": "no", "testo": "Combatti subito", "azione": "no", "bersaglio": "", "gruppo": ""}]
		o.append({"id": "si|" + maghi[0], "testo": "%s lancia Esitazione (2 PF): un momento per curarsi" % pg(maghi[0])["nome"], "azione": "si", "bersaglio": "", "gruppo": ""})
		s["scelta"] = {"tipo": "si_no", "tag": "esitazione", "testo": "Il combattimento sta per cominciare.", "opzioni": o}
		return
	_avvia_comb_attesa()

func _avvia_comb_attesa() -> void:
	var ca: Dictionary = s.get("comb_attesa", {})
	s.erase("comb_attesa")
	s["incontro"]["mostri"] = {}
	# pozioni o incantesimi della Forza preparati (14.5)
	for id in pg_in_gruppo():
		var p = pg(id)
		if int(p.get("forza_prossimo", 0)) > 0:
			p["bc_temp"] = int(p.get("bc_temp", 0)) + int(p["forza_prossimo"])
			annota("%s combatte con +%d al Bonus di Combattimento (Forza)." % [p["nome"], int(p["forza_prossimo"])])
			p["forza_prossimo"] = 0
	inizia_combattimento(ca["mostri"], ca["opz"])

func _chiudi_incontro() -> void:
	var inc: Dictionary = s.get("incontro", {})
	var seguito: String = inc.get("seguito", "elemento")
	s["incontro"] = {}
	if seguito == "elemento":
		fase_elemento()
	elif seguito == "botola_risali":
		_botola_risali()
	else:
		nuovo_turno()

# ============================================================================================
# Porta dell'Inferno (16.0)
# ============================================================================================
func battaglia_hellgate() -> void:
	var liv = int(s["pos"]["liv"])
	var n = d3() + 2
	annota("Ecco la PORTA DELL'INFERNO! X lo Sconosciuto e %d demoni la difendono." % n, "titolo")
	evento({"tipo": "hellgate"})
	var lista = []
	for i in n:
		var dm = crea_mostro("demone", liv, false)
		lista.append(dm)
	lista.append(crea_mostro("x", liv, false))
	s["incontro"] = {"mostri": {}, "origine": "hellgate", "porta": false, "negoziato": true, "corrotto": true, "oratoria": 0, "sconto": 0,
		"seguito": "turno", "solo": "", "no_trattativa": true, "unisci_dal_round": 0, "esito": ""}
	_inizia_con_esitazione(lista, {"hellgate": true})

func tenta_distruzione(id: String) -> void:
	var p = pg(id)
	var t = d6()
	var abil = int(p.get("hellgate", 0))
	mostra_dadi([t], "Distruzione della Porta")
	if t <= abil:
		s["hellgate"]["distrutta"] = true
		annota("%s tira %d contro %d: la PORTA DELL'INFERNO È DISTRUTTA!" % [p["nome"], t, abil], "titolo")
		evento({"tipo": "hellgate_distrutta"})
		for id2 in s["ordine_ids"]:
			if pg(id2).get("stato", "") == "prigioniero":
				pg(id2)["stato"] = "ok"
				annota("%s, prigioniero della Porta, è libero e torna nel gruppo." % pg(id2)["nome"], "evento")
		sistema_ordine()
		conferma("La Porta dell'Inferno è distrutta! Ora il gruppo deve uscire vivo dalla Cittadella, tornando al livello 1 e al Portale del Male.")
	else:
		annota("%s tira %d contro %d: fallisce e subisce 1 ferita." % [p["nome"], t, abil], "dado")
		danneggia("p:" + id, 1, "la Porta", false)
		nuovo_turno()

# ============================================================================================
# Fine del combattimento: rianimazioni, esperienza, tesori (9.0, 12.0, 14.0)
# ============================================================================================
func fine_combattimento(esito: String) -> void:
	var c: Dictionary = s["comb"]
	if c.get("esito", "") != "": return
	c["esito"] = esito
	evento({"tipo": "combattimento", "fine": true, "esito": esito})
	# pulizia degli effetti temporanei
	for id in s["ordine_ids"]:
		var p = pg(id)
		p["bc_temp"] = 0
		p["scudo_magico"] = false
		p["pugnale_lanciato"] = false
		if p.get("flag", {}).get("alloces", false): p["flag"]["alloces"] = false
	# gli incantati dai mostri restano dalla parte dei mostri solo se il gruppo perde
	for uid in unita_in(c["ordine_m"]):
		if uid.begins_with("p:") and esito != "sconfitta":
			var pp = unita(uid)
			if pp.get("stato", "") in ["incantato", "posseduto"]:
				pp["stato"] = "ok"
				pp.erase("incantato_da")
	match esito:
		"sconfitta":
			if c.get("solo", "") != "":
				annota("%s non è riuscito a cavarsela da solo." % pg(c["solo"])["nome"], "morte")
			else:
				for id in s["ordine_ids"]:
					var p2 = pg(id)
					if p2.get("stato", "ok") in ["pietra", "incantato", "posseduto"]:
						p2["stato"] = "morto"
		"tregua":
			var rimasti = []
			for uid in c["mostri"]:
				var m: Dictionary = c["mostri"][uid]
				if m.get("stato", "ok") == "ok" and vivo(m):
					m["dorme"] = false
					rimasti.append(m)
			seg_attuale()["mostri"] = rimasti
		"vittoria":
			pass
	s["dopo_comb"] = true
	_scelta_rianimazione()

func _scelta_rianimazione() -> void:
	var c: Dictionary = s["comb"]
	var opz = []
	for id in s["ordine_ids"]:
		var p = pg(id)
		if p.get("stato", "") == "pietra":
			for mago in pg_in_gruppo():
				if mago != id and "sf" in incantesimi_usabili("p:" + mago, ["NC"]):
					opz.append({"id": "sf|%s|%s" % [mago, id], "azione": "rianima", "bersaglio": "p:" + id, "gruppo": "Pietra in carne",
						"testo": "%s lancia Pietra in carne su %s (3 PF)" % [pg(mago)["nome"], p["nome"]]})
		if p.get("stato", "") == "morto" and id in c.get("caduti", []):
			for mago in pg_in_gruppo():
				var pm = pg(mago)
				if "rs" in pm.get("inc_attivi", []) and pf_residui(pm) > 5:
					opz.append({"id": "rs|%s|%s" % [mago, id], "azione": "rianima", "bersaglio": "p:" + id, "gruppo": "Resurrezione",
						"testo": "%s lancia Resurrezione su %s (5 PF)" % [pm["nome"], p["nome"]]})
				for o in pm.get("oggetti", []):
					if o.get("tipo") == "anello" and o.get("var") == "resurrezione" and not o.get("usato", false):
						opz.append({"id": "ar|%s|%s" % [mago, id], "azione": "rianima", "bersaglio": "p:" + id, "gruppo": "Anello di Resurrezione",
							"testo": "%s usa l'Anello di Resurrezione su %s" % [pm["nome"], p["nome"]]})
	if opz.is_empty() or pg_in_gruppo().is_empty():
		_dopo_rianimazione()
		return
	opz.append({"id": "basta", "azione": "basta", "bersaglio": "", "gruppo": "Altro", "testo": "Nessun altro incantesimo"})
	s["scelta"] = {"tipo": "rianima", "testo": "Il combattimento è finito. Qualcuno può essere salvato?", "opzioni": opz}

func _esegui_rianima(o: Dictionary) -> void:
	var parti: PackedStringArray = String(o["id"]).split("|")
	if parti[0] == "basta":
		_dopo_rianimazione()
		return
	var mago = pg(parti[1])
	var p = pg(parti[2])
	match parti[0]:
		"sf":
			if paga(mago, "sf"):
				p["stato"] = "ok"
				annota("%s riporta in vita %s con Pietra in carne." % [mago["nome"], p["nome"]], "magia")
		"rs":
			mago["ferite"] = int(mago["ferite"]) + 5
			p["stato"] = "ok"
			p["ferite"] = int(p.get("ferite_ingresso", 0))
			annota("%s lancia Resurrezione: %s torna in vita!" % [mago["nome"], p["nome"]], "magia")
		"ar":
			for ob in mago["oggetti"]:
				if ob.get("tipo") == "anello" and ob.get("var") == "resurrezione" and not ob.get("usato", false):
					ob["usato"] = true
					break
			p["stato"] = "ok"
			p["ferite"] = int(p.get("ferite_ingresso", 0))
			annota("L'Anello di Resurrezione riporta in vita %s!" % p["nome"], "magia")
	sistema_ordine()
	_scelta_rianimazione()

func _dopo_rianimazione() -> void:
	var c: Dictionary = s["comb"]
	for id in s["ordine_ids"]:
		var p = pg(id)
		if p.get("stato", "") == "pietra":
			p["stato"] = "morto"
			annota("Nessuno può spezzare l'incantesimo: %s resta una statua per sempre." % p["nome"], "morte")
	var esito: String = c["esito"]
	var inc: Dictionary = s.get("incontro", {})
	if esito == "vittoria" and not c["uccisi"].is_empty():
		# esperienza (12.0)
		var vivi = pg_in_gruppo()
		if not vivi.is_empty():
			var liv = clampi(int(s["pos"]["liv"]), 1, 3)
			var xp = int(int(c["pf_iniziali"]) * 6 / vivi.size()) * int(D.LIVELLI["xp"][liv - 1])
			for id in vivi:
				pg(id)["xp"] = int(pg(id)["xp"]) + xp
			annota("Ogni sopravvissuto guadagna %d punti esperienza." % xp, "evento")
		s["statistiche"]["uccisi"] = int(s["statistiche"]["uccisi"]) + c["uccisi"].size()
		# oro della corruzione recuperato (8.7)
		if int(c.get("oro_corruzione", 0)) > 0:
			_dai_oro(int(c["oro_corruzione"]))
			annota("Il gruppo recupera i %d marchi offerti." % int(c["oro_corruzione"]))
		# tesori (14.0): uno per mostro, i tipi J, K, L in forzieri
		if not c.get("senza_tesoro", false):
			for uid in c["uccisi"]:
				var m: Dictionary = c["mostri"].get(uid, {})
				if m.is_empty(): continue
				var lettera: String = m["tesoro"]
				if lettera in ["J", "K", "L"]:
					s.get_or_add("forzieri", []).append(lettera)
				else:
					_aggiungi_tesoro(genera_tesoro(lettera))
	s["comb"] = {}
	if esito == "sconfitta" and c.get("solo", "") == "":
		_controlla_sconfitta()
		return
	if _controlla_sconfitta(): return
	sistema_ordine()
	# continua dove era rimasto
	var seguito: String = inc.get("seguito", "elemento") if not inc.is_empty() else s.get("seguito_comb", "turno")
	s.erase("seguito_comb")
	s["incontro"] = {}
	s["seguito"] = "elemento" if seguito == "elemento" else ("botola_risali" if seguito == "botola_risali" else "turno")
	_apri_forzieri()

func _apri_forzieri() -> void:
	var f: Array = s.get("forzieri", [])
	if f.is_empty():
		prosegui()
		return
	var lettera: String = f[0]
	var t = d6()
	mostra_dadi([t], "Forziere")
	if t <= 3:
		annota("Il tesoro (tipo %s) è in un forziere protetto da una trappola!" % lettera, "evento")
		_scelta_trappola("forziere")
		return
	annota("Il forziere (tipo %s) non è protetto." % lettera, "dado")
	_dopo_forziere()

func _dopo_forziere() -> void:
	var f: Array = s.get("forzieri", [])
	if f.is_empty():
		prosegui()
		return
	var lettera: String = f.pop_front()
	if not pg_in_gruppo().is_empty():
		_aggiungi_tesoro(genera_tesoro(lettera))
	_apri_forzieri()

# --------------------------------------------------------------------------------------------
# Tesori (14.0 - 14.9)
# --------------------------------------------------------------------------------------------
func _voce_tesoro(v: Array) -> int:
	var soglia = int(v[0])
	if soglia <= 0: return 0
	var t = d6()
	if t > soglia: return 0
	var dadi = int(v[1])
	var facce = int(v[2])
	var molt = int(v[3])
	if facce == 0: return dadi
	return tira(dadi, facce) * molt

func genera_tesoro(lettera: String) -> Dictionary:
	var tab: Array = D.TESORI.get(lettera, D.TESORI["A"])
	var oro = _voce_tesoro(tab[0])
	var ng = _voce_tesoro(tab[1])
	var no = _voce_tesoro(tab[2])
	var gioielli = []
	for i in ng:
		var a = d6()
		var b = d6()
		gioielli.append(int(D.GIOIELLI[a + b]))
	var oggetti = []
	for i in no:
		oggetti.append(crea_oggetto())
	return {"oro": oro, "gioielli": gioielli, "oggetti": oggetti, "lettera": lettera}

func crea_oggetto(tipo_forzato: String = "") -> Dictionary:
	var tipo = tipo_forzato
	if tipo == "":
		tipo = D.OGGETTI_TIPI[d6() - 1]
	var t = d6()
	var v = D.OGGETTI[tipo][t - 1]
	var o = {"tipo": tipo, "var": v}
	match tipo:
		"arma":
			var bonus = 0
			var tiri = 1
			while tiri > 0:
				tiri -= 1
				var b: int = D.BONUS_ARMA[d6() - 1]
				if b == 0: tiri += 2
				else: bonus += b
			o["bonus"] = bonus
			o["nome"] = "%s +%d" % [D.nome_arma(v), bonus]
		"armatura":
			var bonus2 = 0
			if int(v) == 0:
				var tiri2 = 2
				while tiri2 > 0:
					tiri2 -= 1
					var b2: int = D.OGGETTI["armatura"][d6() - 1]
					if b2 == 0: tiri2 += 2
					else: bonus2 += b2
			else:
				bonus2 = int(v)
			o["bonus"] = bonus2
			o["var"] = "armatura"
			o["nome"] = "Armatura magica +%d PF" % bonus2
		"pozione":
			o["nome"] = D.NOMI_POZIONI[v]
			o["dosi"] = 1
		"talismano":
			o["nome"] = D.NOMI_TALISMANI[v]
		"medaglione":
			o["nome"] = D.NOMI_MEDAGLIONI[v]
		"anello":
			o["nome"] = D.NOMI_ANELLI[v]
	return o

func _aggiungi_tesoro(t: Dictionary) -> void:
	var parti = []
	if int(t["oro"]) > 0:
		_dai_oro(int(t["oro"]))
		parti.append("%d marchi d'oro" % int(t["oro"]))
	for g in t["gioielli"]:
		var vivi = pg_in_gruppo()
		if vivi.is_empty(): break
		var povero: String = vivi[0]
		for id in vivi:
			if ricchezza(pg(id)) < ricchezza(pg(povero)): povero = id
		pg(povero)["gioielli"].append(int(g))
		parti.append("un gioiello da %d (a %s)" % [int(g), pg(povero)["nome"]])
	for o in t["oggetti"]:
		s["bottino"].append(o)
		parti.append(o["nome"] if o["tipo"] != "pozione" else "una pozione misteriosa")
	if parti.is_empty():
		annota("Tesoro (tipo %s): niente di valore." % t.get("lettera", "?"))
	else:
		annota("Tesoro (tipo %s): %s." % [t.get("lettera", "?"), ", ".join(parti)], "tesoro")
		evento({"tipo": "tesoro"})

func _distribuisci_prossimo() -> void:
	var b: Array = s["bottino"]
	if b.is_empty():
		if s.get("seguito_incontro", false):
			s.erase("seguito_incontro")
			_scelta_incontro()
			return
		prosegui()
		return
	var o: Dictionary = b[0]
	var opz = []
	var verbo = "prende"
	if o["tipo"] in ["pozione", "medaglione"]: verbo = "prova"
	for id in pg_in_gruppo():
		var p = pg(id)
		var nota = ""
		if o["tipo"] == "arma" and p["armi"].size() >= 2: nota = " (dovrà lasciare un'arma)"
		opz.append({"id": "a|" + id, "azione": "assegna", "bersaglio": "p:" + id, "gruppo": "A chi",
			"testo": "%s %s%s" % [p["nome"], verbo, nota]})
	opz.append({"id": "lascia", "azione": "lascia", "bersaglio": "", "gruppo": "Altro", "testo": "Lascialo qui"})
	var nome_o: String = "una pozione misteriosa" if o["tipo"] == "pozione" else o["nome"]
	s["scelta"] = {"tipo": "tesoro", "testo": "Il gruppo trova %s. Chi lo %s?" % [nome_o, verbo], "opzioni": opz, "oggetto": o}

func _esegui_tesoro(o: Dictionary, sc: Dictionary) -> void:
	var ob: Dictionary = s["bottino"].pop_front()
	if o["id"] == "lascia":
		annota("Il gruppo lascia %s." % ob.get("nome", "l'oggetto"))
		_distribuisci_prossimo()
		return
	var id = String(o["id"]).split("|")[1]
	var p = pg(id)
	if ob["tipo"] == "arma" and p["armi"].size() >= 2:
		var opz = []
		for i in p["armi"].size():
			opz.append({"id": "s|%d" % i, "azione": "sostituisci", "bersaglio": "", "gruppo": "", "testo": "Lascia %s" % D.nome_arma(p["armi"][i]["tipo"])})
		opz.append({"id": "no", "azione": "no", "bersaglio": "", "gruppo": "", "testo": "Non prenderla"})
		s["scelta"] = {"tipo": "arma_sost", "testo": "%s può portare solo due armi: quale lascia per prendere %s?" % [p["nome"], ob["nome"]], "opzioni": opz, "chi": id, "oggetto": ob}
		return
	ricevi_oggetto(id, ob)
	if in_combattimento() or not s.get("scelta", {}).is_empty() or s.get("fine", "") != "": return
	_distribuisci_prossimo()

func _esegui_arma_sost(o: Dictionary, sc: Dictionary) -> void:
	var id: String = sc["chi"]
	var ob: Dictionary = sc["oggetto"]
	if o["id"] != "no":
		var i = int(String(o["id"]).split("|")[1])
		pg(id)["armi"].remove_at(i)
		pg(id)["arma_att"] = 0
		ricevi_oggetto(id, ob)
		if in_combattimento() or not s.get("scelta", {}).is_empty() or s.get("fine", "") != "": return
	_distribuisci_prossimo()

## Effetti dell'oggetto quando un personaggio lo prende o lo prova (14.3 - 14.8)
func ricevi_oggetto(id: String, ob: Dictionary) -> void:
	var p = pg(id)
	match ob["tipo"]:
		"arma":
			p["armi"].append({"tipo": ob["var"], "bonus": int(ob["bonus"])})
			annota("%s impugna ora %s." % [p["nome"], ob["nome"]], "tesoro")
		"armatura":
			if int(ob["bonus"]) > int(p.get("pf_armatura", 0)):
				p["pf_armatura"] = int(ob["bonus"])
			p["oggetti"].append(ob)
			annota("%s indossa %s." % [p["nome"], ob["nome"]], "tesoro")
		"pozione":
			bevi_pozione(id, ob, true)
		"talismano":
			p["oggetti"].append(ob)
			annota("%s prende %s." % [p["nome"], ob["nome"]], "tesoro")
			match ob["var"]:
				"mente":
					ob["usi"] = d6()
					annota("Potrà usarlo %d volte in questa partita." % int(ob["usi"]))
				"sole_giallo", "sole_blu", "sole_rosso":
					var i = D.SOLI.find(String(ob["var"]).substr(5))
					var n = d3()
					p["pm"][i] = int(p["pm"][i]) + n
					annota("Il Potenziale Magico di %s per il %s sale di %d." % [p["nome"], D.SOLI[i], n])
					_aggiorna_incantesimi_attivi(p)
				"tutti_i_soli":
					for i in 3:
						p["pm"][i] = int(p["pm"][i]) + d3()
					annota("Il Potenziale Magico di %s cresce sotto tutti i soli: %d/%d/%d." % [p["nome"], p["pm"][0], p["pm"][1], p["pm"][2]])
					_aggiorna_incantesimi_attivi(p)
				"male":
					if not resiste("p:" + id, "il Talismano del Male"):
						p["stato"] = "posseduto"
						annota("%s cade sotto il potere del Talismano del Male e attacca il gruppo!" % p["nome"], "evento")
						s["seguito_comb"] = "turno" if s.get("seguito", "") == "" else s["seguito"]
						_combatti_posseduto(id)
						return
		"medaglione":
			match ob["var"]:
				"strangolamento":
					annota("Il medaglione si stringe al collo di %s!" % p["nome"], "evento")
					danneggia("p:" + id, d6(), "il medaglione strangolatore", false)
				_:
					p["oggetti"].append(ob)
					annota("%s indossa %s." % [p["nome"], ob["nome"]], "tesoro")
		"anello":
			p["oggetti"].append(ob)
			annota("%s infila %s." % [p["nome"], ob["nome"]], "tesoro")

func _aggiorna_incantesimi_attivi(p: Dictionary) -> void:
	var npm = pm_sole(p)
	var nmax = max_pm(p)
	while p["inc_noti"].size() < nmax:
		var nuovo = ""
		for k in PRIORITA_INC:
			if not k in p["inc_noti"]:
				nuovo = k
				break
		if nuovo == "": break
		p["inc_noti"].append(nuovo)
	for k in p["inc_noti"]:
		var normali = p["inc_attivi"].filter(func(x): return not x in ["wg", "rs"]).size()
		if normali >= npm: break
		if not k in p["inc_attivi"]:
			p["inc_attivi"].append(k)
			if k in ["he", "rj"] and not p["usi_cura"].has(k):
				p["usi_cura"][k] = d6()

func bevi_pozione(id: String, ob: Dictionary, prova: bool) -> void:
	var p = pg(id)
	var stima = ha_oggetto(p, "medaglione", "stima_pozioni")
	if prova and stima:
		if ob["var"] == "veleno":
			annota("Il Medaglione della Stima rivela che è veleno: %s la getta via." % p["nome"], "magia")
			return
		ob["dosi"] = 2
		p["oggetti"].append(ob)
		annota("Il Medaglione della Stima rivela: %s (due dosi)." % ob["nome"], "magia")
		return
	annota("%s beve: %s." % [p["nome"], ob["nome"]], "tesoro")
	match ob["var"]:
		"veleno":
			avvelena(id, d3(), "la pozione velenosa")
		"forza":
			var n = d6()
			p["forza_prossimo"] = n
			annota("+%d al Bonus di Combattimento nel prossimo scontro." % n)
		"guarigione":
			var n2 = mini(d6(), int(p["ferite"]))
			p["ferite"] = int(p["ferite"]) - n2
			annota("%s guarisce %d ferit%s." % [p["nome"], n2, "a" if n2 == 1 else "e"])
		"fascino_persone", "fascino_mostri":
			annota("Non c'è nessuno da affascinare: l'effetto svanisce.")
	if prova and ob["var"] != "veleno":
		var copia = ob.duplicate()
		copia["dosi"] = 1
		p["oggetti"].append(copia)
		annota("%s conserva una dose." % p["nome"])

func _combatti_posseduto(id: String) -> void:
	var uid = "p:" + id
	togli_da_ordine(s["ordine"], uid)
	s["incontro"] = {"mostri": {}, "origine": "posseduto", "porta": false, "negoziato": true, "corrotto": true, "oratoria": 0, "sconto": 0,
		"seguito": s.get("seguito_comb", "turno"), "solo": "", "no_trattativa": true, "unisci_dal_round": 0, "esito": ""}
	inizia_combattimento([], {"posseduti": [uid], "mostri_primi": true, "senza_tesoro": true})

# ============================================================================================
# Elementi delle stanze (13.0)
# ============================================================================================
func fase_elemento() -> void:
	var seg = seg_attuale()
	var el: String = seg.get("elemento", "")
	if seg["tipo"] != "stanza" or el == "" or el == "scala" or seg.get("elemento_usato", false):
		nuovo_turno()
		return
	var opz = []
	for id in pg_in_gruppo():
		opz.append({"id": "ind|" + id, "azione": "indaga", "bersaglio": "p:" + id, "gruppo": "Chi indaga", "testo": "%s indaga" % pg(id)["nome"]})
	opz.append({"id": "no", "azione": "no", "bersaglio": "", "gruppo": "Altro", "testo": "Non indagare e prosegui"})
	s["scelta"] = {"tipo": "elemento", "testo": "Nella stanza c'è %s. Qualcuno vuole indagare?" % _art_elemento(el), "opzioni": opz, "elemento": el}

func _art_elemento(el: String) -> String:
	return {"fontana": "una fontana di bronzo", "statua": "una statua di alabastro", "botola": "una botola", "mobili": "un mobile magico",
		"altare": "un altare demoniaco", "opera": "un'opera d'arte magica", "specchio": "un grande specchio"}.get(el, el)

func _esegui_elemento(o: Dictionary) -> void:
	if o["id"] == "no":
		nuovo_turno()
		return
	var id = String(o["id"]).split("|")[1]
	var seg = seg_attuale()
	seg["elemento_usato"] = true
	indaga(id, seg["elemento"])

func indaga(id: String, el: String) -> void:
	var p = pg(id)
	if el == "specchio":
		specchio()
		return
	var t = d6()
	var r: String = D.TABELLA_ELEMENTI[el][t - 1]
	mostra_dadi([t], "Tabella degli elementi")
	annota("%s indaga %s: tira %d → %s." % [p["nome"], D.ELEMENTI[el].to_lower(), t, D.NOMI_RISULTATI[r]], "dado")
	evento({"tipo": "elemento", "el": el, "r": r})
	s["seguito"] = "turno"
	match el:
		"fontana": _fontana(id, r)
		"statua": _statua(id, r)
		"botola": _botola(id, r)
		"mobili": _mobili(id, r)
		"altare": _altare(id, r)
		"opera": _opera(id, r)

func _fine_elemento(testo: String) -> void:
	if _controlla_sconfitta(): return
	if not s["bottino"].is_empty():
		_distribuisci_prossimo()
		return
	conferma(testo)

func _fontana(id: String, r: String) -> void:
	var p = pg(id)
	match r:
		"veleno":
			avvelena(id, d3(), "l'acqua avvelenata")
			_fine_elemento("La fontana era avvelenata.")
		"pozione":
			var ob = crea_oggetto("pozione")
			bevi_pozione(id, ob, true)
			_fine_elemento("Dalla fontana sgorga una pozione magica.")
		"alcol":
			p["bc"] = int(p["bc"]) - 2
			annota("%s è ubriaco: −2 al Bonus di Combattimento per il resto della partita." % p["nome"])
			_fine_elemento("Un liquore magico potentissimo!")
		"gioiello":
			var a = d6()
			var b = d6()
			var v = int(D.GIOIELLI[a + b])
			p["gioielli"].append(v)
			annota("Nell'acqua brilla un gioiello da %d marchi: lo prende %s." % [v, p["nome"]], "tesoro")
			_fine_elemento("Un gioiello nella vasca!")
		"acqua":
			_fine_elemento("È solo acqua.")
		"sangue":
			p["bc"] = int(p["bc"]) - 1
			annota("Sangue fumante! %s sta male: −1 al Bonus di Combattimento per il resto della partita." % p["nome"])
			_fine_elemento("La fontana versa sangue.")

func _statua(id: String, r: String) -> void:
	var p = pg(id)
	match r:
		"medusa":
			annota("La statua prende vita: è una Medusa!", "evento")
			if not resiste("p:" + id, "lo sguardo della Medusa"):
				p["stato"] = "pietra"
				annota("%s è trasformato in pietra!" % p["nome"], "morte")
				_pietrificato_fuori_comb(id)
			sistema_ordine()
			if pg_in_gruppo().is_empty():
				_controlla_sconfitta()
				return
			apri_incontro([crea_mostro("medusa", int(s["pos"]["liv"]), false)], "elemento", false, {"seguito": "turno"})
		"gioielli":
			for i in 2:
				var a = d6()
				var b = d6()
				p["gioielli"].append(int(D.GIOIELLI[a + b]))
			annota("%s prende i due gioielli: %d e %d marchi." % [p["nome"], p["gioielli"][-2], p["gioielli"][-1]], "tesoro")
			_fine_elemento("Una statua di ariete con due gemme per occhi.")
		"medaglione":
			ricevi_oggetto(id, crea_oggetto("medaglione"))
			_fine_elemento("Al collo della statua pende un medaglione.")
		"demone":
			var t = d6()
			var r2: String = D.TABELLA_ELEMENTI["altare"][t - 1]
			annota("È la statua di un demone (tiro %d): %s." % [t, D.NOMI_RISULTATI[r2]], "dado")
			_altare(id, r2)
		"talismano":
			var ob = crea_oggetto("talismano")
			ricevi_oggetto(id, ob)
			if s.get("comb", {}).is_empty() and s.get("scelta", {}).is_empty():
				_fine_elemento("Al collo della statua pende un talismano.")
		"x":
			annota("È una statua di X lo Sconosciuto!", "evento")
			if resiste("p:" + id, "il potere di X"):
				_fine_elemento("La statua non ha effetto.")
			else:
				p["stato"] = "posseduto"
				annota("%s diventa strumento di X e attacca il gruppo!" % p["nome"], "evento")
				s["seguito_comb"] = "turno"
				_combatti_posseduto(id)

func _pietrificato_fuori_comb(id: String) -> void:
	for mago in pg_in_gruppo():
		if mago != id and "sf" in incantesimi_usabili("p:" + mago, ["NC"]):
			var pm = pg(mago)
			if paga(pm, "sf"):
				pg(id)["stato"] = "ok"
				annota("%s spezza la pietrificazione con Pietra in carne." % pm["nome"], "magia")
				return

func _botola(id: String, r: String) -> void:
	var p = pg(id)
	match r:
		"trappola":
			annota("La botola è protetta da una trappola.")
			s["botola_chi"] = id
			_scelta_trappola_su(id, "botola")
		"stanza":
			annota("%s precipita in una stanza segreta sotto il pavimento!" % p["nome"], "evento")
			s["botola_chi"] = id
			var t = d6()
			mostra_dadi([t], "Controllo dei mostri")
			if t <= 3:
				annota("Tiro %d: la stanza è abitata. %s dovrà cavarsela da solo." % [t, p["nome"]], "dado")
				apri_incontro(tira_incontro(true, int(s["pos"]["liv"])), "botola", false, {"seguito": "botola_risali", "solo": id})
			else:
				annota("Tiro %d: la stanza è vuota." % t, "dado")
				_botola_risali()
		"fossa":
			annota("%s cade in una fossa piena di Cronk!" % p["nome"], "evento")
			s["botola_chi"] = id
			var n = d3()
			var lista = []
			for i in n:
				lista.append(crea_mostro("cronk", int(s["pos"]["liv"]), false))
			s["botola_tesoro"] = false
			apri_incontro(lista, "botola", false, {"seguito": "botola_risali", "solo": id})
		"hellgate":
			p["stato"] = "prigioniero"
			sistema_ordine()
			annota("%s scivola in un pozzo che lo porta fino alla bocca della Porta dell'Inferno! Resterà prigioniero finché la Porta non sarà distrutta." % p["nome"], "evento")
			if _controlla_sconfitta(): return
			_fine_elemento("Un pozzo senza fondo.")

func _scelta_trappola_su(id: String, cosa: String) -> void:
	# la trappola della botola o dello scrittoio colpisce chi indaga: può tentare di disinnescarla
	var p = pg(id)
	var opz = [{"id": "tr|" + id + "|", "azione": "trappola", "bersaglio": "p:" + id, "gruppo": "",
		"testo": "%s %s" % [p["nome"], ("prova a disinnescarla (Disinnesco %d)" % int(p["disinnesco"])) if int(p["disinnesco"]) > 0 else "non sa disinnescarla"]}]
	if int(p["disinnesco"]) > 0:
		for mago in pg_in_gruppo():
			if "tf" in incantesimi_usabili("p:" + mago, ["NC"]):
				opz.append({"id": "tr|%s|%s" % [id, mago], "azione": "trappola", "bersaglio": "p:" + id, "gruppo": "",
					"testo": "%s con Ladro di %s (Disinnesco %d, 1 PF)" % [p["nome"], pg(mago)["nome"], mini(int(p["disinnesco"]) + 3, 8)]})
	s["trappola_su"] = cosa
	s["scelta"] = {"tipo": "trappola", "testo": "La trappola minaccia %s." % p["nome"], "opzioni": opz}

func _dopo_trappola_elemento(cosa: String) -> void:
	var id: String = s.get("botola_chi", "")
	if cosa == "botola":
		if not pg(id).is_empty() and vivo(pg(id)):
			annota("Sotto la botola c'è un tesoro (tipo J).", "evento")
			_aggiungi_tesoro(genera_tesoro("J"))
		_fine_elemento("La botola nascondeva un tesoro.")
	else:
		if not pg(id).is_empty() and vivo(pg(id)):
			ricevi_oggetto(id, crea_oggetto("medaglione"))
		_fine_elemento("Nel cassetto c'era un medaglione.")

func _botola_risali() -> void:
	var id: String = s.get("botola_chi", "")
	s.erase("botola_chi")
	var p = pg(id)
	if not p.is_empty() and vivo(p) and p.get("stato", "ok") == "ok":
		if s.get("botola_tesoro", true):
			annota("Nella stanza segreta c'è un tesoro (tipo J).", "evento")
			_aggiungi_tesoro(genera_tesoro("J"))
		annota("%s risale e raggiunge i compagni." % p["nome"])
	s.erase("botola_tesoro")
	sistema_ordine()
	_fine_elemento("Avventura sotto la botola conclusa.")

func _mobili(id: String, r: String) -> void:
	var p = pg(id)
	match r:
		"bara":
			annota("Dalla bara si leva un Vampiro! %s deve affrontarlo subito; dal secondo round il gruppo può aiutarlo." % p["nome"], "evento")
			var v = crea_mostro("vampiro", int(s["pos"]["liv"]), false)
			s["incontro"] = {"mostri": {}, "origine": "bara", "porta": false, "negoziato": true, "corrotto": true, "oratoria": 0, "sconto": 0,
				"seguito": "turno", "solo": id, "no_trattativa": true, "unisci_dal_round": 2, "esito": ""}
			_inizia_con_esitazione([v], {"solo": id, "unisci_dal_round": 2})
		"libreria":
			var t = d6()
			if t <= 3:
				var n = d3()
				annota("La libreria crolla addosso a %s (tiro %d): %d ferit%s." % [p["nome"], t, n, "a" if n == 1 else "e"], "dado")
				danneggia("p:" + id, n, "la libreria", false)
				_fine_elemento("La libreria era marcia.")
			else:
				annota("Tra i volumi (tiro %d) %s trova un libro di magia e impara Resurrezione!" % [t, p["nome"]], "tesoro")
				_impara_speciale(p, "rs")
				_fine_elemento("Un libro di incantesimi!")
		"scrittoio":
			annota("Il cassetto dello scrittoio è protetto da una trappola; dentro c'è un medaglione.")
			s["botola_chi"] = id
			_scelta_trappola_su(id, "scrittoio")
		"letto":
			var n2 = mini(d3(), int(p["ferite"]))
			p["ferite"] = int(p["ferite"]) - n2
			annota("%s riposa nel letto magico e guarisce %d ferit%s." % [p["nome"], n2, "a" if n2 == 1 else "e"])
			_fine_elemento("Un letto magico.")
		"clavicembalo":
			if resiste("p:" + id, "l'incanto del clavicembalo"):
				_fine_elemento("Il clavicembalo suona da solo, ma %s non si lascia ammaliare." % p["nome"])
			else:
				var meta = int(int(p["oro"]) / 2)
				p["oro"] = int(p["oro"]) - meta
				if meta > 0:
					annota("Ammaliato dalla musica, %s infila %d marchi nello strumento." % [p["nome"], meta])
					s["scelta"] = {"tipo": "si_no", "tag": "clavicembalo", "chi": id, "oro": meta, "testo": "Per riaprire lo strumento e riprendere i %d marchi bisogna subire 1 ferita." % meta,
						"opzioni": [{"id": "si", "testo": "%s riapre lo strumento (1 ferita)" % p["nome"], "azione": "si", "bersaglio": "", "gruppo": ""},
							{"id": "no", "testo": "Lascia l'oro", "azione": "no", "bersaglio": "", "gruppo": ""}]}
				else:
					_fine_elemento("Ammaliato, %s non ha oro da dare allo strumento." % p["nome"])
		"specchio":
			specchio()

func _impara_speciale(p: Dictionary, k: String) -> void:
	if not p.has("inc_speciali"): p["inc_speciali"] = []
	if not k in p["inc_speciali"]: p["inc_speciali"].append(k)
	if not k in p["inc_attivi"]: p["inc_attivi"].append(k)

func _altare(id: String, r: String) -> void:
	var p = pg(id)
	var ok = resiste("p:" + id, "l'altare di " + D.NOMI_RISULTATI[r].split(",")[0])
	match r:
		"alloces":
			if ok:
				p["flag"]["alloces"] = true
				annota("Benedizione di Alloces: nel prossimo combattimento %s lancerà gli incantesimi senza costo." % p["nome"], "magia")
			else:
				p["bc"] = int(p["bc"]) - 1
				annota("Maledizione di Alloces: −1 al Bonus di Combattimento.", "magia")
		"vassago":
			if ok:
				p["disinnesco"] = mini(int(p["disinnesco"]) + 3, 5)
				annota("Dono di Vassago: +3 al Disinnesco (massimo 5).", "magia")
			else:
				p["disinnesco"] = 0
				annota("Maledizione di Vassago: %s perde per sempre l'abilità di disinnescare." % p["nome"], "magia")
		"avnas":
			if ok:
				p["flag"]["fulmine_economico"] = true
				_impara_inc(p, "lt")
				annota("Dono di Avnas: %s lancia il Fulmine a 1 solo PF." % p["nome"], "magia")
			else:
				annota("L'altare di Avnas scaglia un Fulmine contro %s!" % p["nome"], "magia")
				if not resiste("p:" + id, "il Fulmine"):
					danneggia("p:" + id, d3() + 2, "il Fulmine", true)
		"malthus":
			if ok:
				_impara_speciale(p, "wg")
				annota("Dono di Malthus: %s impara l'Ira di Dio." % p["nome"], "magia")
			else:
				annota("L'altare di Malthus scaglia l'Ira di Dio contro %s!" % p["nome"], "magia")
				if not resiste("p:" + id, "l'Ira di Dio"):
					danneggia("p:" + id, tira(2) + 2, "l'Ira di Dio", true)
		"leraje":
			if ok:
				p["abil"]["arco"] = int(p["abil"].get("arco", 0)) + 3
				annota("Dono di Leraje: +3 all'abilità con l'arco.", "magia")
			else:
				annota("Tre frecce magiche colpiscono %s!" % p["nome"], "magia")
				for i in 3:
					if not vivo(p): break
					var t = d6()
					var n = D.ferite_crt("arco", t)
					annota("Freccia magica: tiro %d → %d ferit%s." % [t, n, "a" if n == 1 else "e"], "dado")
					danneggia("p:" + id, n, "le frecce di Leraje", false)
		"asmoday":
			if ok:
				p["bc"] = int(p["bc"]) + 3
				p["flag"]["fulmine_economico"] = true
				_impara_inc(p, "lt")
				annota("Dono di Asmoday: +3 al Bonus di Combattimento e il Fulmine a 1 solo PF.", "magia")
			else:
				for i in 3:
					p["pm"][i] = maxi(0, int(p["pm"][i]) - 1)
				annota("Maledizione di Asmoday: il Potenziale Magico di %s cala di 1 sotto ogni sole." % p["nome"], "magia")
				while p["inc_attivi"].filter(func(x): return not x in ["wg", "rs"]).size() > pm_sole(p):
					var tolto = ""
					for k in p["inc_attivi"]:
						if not k in ["wg", "rs"]: tolto = k
					p["inc_attivi"].erase(tolto)
	_fine_elemento("L'altare ha parlato.")

func _impara_inc(p: Dictionary, k: String) -> void:
	if not k in p["inc_noti"]: p["inc_noti"].append(k)
	if not k in p["inc_attivi"]: p["inc_attivi"].append(k)

func _opera(id: String, r: String) -> void:
	var p = pg(id)
	match r:
		"arazzo":
			var a = d6()
			var b = d6()
			var v = int(D.GIOIELLI[mini(a + b + 4, 12)])
			s["scelta"] = {"tipo": "si_no", "tag": "arazzo", "chi": id, "valore": v,
				"testo": "Un arazzo elfico del valore di %d marchi. %s può prenderlo lasciando una delle sue armi." % [v, p["nome"]],
				"opzioni": []}
			for i in p["armi"].size():
				s["scelta"]["opzioni"].append({"id": "si|%d" % i, "testo": "Lascia %s e prendi l'arazzo" % D.nome_arma(p["armi"][i]["tipo"]), "azione": "si", "bersaglio": "", "gruppo": ""})
			s["scelta"]["opzioni"].append({"id": "no", "testo": "Lascia l'arazzo", "azione": "no", "bersaglio": "", "gruppo": ""})
		"dipinto":
			annota("Un dipinto raffigura un gruppo di figure... ognuno tira un dado.")
			for x in pg_in_gruppo():
				var t = d6()
				if t == 1:
					var n = d3()
					annota("%s si riconosce nel dipinto: è maledetto e subisce %d ferit%s." % [pg(x)["nome"], n, "a" if n == 1 else "e"], "evento")
					danneggia("p:" + x, n, "la maledizione del dipinto", false)
			_fine_elemento("Il dipinto maledetto.")
		"statua":
			var t2 = d6()
			var r2: String = D.TABELLA_ELEMENTI["statua"][t2 - 1]
			annota("Una grande statua (tiro %d): %s." % [t2, D.NOMI_RISULTATI[r2]], "dado")
			_statua(id, r2)
		"vetro":
			var t3 = d6()
			var tipo = "talismano" if t3 <= 3 else "medaglione"
			annota("Il vetro intagliato (tiro %d) è un %s." % [t3, tipo])
			ricevi_oggetto(id, crea_oggetto(tipo))
			if s.get("comb", {}).is_empty() and s.get("scelta", {}).is_empty():
				_fine_elemento("Un oggetto di vetro intagliato.")
		"icona":
			var t4 = d6()
			var r3: String = D.TABELLA_ELEMENTI["altare"][t4 - 1]
			annota("Un'icona di demone (tiro %d): %s." % [t4, D.NOMI_RISULTATI[r3]], "dado")
			_altare(id, r3)
		"manoscritto":
			_impara_speciale(p, "wg")
			annota("Dal manoscritto miniato %s impara l'Ira di Dio!" % p["nome"], "tesoro")
			_fine_elemento("Un manoscritto di grande bellezza.")

func _esegui_si_no(o: Dictionary, sc: Dictionary) -> void:
	match sc.get("tag", ""):
		"esitazione":
			if String(o["id"]).begins_with("si"):
				var id = String(o["id"]).split("|")[1]
				var p = pg(id)
				if paga(p, "hs"):
					annota("%s lancia Esitazione: il gruppo ha il tempo di curarsi prima dello scontro." % p["nome"], "magia")
					s["scelta"] = {"tipo": "si_no", "tag": "esitazione_fatta", "testo": "Usa ora le cure (pannello del personaggio: incantesimi e oggetti), poi comincia il combattimento.",
						"opzioni": [{"id": "via", "testo": "Comincia il combattimento", "azione": "via", "bersaglio": "", "gruppo": ""}]}
					s["esitazione"] = true
					return
			_avvia_comb_attesa()
		"esitazione_fatta":
			s.erase("esitazione")
			_avvia_comb_attesa()
		"clavicembalo":
			var p2 = pg(sc["chi"])
			if o["id"] == "si":
				p2["oro"] = int(p2["oro"]) + int(sc["oro"])
				annota("%s riapre lo strumento e si riprende l'oro." % p2["nome"])
				danneggia("p:" + p2["id"], 1, "le corde del clavicembalo", false)
			_fine_elemento("Il clavicembalo tace.")
		"arazzo":
			var p3 = pg(sc["chi"])
			if String(o["id"]).begins_with("si"):
				var i = int(String(o["id"]).split("|")[1])
				p3["armi"].remove_at(i)
				p3["arma_att"] = 0
				p3["gioielli"].append(int(sc["valore"]))
				annota("%s prende l'arazzo (%d marchi)." % [p3["nome"], int(sc["valore"])], "tesoro")
			_fine_elemento("L'arazzo elfico.")

# --------------------------------------------------------------------------------------------
# Specchi (13.7)
# --------------------------------------------------------------------------------------------
func specchio() -> void:
	var hg: Dictionary = s["hellgate"]
	var liv = int(s["pos"]["liv"])
	if hg["trovata"]:
		_fine_elemento("Lo specchio riflette solo il gruppo: la Porta è già stata trovata.")
		return
	if int(hg["liv"]) == 0:
		var t = d6()
		var r: Array = D.SPECCHIO[t - 1]
		hg["liv"] = int(r[0])
		mostra_dadi([t], "Tabella dello specchio")
		annota("Lo specchio mostra la Porta dell'Inferno (tiro %d): si trova al LIVELLO %d." % [t, int(r[0])], "evento")
		if int(r[0]) == liv:
			_specchio_segmenti()
		else:
			hg["serve_specchio"] = true
			_fine_elemento("La Porta dell'Inferno è al livello %d: serve un altro specchio su quel livello per sapere quanto è lontana." % int(r[0]))
		return
	if bool(hg["serve_specchio"]) and int(hg["liv"]) == liv:
		hg["serve_specchio"] = false
		_specchio_segmenti()
		return
	_fine_elemento("Lo specchio resta opaco: non rivela nulla di nuovo.")

func _specchio_segmenti() -> void:
	var t = d6()
	var n = int(D.SPECCHIO[t - 1][1])
	s["hellgate"]["conto"] = n
	mostra_dadi([t], "Segmenti di distanza")
	annota("Lo specchio rivela la distanza (tiro %d): la Porta sarà il %d° segmento inesplorato in cui entrerete su questo livello." % [t, n], "evento")
	_fine_elemento("La Porta dell'Inferno è vicina: %d segmenti inesplorati." % n)

# ============================================================================================
# Azioni fuori combattimento (incantesimi, oggetti, ordine di marcia)
# ============================================================================================
func in_combattimento() -> bool:
	return not s.get("comb", {}).is_empty() and s["comb"].get("esito", "") == ""

func puo_agire_fuori_combattimento() -> bool:
	if s.get("fine", "") != "": return false
	if in_combattimento(): return false
	var t: String = s.get("scelta", {}).get("tipo", "")
	return t in ["rotta", "incontro", "elemento", "conferma", "si_no", "orienta", "rianima", "tesoro", "riposo"]

## Incantesimi lanciabili ora da un personaggio: [[k, [bersagli id]]]
func incantesimi_fuori(id: String) -> Array:
	var r = []
	if not puo_agire_fuori_combattimento(): return r
	var p = pg(id)
	if p.get("stato", "ok") != "ok": return r
	for k in incantesimi_usabili("p:" + id, ["NC"]):
		match k:
			"he", "rj":
				var b = pg_in_gruppo().filter(func(x): return x != id and int(pg(x)["ferite"]) > 0)
				if not b.is_empty(): r.append([k, b])
			"mr", "st":
				r.append([k, pg_in_gruppo()])
	return r

func lancia_fuori(id: String, k: String, bers: String) -> void:
	var p = pg(id)
	var b = pg(bers)
	if not paga(p, k): return
	match k:
		"he", "rj":
			p["usi_cura"][k] = int(p["usi_cura"].get(k, 0)) - 1
			var n = (d3() + 1) if k == "he" else (d6() + 1)
			n = mini(n, int(b["ferite"]))
			b["ferite"] = int(b["ferite"]) - n
			annota("%s lancia %s su %s: guarisce %d ferit%s." % [p["nome"], D.INCANTESIMI[k]["nome"], b["nome"], n, "a" if n == 1 else "e"], "magia")
		"mr":
			var n2 = d3() + 1
			b["armatura_magica"] = int(b.get("armatura_magica", 0)) + n2
			annota("%s lancia Armatura magica su %s: assorbirà %d ferite." % [p["nome"], b["nome"], n2], "magia")
		"st":
			var n3 = d6()
			b["forza_prossimo"] = n3
			annota("%s lancia Forza su %s: +%d al Bonus di Combattimento nel prossimo scontro." % [p["nome"], b["nome"], n3], "magia")
	evento({"tipo": "aggiorna"})

## Oggetti usabili ora: [[indice, testo]]
func oggetti_usabili(id: String) -> Array:
	var r = []
	if not puo_agire_fuori_combattimento(): return r
	var p = pg(id)
	for i in p.get("oggetti", []).size():
		var o: Dictionary = p["oggetti"][i]
		if o.get("tipo") == "pozione" and o.get("var") in ["guarigione", "forza"]:
			r.append([i, "Bevi " + o["nome"]])
		if o.get("tipo") == "anello" and o.get("var") == "guarigione" and not o.get("usato", false):
			r.append([i, "Usa l'Anello di Guarigione"])
	return r

func usa_oggetto(id: String, i: int) -> void:
	var p = pg(id)
	var o: Dictionary = p["oggetti"][i]
	if o.get("tipo") == "pozione":
		p["oggetti"].remove_at(i)
		bevi_pozione(id, o, false)
	elif o.get("tipo") == "anello":
		o["usato"] = true
		var n = mini(d3() + 1, int(p["ferite"]))
		p["ferite"] = int(p["ferite"]) - n
		annota("%s usa l'Anello di Guarigione: guarisce %d ferit%s." % [p["nome"], n, "a" if n == 1 else "e"], "magia")
	evento({"tipo": "aggiorna"})

## Spostamento libero nell'ordine di marcia fuori dal combattimento (4.1 C3)
func sposta_fuori(uid: String, col: int, riga: int) -> void:
	if in_combattimento(): return
	var o: Array = s["ordine"]
	var altro: String = o[riga][col]
	var da = fila_di(o, uid)
	if da.x < 0: return
	o[da.y][da.x] = altro
	o[riga][col] = uid
	compatta(o)
	var conta = 0
	for x in o[0]:
		if x != "": conta += 1
	if conta < 2 and unita_in(o).size() >= 2:
		# annulla: la prima fila deve avere almeno due personaggi
		o[riga][col] = altro
		o[da.y][da.x] = uid
		return
	evento({"tipo": "ordine"})

# ============================================================================================
# Uscita, vittoria, campagna (17.0)
# ============================================================================================
func _controlla_sconfitta() -> bool:
	if s.get("fine", "") != "": return true
	var vivi = s["ordine_ids"].filter(func(x): return pg(x).get("stato", "ok") in ["ok"])
	if vivi.is_empty():
		var prig = s["ordine_ids"].filter(func(x): return pg(x).get("stato", "") == "prigioniero")
		s["fine"] = "sconfitta"
		annota("Il gruppo è stato annientato nella Cittadella di Sangue." + (" I prigionieri della Porta non rivedranno mai la luce." if not prig.is_empty() else ""), "titolo")
		s["scelta"] = {"tipo": "fine", "testo": "Sconfitta: nessuno è uscito vivo.", "opzioni": [{"id": "nuova", "testo": "Nuova partita", "azione": "nuova", "bersaglio": "", "gruppo": ""}]}
		evento({"tipo": "fine", "esito": "sconfitta"})
		return true
	return false

func costo_miglioramento(p: Dictionary, bc: bool) -> int:
	var base = 150 if bc else 100
	var extra = maxi(0, int(p.get("uscite", 0)) - 3)
	return int(base * (1.0 + 0.1 * extra))

func vincitori() -> Array:
	var cand = []
	for id in s["ordine_ids"]:
		var p = pg(id)
		if p.get("stato", "") != "ok": continue
		var ric = ricchezza(p) + int(s["casa"].get(id, {}).get("oro", 0))
		if int(p["xp"]) >= 100 and ric >= 100:
			cand.append([id, int(p["xp"]) + ric])
	cand.sort_custom(func(a, b): return a[1] > b[1])
	return cand

func fine_spedizione() -> void:
	annota("Il gruppo esce dalla Cittadella attraverso il Portale del Male.", "titolo")
	for id in s["ordine_ids"]:
		var p = pg(id)
		if p.get("stato", "") != "ok": continue
		p["uscite"] = int(p.get("uscite", 0)) + 1
		var casa: Dictionary = s["casa"].get(id, {"oro": 0})
		casa["oro"] = int(casa["oro"]) + ricchezza(p)
		s["casa"][id] = casa
		p["oro"] = 0
		p["gioielli"] = []
	var v = vincitori()
	var testo = ""
	if s["hellgate"]["distrutta"]:
		s["fine"] = "vittoria"
		testo = "VITTORIA! La Porta dell'Inferno è distrutta e il gruppo è uscito vivo per raccontarlo."
	else:
		testo = "Il gruppo è fuori dalla Cittadella, ma la Porta dell'Inferno non è stata distrutta."
	if not v.is_empty():
		testo += " Miglior avventuriero: %s (%d tra esperienza e ricchezza)." % [pg(v[0][0])["nome"], int(v[0][1])]
	annota(testo, "titolo")
	evento({"tipo": "fine", "esito": "vittoria" if s["fine"] == "vittoria" else "uscita"})
	_scelta_riposo(testo)

func _scelta_riposo(testo: String) -> void:
	var opz = []
	if s["fine"] != "vittoria":
		opz.append({"id": "migliora", "testo": "Spendi esperienza e oro per migliorare", "azione": "migliora", "bersaglio": "", "gruppo": ""})
		opz.append({"id": "rientra", "testo": "Torna nella Cittadella (campagna)", "azione": "rientra", "bersaglio": "", "gruppo": ""})
	else:
		opz.append({"id": "migliora", "testo": "Spendi esperienza e oro per migliorare", "azione": "migliora", "bersaglio": "", "gruppo": ""})
	opz.append({"id": "termina", "testo": "Termina la partita", "azione": "termina", "bersaglio": "", "gruppo": ""})
	s["scelta"] = {"tipo": "riposo", "testo": testo, "opzioni": opz}

func _esegui_riposo(o: Dictionary) -> void:
	match o["id"]:
		"migliora": _scelta_migliora()
		"rientra": rientra()
		"termina":
			if s["fine"] == "": s["fine"] = "ritirata"
			s["scelta"] = {"tipo": "fine", "testo": "Partita conclusa.", "opzioni": [{"id": "nuova", "testo": "Nuova partita", "azione": "nuova", "bersaglio": "", "gruppo": ""}]}

func _scelta_migliora() -> void:
	var opz = []
	for id in s["ordine_ids"]:
		var p = pg(id)
		if p.get("stato", "") != "ok": continue
		var oro = int(s["casa"].get(id, {}).get("oro", 0))
		var c1 = costo_miglioramento(p, false)
		var c2 = costo_miglioramento(p, true)
		if int(p["xp"]) >= c1 and oro >= c1:
			opz.append({"id": "m|%s|pf" % id, "testo": "%s: +1 Punto Ferita (%d PE e %d oro)" % [p["nome"], c1, c1], "azione": "m", "bersaglio": "p:" + id, "gruppo": p["nome"]})
			var a = arma(p)
			opz.append({"id": "m|%s|arma" % id, "testo": "%s: +1 con %s" % [p["nome"], D.nome_arma(a["tipo"])], "azione": "m", "bersaglio": "p:" + id, "gruppo": p["nome"]})
			if vr_totale(p) < 5 and int(p["vr"]) < 5:
				opz.append({"id": "m|%s|vr" % id, "testo": "%s: +1 Resistenza" % p["nome"], "azione": "m", "bersaglio": "p:" + id, "gruppo": p["nome"]})
			for ab in ["disinnesco", "hellgate", "negoziazione"]:
				if ab != "negoziazione" and int(p[ab]) >= 5: continue
				opz.append({"id": "m|%s|%s" % [id, ab], "testo": "%s: +1 %s" % [p["nome"], {"disinnesco": "Disinnesco", "hellgate": "abilità contro la Porta", "negoziazione": "Negoziazione"}[ab]], "azione": "m", "bersaglio": "p:" + id, "gruppo": p["nome"]})
			for i in 3:
				opz.append({"id": "m|%s|pm%d" % [id, i], "testo": "%s: +1 Potenziale Magico (%s)" % [p["nome"], D.NOMI_SOLI[D.SOLI[i]]], "azione": "m", "bersaglio": "p:" + id, "gruppo": p["nome"]})
		if int(p["xp"]) >= c2 and oro >= c2:
			opz.append({"id": "m|%s|bc" % id, "testo": "%s: +1 Bonus di Combattimento (%d PE e %d oro)" % [p["nome"], c2, c2], "azione": "m", "bersaglio": "p:" + id, "gruppo": p["nome"]})
	opz.append({"id": "fatto", "testo": "Fine dei miglioramenti", "azione": "fatto", "bersaglio": "", "gruppo": "Altro"})
	s["scelta"] = {"tipo": "migliora", "testo": "Ogni punto di abilità costa 100 punti esperienza e 100 marchi (150 per il Bonus di Combattimento).", "opzioni": opz}

func _esegui_migliora(o: Dictionary) -> void:
	if o["id"] == "fatto":
		_scelta_riposo("Miglioramenti conclusi.")
		return
	var parti: PackedStringArray = String(o["id"]).split("|")
	var p = pg(parti[1])
	var bc = parti[2] == "bc"
	var costo = costo_miglioramento(p, bc)
	p["xp"] = int(p["xp"]) - costo
	s["casa"][p["id"]]["oro"] = int(s["casa"][p["id"]]["oro"]) - costo
	match parti[2]:
		"pf": p["pf_max"] = int(p["pf_max"]) + 1
		"arma":
			var t: String = arma(p)["tipo"]
			p["abil"][t] = int(p["abil"].get(t, 0)) + 1
		"vr": p["vr"] = mini(int(p["vr"]) + 1, 5)
		"disinnesco", "hellgate": p[parti[2]] = mini(int(p[parti[2]]) + 1, 5)
		"negoziazione": p["negoziazione"] = int(p["negoziazione"]) + 1
		"bc": p["bc"] = int(p["bc"]) + 1
		_:
			if parti[2].begins_with("pm"):
				var i = int(parti[2].substr(2))
				p["pm"][i] = int(p["pm"][i]) + 1
	annota("%s migliora: %s." % [p["nome"], o["testo"].split(": ")[1]], "evento")
	_scelta_migliora()

func rientra() -> void:
	s["spedizione"] = int(s["spedizione"]) + 1
	s["alleati"] = {}
	for id in s["ordine_ids"]:
		var p = pg(id)
		if p.get("stato", "") == "ok":
			p["ferite"] = 0
			p["armatura_magica"] = 0
			p["bc_temp"] = 0
			for o in p["oggetti"]:
				if o.get("tipo") == "anello": o["usato"] = false
	# si torna a sei (17.3) con nuovi iniziati
	var vivi = s["ordine_ids"].filter(func(x): return pg(x).get("stato", "") == "ok")
	var n = s["ordine_ids"].size()
	var razze = ["umano", "nano", "elfo"]
	while vivi.size() < 6:
		n += 1
		var razza: String = razze[n % 3]
		var nomi: Array = D.NOMI_INIZIATI[razza]
		var femmina = n % 2 == 0
		var id = "ini%d" % n
		var p2 = nuovo_pg_iniziato(id, nomi[n % nomi.size()], razza, femmina, "pugnale", "pf", d6())
		p2["inc_noti"] = incantesimi_consigliati(p2, max_pm(p2))
		s["gruppo"][id] = p2
		s["ordine_ids"].append(id)
		vivi.append(id)
		annota("%s (%s) si unisce al gruppo." % [p2["nome"], p2["razza"]], "evento")
	# solo i vivi restano nell'elenco del gruppo
	s["ordine_ids"] = s["ordine_ids"].filter(func(x): return pg(x).get("stato", "") in ["ok", "prigioniero"])
	s["ordine"] = [["", "", ""], ["", "", ""], ["", "", ""]]
	sistema_ordine()
	s["pos"] = {"liv": 1, "xy": "0,0"}
	s["turno"] = 0
	annota("Sei mesi dopo, il gruppo torna al Portale del Male per la spedizione n. %d." % int(s["spedizione"]), "titolo")
	evento({"tipo": "muovi", "liv": 1, "xy": "0,0"})
	inizio_spedizione()

# ============================================================================================
# Salvataggio
# ============================================================================================
func esporta() -> String:
	s["rng_stato"] = str(rng.state)
	return JSON.stringify(s)

func importa(testo: String) -> bool:
	var d = JSON.parse_string(testo)
	if typeof(d) != TYPE_DICTIONARY: return false
	s = d
	_normalizza(s)
	rng.seed = int(s.get("seme", 1))
	if s.has("rng_stato"):
		rng.state = int(String(s["rng_stato"]))
	return true

## Dopo il JSON i numeri sono float: li riporta a interi dove servono.
func _normalizza(x) -> void:
	if typeof(x) == TYPE_DICTIONARY:
		for k in x.keys():
			var v = x[k]
			if typeof(v) == TYPE_FLOAT and v == floor(v):
				x[k] = int(v)
			else:
				_normalizza(v)
	elif typeof(x) == TYPE_ARRAY:
		for i in x.size():
			var v2 = x[i]
			if typeof(v2) == TYPE_FLOAT and v2 == floor(v2):
				x[i] = int(v2)
			else:
				_normalizza(v2)
