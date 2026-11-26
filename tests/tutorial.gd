## Gioca il tutorial dall'inizio alla fine controllando che ogni azione attesa sia disponibile.
extends SceneTree

func _init() -> void:
	var m = Motore.new()
	var t = Tutorial.new()
	t.avvia(m)
	var errori = 0
	var n = 0
	while t.indice < t.passi.size():
		var p: Dictionary = t.passi[t.indice]
		var att: String = p.get("attendi", "")
		if att == "":
			t.indice += 1
			continue
		n += 1
		var ids = []
		for o in m.s.get("scelta", {}).get("opzioni", []): ids.append(o["id"])
		if not att in ids:
			printerr("passo %d: azione attesa %s non disponibile; scelta %s con %s" % [t.indice, att, m.s.get("scelta", {}).get("tipo", "?"), ids])
			print(m.s["diario"].slice(-8))
			errori += 1
			break
		t.consenti(att)
		m.scegli(att, {"selezione": {}})
		if not m.dadi_forzati.is_empty():
			printerr("passo %d (%s): dadi preparati non usati: %s" % [t.indice - 1, att, m.dadi_forzati])
			errori += 1
		for e in m.eventi:
			if e["tipo"] == "log": print("   ", e["testo"])
		m.eventi.clear()
		print("passo %d ok: %s -> %s" % [t.indice - 1, att, m.s.get("scelta", {}).get("tipo", "?")])
	if errori > 0:
		printerr("TUTORIAL CON ERRORI")
		quit(1)
		return
	print("tutorial completo: %d azioni guidate" % n)
	quit(0)
