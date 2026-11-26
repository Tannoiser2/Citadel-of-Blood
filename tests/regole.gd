## Controlli puntuali delle regole: godot --headless -s tests/regole.gd
extends SceneTree

const D = preload("res://scripts/dati.gd")
var falliti := 0

func verifica(cond: bool, testo: String) -> void:
	if cond:
		print("ok  ", testo)
	else:
		printerr("NO  ", testo)
		falliti += 1

func _init() -> void:
	# Tabella dei risultati: esempio del regolamento (Almuric tira 4 +2 +3 = 9 con la spada)
	verifica(D.ferite_crt("spada", 9) == 1, "CRT spada 9 → 1 ferita")
	verifica(D.ferite_crt("martello", 17) == 5, "CRT martello 17+ → 5")
	verifica(D.ferite_crt("mostro", 5) == 0 and D.ferite_crt("mostro", 6) == 1, "CRT mostri 5/6")
	verifica(D.esito_negoziazione(6) == "fallimento" and D.esito_negoziazione(7) == "accordo" and D.esito_negoziazione(10) == "intimidazione", "negoziazione")
	verifica(D.CORRUZIONE[4][2] == 4, "corruzione 100 marchi, colonna 10-12 → 4")
	verifica(D.lettera_tesoro("C", 2) == "E", "tesoro C al livello 3 diventa E")
	verifica(Motore.ruota_uscite("DWCW", 1) == "WDWC", "rotazione delle uscite")
	var m := Motore.new()
	verifica(m.tessere.size() == 100, "100 tessere caricate")
	m.nuova_partita({"seme": 5, "eroi": ["almuric", "gislan", "dalmilandril"], "iniziati": [
		{"nome": "A", "razza": "umano", "arma2": "pugnale", "esperienza": "pf", "tiro_pm": 6},
		{"nome": "B", "razza": "nano", "arma2": "pugnale", "esperienza": "pf", "tiro_pm": 1},
		{"nome": "C", "razza": "elfo", "arma2": "pugnale", "esperienza": "pf", "tiro_pm": 3}]})
	verifica(m.pg("ini1")["pf_max"] == 8, "iniziato umano con esperienza: 7+1 PF")
	verifica(m.pg("ini1")["pm"] == [2, 2, 2], "Potenziale Magico tiro 6 → 2/2/2")
	verifica(m.pg("almuric")["inc_noti"].size() == 2, "Almuric conosce 2 incantesimi (PM 1/1/2)")
	verifica(not m.s["scelta"].is_empty(), "dopo l'avvio c'è una scelta")
	# bersagli 9.3: tre personaggi contro due mostri in posizione 1 e 2
	m.s["comb"] = {"mostri": {"m:1": {"nome": "A", "pf_max": 5, "ferite": 0}, "m:2": {"nome": "B", "pf_max": 5, "ferite": 0}},
		"ordine_m": [["m:1", "m:2", ""], ["", "", ""], ["", "", ""]], "solo": ""}
	m.s["ordine"] = [["p:almuric", "p:gislan", "p:dalmilandril"], ["p:ini1", "p:ini2", "p:ini3"], ["", "", ""]]
	verifica(m.bersagli("m:1") == ["p:almuric"], "9.3: A attacca 1")
	var bb := m.bersagli("m:2")
	verifica(bb.size() == 2 and "p:gislan" in bb and "p:dalmilandril" in bb, "9.3: B sceglie tra 2 e 3")
	m.s["comb"]["ordine_m"] = [["", "m:1", ""], ["", "", ""], ["", "", ""]]
	verifica(m.bersagli("m:1").size() == 3, "9.3: un solo mostro al centro può colpire tutti e tre")
	verifica(m.bersagli("p:almuric") == ["m:1"], "9.3: il personaggio a sinistra colpisce il mostro al centro")
	# prova di tutte le tessere: ogni faccia ha almeno un'uscita
	var vuote := 0
	for t in m.tessere:
		if t["fronte"]["uscite"] == "WWWW" or t["retro"]["uscite"] == "WWWW": vuote += 1
	verifica(vuote == 0, "ogni faccia di tessera ha almeno un'uscita")
	# tesori: 200 estrazioni di tipo L non danno errori e producono oggetti validi
	var ogg := 0
	for k in 200:
		var t2 := m.genera_tesoro("L")
		ogg += t2["oggetti"].size()
		for o in t2["oggetti"]:
			if not o.has("nome"): falliti += 1
	verifica(ogg > 0, "il tesoro L contiene oggetti magici (%d)" % ogg)
	if falliti > 0:
		printerr("controlli falliti: %d" % falliti)
		quit(1)
		return
	print("tutti i controlli superati")
	quit(0)
