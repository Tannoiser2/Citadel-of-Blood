## Partite automatiche: un giocatore casuale gioca molte spedizioni per stanare errori del motore.
## Uso: godot --headless -s tests/partite_auto.gd -- [numero partite]
extends SceneTree

const D = preload("res://scripts/dati.gd")

func _init() -> void:
	var n := 60
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		n = int(a[0])
	var tot := {"vittorie": 0, "sconfitte": 0, "uscite": 0, "turni": 0, "segmenti": 0, "porte_trovate": 0, "uccisi": 0, "combattimenti": 0}
	var errori := 0
	for i in n:
		var m := Motore.new()
		var rng := RandomNumberGenerator.new()
		rng.seed = 7000 + i
		var eroi := []
		var pool := D.EROI.duplicate()
		for k in 3:
			var j := rng.randi_range(0, pool.size() - 1)
			eroi.append(pool[j]["id"])
			pool.remove_at(j)
		m.nuova_partita({"seme": 1000 + i, "eroi": eroi, "iniziati": [
			{"nome": "Borin", "razza": "nano", "arma2": "pugnale", "esperienza": "pf"},
			{"nome": "Lithiel", "razza": "elfo", "femmina": true, "arma2": "pugnale", "esperienza": "arma"},
			{"nome": "Corrado", "razza": "umano", "arma2": "pugnale_lancio", "esperienza": "abilita"}]})
		var passi := 0
		var spedizioni := 0
		while m.s.get("fine", "") == "" and passi < 6000:
			passi += 1
			var sc: Dictionary = m.s.get("scelta", {})
			if sc.is_empty():
				printerr("partita %d passo %d: nessuna scelta! ultimo diario: %s" % [i, passi, m.s["diario"].slice(-5)])
				errori += 1
				break
			var opz: Array = sc["opzioni"]
			var o: Dictionary = _scegli(m, sc, opz, rng, passi, spedizioni)
			if sc["tipo"] == "riposo":
				spedizioni += 1
			# azioni fuori combattimento ogni tanto
			if rng.randf() < 0.1 and m.puo_agire_fuori_combattimento():
				for id in m.pg_in_gruppo():
					for x in m.incantesimi_fuori(id):
						m.lancia_fuori(id, x[0], x[1][0])
						break
			if passi % 13 == 0:
				var copia := m.esporta()
				var q := Motore.new()
				if not q.importa(copia):
					printerr("partita %d: importazione fallita" % i)
					errori += 1
				m = q
			m.eventi.clear()
			m.scegli(o["id"], {"selezione": {}})
			_controlla(m, i)
		if m.s.get("fine", "") == "" :
			printerr("partita %d non finita dopo %d passi: %s" % [i, passi, m.s.get("scelta", {}).get("tipo", "?")])
			errori += 1
		match m.s.get("fine", ""):
			"vittoria": tot["vittorie"] += 1
			"sconfitta": tot["sconfitte"] += 1
			_: tot["uscite"] += 1
		tot["turni"] += int(m.s["turno"])
		tot["segmenti"] += int(m.s.get("segmenti_esplorati", 0))
		tot["porte_trovate"] += 1 if m.s["hellgate"]["trovata"] else 0
		tot["uccisi"] += int(m.s["statistiche"]["uccisi"])
		if i < 3:
			print("--- partita %d: %s, turno %d, %d segmenti, ultime righe: %s" % [i, m.s.get("fine", ""), int(m.s["turno"]), int(m.s.get("segmenti_esplorati", 0)), str(m.s["diario"].slice(-3))])
	print("partite %d: vittorie %d, sconfitte %d, uscite %d; turni medi %.1f; segmenti medi %.1f; Porta trovata %d volte; mostri uccisi %d" % [n, tot["vittorie"], tot["sconfitte"], tot["uscite"], float(tot["turni"]) / n, float(tot["segmenti"]) / n, tot["porte_trovate"], tot["uccisi"]])
	if errori > 0:
		printerr("ERRORI: %d" % errori)
		quit(1)
		return
	print("partite automatiche riuscite")
	quit(0)

## Giocatore automatico un po' sensato: esplora, combatte, indaga, prova a distruggere la Porta.
func _scegli(m: Motore, sc: Dictionary, opz: Array, rng: RandomNumberGenerator, passi: int, spedizioni: int) -> Dictionary:
	var prefer := []
	match sc["tipo"]:
		"rotta":
			prefer = opz.filter(func(x): return x["azione"] == "distruggi")
			if prefer.is_empty() and m.s["hellgate"]["distrutta"]:
				prefer = opz.filter(func(x): return x["azione"] == "esci" or x["azione"] == "vai" or x["id"] == "liv|1")
				if not prefer.is_empty() and rng.randf() < 0.5:
					var esci := opz.filter(func(x): return x["azione"] == "esci")
					if not esci.is_empty(): prefer = esci
			if prefer.is_empty():
				prefer = opz.filter(func(x): return x["azione"] in ["esplora", "livello"])
			if prefer.is_empty() or rng.randf() < 0.25:
				prefer = opz.filter(func(x): return x["azione"] != "esci" or passi > 400)
		"azione":
			prefer = opz.filter(func(x): return x["azione"] != "passa" and x["azione"] != "cambia")
		"riposo":
			if spedizioni < 2:
				prefer = opz.filter(func(x): return x["id"] == "rientra")
			if prefer.is_empty():
				prefer = opz.filter(func(x): return x["id"] == "termina")
		"migliora":
			prefer = opz.filter(func(x): return x["id"] == "fatto")
	if prefer.is_empty():
		prefer = opz
	return prefer[rng.randi_range(0, prefer.size() - 1)]

func _controlla(m: Motore, i: int) -> void:
	for id in m.s["gruppo"]:
		var p: Dictionary = m.s["gruppo"][id]
		if int(p["ferite"]) < 0:
			printerr("partita %d: ferite negative per %s" % [i, p["nome"]])
			quit(1)
	var visti := {}
	for fila in m.s["ordine"]:
		for u in fila:
			if u == "": continue
			if visti.has(u):
				printerr("partita %d: %s due volte nell'ordine di marcia" % [i, u])
				quit(1)
			visti[u] = true
