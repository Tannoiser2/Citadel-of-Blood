extends RefCounted
class_name MotoreBase
## Base del motore: stato serializzabile, dadi, diario, gruppo e labirinto.
## Tutto lo stato sta nel dizionario `s` (salvabile in JSON).

const D = preload("res://scripts/dati.gd")

var s: Dictionary = {}
var rng := RandomNumberGenerator.new()
var dadi_forzati: Array = []        # tutorial e test: i prossimi tiri di dado
var tessere_forzate: Array = []     # tutorial: le prossime tessere pescate [id, ...]
var eventi: Array = []              # per l'interfaccia: dadi, movimenti, danni...
var tessere: Array = []             # dati delle 100 tessere (data/tessere.json)

func _init() -> void:
	var f := FileAccess.open("res://data/tessere.json", FileAccess.READ)
	if f:
		tessere = JSON.parse_string(f.get_as_text())

# --------------------------------------------------------------------------------------------
# Dadi
# --------------------------------------------------------------------------------------------
func d6() -> int:
	var v: int
	if not dadi_forzati.is_empty():
		v = int(dadi_forzati.pop_front())
	else:
		v = rng.randi_range(1, 6)
	s["rng_stato"] = str(rng.state)
	return v

func d3() -> int:
	return int(ceil(d6() / 2.0))

func tira(n: int, facce: int = 6) -> int:
	var t := 0
	for i in n:
		t += d3() if facce == 3 else d6()
	return t

## "1D3+2", "1D6", "2" ...
func tira_codice(codice: String) -> int:
	if not "D" in codice:
		return int(codice)
	var parti := codice.split("+")
	var base := parti[0].split("D")
	var v := tira(int(base[0]), int(base[1]))
	if parti.size() > 1:
		v += int(parti[1])
	return v

func evento(e: Dictionary) -> void:
	eventi.append(e)

func mostra_dadi(valori: Array, testo: String) -> void:
	evento({"tipo": "dadi", "valori": valori, "testo": testo})

# --------------------------------------------------------------------------------------------
# Diario
# --------------------------------------------------------------------------------------------
func annota(testo: String, tipo: String = "") -> void:
	var d: Array = s.get("diario", [])
	d.append({"t": testo, "k": tipo, "turno": s.get("turno", 0)})
	if d.size() > 600:
		d.remove_at(0)
	s["diario"] = d
	evento({"tipo": "log", "testo": testo, "k": tipo})

# --------------------------------------------------------------------------------------------
# Personaggi
# --------------------------------------------------------------------------------------------
func pg(id: String) -> Dictionary:
	return s["gruppo"].get(id, {})

func nome(uid: String) -> String:
	var u := unita(uid)
	return u.get("nome", uid)

func pf_residui(u: Dictionary) -> int:
	return int(u["pf_max"]) + int(u.get("pf_armatura", 0)) - int(u["ferite"])

func vivo(u: Dictionary) -> bool:
	return u.get("stato", "ok") != "morto" and pf_residui(u) > 0

## Personaggi presenti e utilizzabili (non morti, non pietrificati, non prigionieri dell'Hellgate)
func pg_attivi() -> Array:
	var r := []
	for id in s.get("ordine_ids", []):
		var p := pg(id)
		if p.is_empty(): continue
		if p.get("stato", "ok") in ["ok", "incantato", "posseduto"]:
			r.append(id)
	return r

func pg_in_gruppo() -> Array:
	## solo quelli che marciano col gruppo (non incantati dai mostri)
	var r := []
	for id in pg_attivi():
		if pg(id).get("stato", "ok") == "ok":
			r.append(id)
	return r

func nuovo_pg_eroe(id: String) -> Dictionary:
	var e: Dictionary = D.eroe(id)
	var p := {
		"id": id, "nome": e["nome"], "tipo": "eroe", "razza": e["razza"], "ritratto": "h_" + id,
		"pf_max": e["pf"], "ferite": 0, "pm": e["pm"].duplicate(), "vr": e["vr"], "bc": e["bc"],
		"armi": [], "arma_att": 0, "abil": e["abil"].duplicate(),
		"disinnesco": e.get("disinnesco", 0), "hellgate": e.get("hellgate", 0), "negoziazione": e.get("negoziazione", 0),
	}
	for a in e["armi"]:
		p["armi"].append({"tipo": a, "bonus": 0})
	return _completa_pg(p)

func nuovo_pg_iniziato(id: String, nome_pg: String, razza: String, femmina: bool, arma2: String, esperienza: String, tiro_pm: int) -> Dictionary:
	var r: Dictionary = D.RAZZE_INIZIATI[razza]
	var p := {
		"id": id, "nome": nome_pg, "tipo": "iniziato", "razza": r["nome"] if not femmina else (r["nome"].substr(0, r["nome"].length() - 1) + "a"),
		"ritratto": "i_%s_%s" % [razza, "f" if femmina else "m"],
		"pf_max": r["pf"], "ferite": 0, "pm": D.POTENZIALE[clamp(tiro_pm, 1, 6) - 1].duplicate(), "vr": r["vr"], "bc": 0,
		"armi": [{"tipo": r["arma"], "bonus": 0}, {"tipo": arma2, "bonus": 0}], "arma_att": 0,
		"abil": {r["arma"]: 1}, "disinnesco": 0, "hellgate": 0, "negoziazione": 0,
	}
	p[r["abilita"]] = 1
	match esperienza:
		"pf": p["pf_max"] += 1
		"arma": p["abil"][r["arma"]] = 2
		"abilita": p[r["abilita"]] = 2
	return _completa_pg(p)

func _completa_pg(p: Dictionary) -> Dictionary:
	p.merge({
		"stato": "ok", "inc_noti": [], "inc_attivi": [], "oggetti": [], "oro": 0, "gioielli": [], "xp": 0,
		"usi_cura": {}, "pf_armatura": 0, "armatura_magica": 0, "scudo_magico": false, "bc_temp": 0,
		"pugnale_lanciato": false, "flag": {}, "uscite": 0, "ferite_ingresso": 0,
	}, false)
	return p

func max_pm(p: Dictionary) -> int:
	return int(max(p["pm"][0], max(p["pm"][1], p["pm"][2])))

func pm_sole(p: Dictionary) -> int:
	var i := D.SOLI.find(s.get("sole", "giallo"))
	return int(p["pm"][max(i, 0)])

func bc_totale(p: Dictionary) -> int:
	var b := int(p["bc"]) + int(p.get("bc_temp", 0))
	for o in p.get("oggetti", []):
		if o.get("tipo") == "medaglione" and o.get("var") == "destrezza":
			b += 2
	return b

func vr_totale(u: Dictionary) -> int:
	var v := int(u.get("vr", 1))
	for o in u.get("oggetti", []):
		if o.get("tipo") == "anello" and o.get("var") == "resistenza1": v += 1
		if o.get("tipo") == "anello" and o.get("var") == "resistenza2": v += 2
	return v

func arma(p: Dictionary) -> Dictionary:
	var armi: Array = p.get("armi", [])
	if armi.is_empty():
		return {"tipo": "pugnale", "bonus": 0}
	return armi[clamp(int(p.get("arma_att", 0)), 0, armi.size() - 1)]

func ha_oggetto(p: Dictionary, tipo: String, variante: String) -> bool:
	for o in p.get("oggetti", []):
		if o.get("tipo") == tipo and o.get("var") == variante:
			return true
	return false

func ricchezza(p: Dictionary) -> int:
	var t := int(p.get("oro", 0))
	for g in p.get("gioielli", []):
		t += int(g)
	return t

## Prova di Resistenza (11.0): 1D6 <= VR
func resiste(uid: String, motivo: String) -> bool:
	var u := unita(uid)
	var v := vr_totale(u)
	var t := d6()
	var ok := t <= v
	mostra_dadi([t], "Resistenza di %s (VR %d)" % [u.get("nome", uid), v])
	annota("%s tenta di resistere a %s: tira %d contro VR %d, %s." % [u.get("nome", uid), motivo, t, v, "resiste" if ok else "non resiste"], "dado")
	return ok

# unità: personaggio ("p:id") o mostro ("m:n")
func unita(uid: String) -> Dictionary:
	if uid.begins_with("p:"):
		return pg(uid.substr(2))
	if uid.begins_with("m:"):
		var al: Dictionary = s.get("alleati", {})
		if al.has(uid):
			return al[uid]
		var c: Dictionary = s.get("comb", {})
		var m: Dictionary = c.get("mostri", {}).get(uid, {})
		if m.is_empty():
			m = s.get("incontro", {}).get("mostri", {}).get(uid, {})
		return m
	return {}

# --------------------------------------------------------------------------------------------
# Labirinto
# --------------------------------------------------------------------------------------------
static func chiave(v: Vector2i) -> String:
	return "%d,%d" % [v.x, v.y]

static func da_chiave(k: String) -> Vector2i:
	var p := k.split(",")
	return Vector2i(int(p[0]), int(p[1]))

func mappa(liv: int) -> Dictionary:
	var m: Dictionary = s["mappe"]
	var k := str(liv)
	if not m.has(k):
		m[k] = {"seg": {}, "hub": ""}
	return m[k]

func segmento(liv: int, k: String) -> Dictionary:
	return mappa(liv)["seg"].get(k, {})

func seg_attuale() -> Dictionary:
	return segmento(int(s["pos"]["liv"]), s["pos"]["xy"])

## uscite di una faccia ruotata di rot quarti di giro in senso orario
static func ruota_uscite(u: String, rot: int) -> String:
	var r := ""
	for i in 4:
		r += u[(i - rot + 8) % 4]
	return r

func faccia(id_tessera: int, lato: String) -> Dictionary:
	if id_tessera < 0 or id_tessera >= tessere.size():
		return {"uscite": "DDDD", "griglia": [], "elemento": ""}
	return tessere[id_tessera][lato]

func nuovo_segmento(id_tessera: int, lato: String, rot: int, xy: Vector2i) -> Dictionary:
	var f := faccia(id_tessera, lato)
	return {
		"t": id_tessera, "lato": lato, "rot": rot, "x": xy.x, "y": xy.y,
		"uscite": ruota_uscite(f["uscite"], rot),
		"tipo": "stanza" if lato == "fronte" else "corridoio",
		"elemento": f.get("elemento", "") if lato == "fronte" else "",
		"visitato": false, "elemento_usato": false, "mostri": [], "chiuse": [],
		"hellgate": false, "ingresso": false, "scala_hub": false,
	}

## tipo dell'uscita di un segmento verso la direzione d (0..3); "W" se muro
func uscita(seg: Dictionary, d: int) -> String:
	if seg.is_empty(): return "W"
	if d in seg.get("chiuse", []): return "W"
	return seg["uscite"][d]

## Compatibilità di un lato con il vicino (6.1): porta con porta, corridoio con corridoio, muro con muro.
func lati_compatibili(a: String, b: String) -> bool:
	if a == "*" or b == "*": return true
	return a == b

func frontiera_aperta(liv: int, extra: Dictionary = {}) -> int:
	## numero di uscite che portano a celle ancora vuote (6.4: niente vicoli ciechi)
	var segs: Dictionary = mappa(liv)["seg"].duplicate()
	for k in extra: segs[k] = extra[k]
	var n := 0
	for k in segs:
		var sg: Dictionary = segs[k]
		var xy := Vector2i(int(sg["x"]), int(sg["y"]))
		for d in 4:
			if uscita(sg, d) == "W": continue
			var vk := chiave(xy + D.VETTORI[d])
			if not segs.has(vk):
				n += 1
	return n

## Orientamenti validi di una tessera entrando dal lato `entrata` (direzione dal nuovo segmento verso l'origine)
func orientamenti(liv: int, id_t: int, lato: String, xy: Vector2i, entrata: int, tipo_ingresso: String, rigoroso: bool) -> Array:
	var f := faccia(id_t, lato)
	var validi := []
	for rot in 4:
		var u := ruota_uscite(f["uscite"], rot)
		var ok := true
		for d in 4:
			var vicino := segmento(liv, chiave(xy + D.VETTORI[d]))
			if d == entrata:
				if tipo_ingresso == "*":
					if u[d] == "W": ok = false
				elif u[d] != tipo_ingresso:
					ok = false
				continue
			if vicino.is_empty() or not rigoroso: continue
			var opposto := uscita(vicino, (d + 2) % 4)
			if vicino.get("ingresso", false): opposto = "W"
			if not lati_compatibili(u[d], opposto):
				ok = false
		if ok:
			validi.append(rot)
	return validi

func pesca_tessera() -> int:
	if not tessere_forzate.is_empty():
		var t := int(tessere_forzate.pop_front())
		s["tazza"].erase(t)
		return t
	var tazza: Array = s["tazza"]
	if tazza.is_empty():
		return -1
	var i := rng.randi_range(0, tazza.size() - 1)
	s["rng_stato"] = str(rng.state)
	var t: int = tazza[i]
	tazza.remove_at(i)
	return t

func rimetti_tessera(t: int) -> void:
	if t >= 0:
		s["tazza"].append(t)

func cerca_scala_in_tazza() -> int:
	for t in s["tazza"]:
		if faccia(int(t), "fronte").get("elemento", "") == "scala":
			s["tazza"].erase(t)
			return int(t)
	return -1

func descrivi_uscite(u: String) -> String:
	var parti := []
	var nomi := ["nord", "est", "sud", "ovest"]
	for d in 4:
		if u[d] == "D": parti.append("porta a " + nomi[d])
		elif u[d] == "C": parti.append("corridoio a " + nomi[d])
	if parti.is_empty(): return "nessuna uscita"
	return ", ".join(parti)

const NOMI_DIR := ["nord", "est", "sud", "ovest"]
