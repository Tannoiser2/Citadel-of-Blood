extends RefCounted
class_name Dati
## Tabelle e dati di Citadel of Blood (SPI, ARES n. 5, 1980), tradotti in italiano.
## Ogni tabella riporta tra parentesi il numero del paragrafo del regolamento originale.

# --- Armi e Tabella dei Risultati del Combattimento (9.9) ---------------------------------
const ARMI := {
	"pugnale": "Pugnale",
	"pugnale_lancio": "Pugnale da lancio",
	"arco": "Arco",
	"spada": "Spada",
	"martello": "Martello",
	"ascia": "Ascia",
	"mostro": "Mostri",
}
# righe: 1-3, 4, 5, 6-9, 10, 11, 12, 13, 14, 15, 16, 17+
const CRT := {
	"pugnale":        [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4, 4],
	"pugnale_lancio": [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4],
	"arco":           [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 4, 4],
	"spada":          [0, 1, 1, 1, 2, 2, 2, 3, 3, 4, 4, 5],
	"martello":       [0, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
	"ascia":          [0, 1, 1, 1, 2, 2, 2, 3, 4, 4, 5, 5],
	"mostro":         [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 4, 5],
}
const CRT_RIGHE := ["1-3", "4", "5", "6-9", "10", "11", "12", "13", "14", "15", "16", "17+"]

static func riga_crt(totale: int) -> int:
	if totale <= 3: return 0
	if totale == 4: return 1
	if totale == 5: return 2
	if totale <= 9: return 3
	if totale >= 17: return 11
	return totale - 6

static func ferite_crt(arma: String, totale: int) -> int:
	var col: Array = CRT.get(arma, CRT["mostro"])
	return col[riga_crt(totale)]

# --- Eroi (4.3) ----------------------------------------------------------------------------
# nome, razza, PF, PM [rosso, giallo, blu], VR, BC, armi, abilità con le armi, abilità speciali
const EROI := [
	{"id": "almuric", "nome": "Almuric", "razza": "Umano", "pf": 8, "pm": [1, 1, 2], "vr": 2, "bc": 3, "armi": ["spada", "pugnale"], "abil": {"spada": 2}, "hellgate": 1},
	{"id": "alric", "nome": "Alric", "razza": "Umano", "pf": 6, "pm": [2, 3, 4], "vr": 2, "bc": 0, "armi": ["spada", "pugnale_lancio"], "abil": {}, "hellgate": 1},
	{"id": "curvenol", "nome": "Curvenol", "razza": "Umano", "pf": 5, "pm": [5, 5, 5], "vr": 1, "bc": 0, "armi": ["spada", "pugnale_lancio"], "abil": {}, "hellgate": 2},
	{"id": "dalmilandril", "nome": "Dalmilandril", "razza": "Elfo", "pf": 5, "pm": [3, 4, 5], "vr": 3, "bc": 2, "armi": ["arco", "pugnale"], "abil": {"arco": 2}, "negoziazione": 2},
	{"id": "dierdra", "nome": "Dierdra", "razza": "Umana", "pf": 7, "pm": [0, 0, 0], "vr": 1, "bc": 4, "armi": ["martello", "spada"], "abil": {"martello": 1}, "hellgate": 1},
	{"id": "eodred", "nome": "Eodred", "razza": "Umano", "pf": 6, "pm": [3, 4, 5], "vr": 2, "bc": 0, "armi": ["arco", "pugnale_lancio"], "abil": {}, "hellgate": 2},
	{"id": "gerudirr", "nome": "Gerudirr", "razza": "Nano", "pf": 6, "pm": [0, 0, 0], "vr": 2, "bc": 6, "armi": ["ascia", "pugnale"], "abil": {"ascia": 3}, "disinnesco": 1},
	{"id": "gilith", "nome": "Gilith", "razza": "Elfa", "pf": 8, "pm": [0, 0, 0], "vr": 3, "bc": 4, "armi": ["arco", "pugnale"], "abil": {"arco": 2}, "negoziazione": 2},
	{"id": "gislan", "nome": "Gislan", "razza": "Nano", "pf": 10, "pm": [4, 4, 4], "vr": 3, "bc": 4, "armi": ["ascia", "martello"], "abil": {"ascia": 2}, "disinnesco": 3},
	{"id": "gwaigilion", "nome": "Gwaigilion Elengal", "razza": "Elfo", "pf": 7, "pm": [4, 3, 2], "vr": 3, "bc": 4, "armi": ["arco", "pugnale"], "abil": {"arco": 2}, "negoziazione": 1},
	{"id": "larraka", "nome": "Larraka", "razza": "Umana", "pf": 5, "pm": [6, 5, 4], "vr": 3, "bc": 0, "armi": ["arco", "pugnale"], "abil": {}, "hellgate": 1},
	{"id": "linfalas", "nome": "Linfalas", "razza": "Elfo", "pf": 9, "pm": [0, 0, 0], "vr": 2, "bc": 5, "armi": ["arco", "spada"], "abil": {"arco": 2}, "negoziazione": 3},
	{"id": "lord_dil", "nome": "Lord Dil", "razza": "Umano", "pf": 10, "pm": [0, 0, 0], "vr": 3, "bc": 5, "armi": ["spada", "pugnale"], "abil": {"spada": 2}, "hellgate": 2},
	{"id": "maytwist", "nome": "Maytwist", "razza": "Elfa", "pf": 7, "pm": [3, 3, 3], "vr": 2, "bc": 0, "armi": ["pugnale_lancio", "arco"], "abil": {"arco": 2}, "negoziazione": 3},
	{"id": "paladin_glade", "nome": "Paladino Glade", "razza": "Umano", "pf": 10, "pm": [0, 0, 0], "vr": 2, "bc": 4, "armi": ["spada", "pugnale_lancio"], "abil": {"spada": 2}, "hellgate": 2},
	{"id": "raman", "nome": "Raman Cronkevitch", "razza": "Mezzo-Cronk", "pf": 9, "pm": [0, 0, 0], "vr": 3, "bc": 4, "armi": ["spada", "pugnale"], "abil": {"spada": 1}, "disinnesco": 1},
	{"id": "sliggoth", "nome": "Sliggoth", "razza": "Creatura delle Paludi", "pf": 8, "pm": [1, 2, 3], "vr": 2, "bc": 4, "armi": ["ascia", "arco"], "abil": {"ascia": 1}, "disinnesco": 1},
	{"id": "stephen", "nome": "Stephen il Paladino", "razza": "Umano", "pf": 10, "pm": [0, 0, 0], "vr": 2, "bc": 5, "armi": ["spada", "pugnale"], "abil": {"spada": 2}, "hellgate": 2},
	{"id": "theregond", "nome": "Theregond", "razza": "Umano", "pf": 8, "pm": [4, 3, 2], "vr": 2, "bc": 1, "armi": ["spada", "pugnale_lancio"], "abil": {"spada": 3}, "hellgate": 3},
	{"id": "weldron", "nome": "Weldron", "razza": "Umano", "pf": 9, "pm": [0, 0, 0], "vr": 2, "bc": 5, "armi": ["spada", "arco"], "abil": {"spada": 2}, "hellgate": 3},
	{"id": "wendolyn", "nome": "Wendolyn", "razza": "Umana", "pf": 7, "pm": [4, 3, 2], "vr": 2, "bc": 1, "armi": ["spada", "pugnale"], "abil": {"pugnale": 2}, "hellgate": 4},
	{"id": "zareth", "nome": "Zareth", "razza": "Umano", "pf": 9, "pm": [0, 0, 0], "vr": 4, "bc": 4, "armi": ["spada", "pugnale_lancio"], "abil": {"spada": 1}, "hellgate": 3},
	{"id": "zurik", "nome": "Zurik", "razza": "Nano", "pf": 8, "pm": [3, 4, 5], "vr": 2, "bc": 3, "armi": ["ascia", "pugnale"], "abil": {"ascia": 2}, "disinnesco": 3},
]

static func eroe(id: String) -> Dictionary:
	for e in EROI:
		if e["id"] == id:
			return e
	return {}

# --- Iniziati (4.1 B) ----------------------------------------------------------------------
const RAZZE_INIZIATI := {
	"elfo":  {"nome": "Elfo",  "pf": 5, "vr": 2, "arma": "arco",   "abilita": "negoziazione"},
	"nano":  {"nome": "Nano",  "pf": 6, "vr": 2, "arma": "ascia",  "abilita": "disinnesco"},
	"umano": {"nome": "Umano", "pf": 7, "vr": 1, "arma": "spada",  "abilita": "hellgate"},
}
# Tabella del Potenziale Magico (4.4): per il tiro 1..6 [rosso, giallo, blu]
const POTENZIALE := [[0, 0, 0], [0, 0, 0], [2, 1, 0], [0, 1, 2], [1, 1, 1], [2, 2, 2]]
const NOMI_INIZIATI := {
	"elfo": ["Aelrin", "Lithiel", "Faelwen", "Thandor", "Ilmare", "Caladh"],
	"nano": ["Borin", "Thrudda", "Kargun", "Dagna", "Orik", "Helga"],
	"umano": ["Bertrando", "Ilaria", "Corrado", "Gisella", "Rolando", "Matilde"],
}

# --- Soli (4.1 D) ---------------------------------------------------------------------------
const SOLI := ["rosso", "giallo", "blu"]
const NOMI_SOLI := {"rosso": "Sole rosso", "giallo": "Sole giallo", "blu": "Sole blu"}

# --- Incantesimi (10.9) ---------------------------------------------------------------------
# tipo: C combattimento, NC fuori combattimento, N negoziazione, B corruzione, S speciale
const INCANTESIMI := {
	"cm": {"nome": "Incantamento", "orig": "Charm", "costo": 3, "tipo": "C", "res": true,
		"testo": "Un mostro in prima o seconda fila che fallisce la Resistenza passa dalla parte del gruppo."},
	"bl": {"nome": "Scarica", "orig": "Blast", "costo": 1, "tipo": "C", "res": true,
		"testo": "Un mostro in prima fila subisce 2 ferite, se non resiste."},
	"ex": {"nome": "Esplosione", "orig": "Explosion", "costo": 1, "tipo": "C", "res": true,
		"testo": "Tutti, mostri e personaggi, fanno la Resistenza: chi fallisce subisce 1 ferita."},
	"lt": {"nome": "Fulmine", "orig": "Lightning", "costo": 2, "tipo": "C", "res": true,
		"testo": "Un mostro in prima fila subisce 1D3+2 ferite, se non resiste."},
	"sl": {"nome": "Sonno", "orig": "Sleep", "costo": 2, "tipo": "C", "res": true,
		"testo": "Un mostro di qualsiasi fila si addormenta; quando gli altri sono morti o addormentati è ucciso."},
	"rd": {"nome": "Redenzione", "orig": "Redemption", "costo": 3, "tipo": "C", "res": true,
		"testo": "Un personaggio incantato o posseduto torna nel gruppo, se non resiste."},
	"ms": {"nome": "Scudo magico", "orig": "Magic Shield", "costo": 2, "tipo": "C", "res": false,
		"testo": "Il bersaglio è immune agli incantesimi che infliggono ferite per tutto il combattimento."},
	"hs": {"nome": "Esitazione", "orig": "Hesitate", "costo": 2, "tipo": "C", "res": false,
		"testo": "Prima dello scontro il gruppo ha il tempo di usare pozioni e incantesimi di cura."},
	"cf": {"nome": "Tregua", "orig": "Cease Fire", "costo": 3, "tipo": "C", "res": false,
		"testo": "Come un Accordo: il combattimento finisce subito. Non funziona contro X lo Sconosciuto."},
	"ma": {"nome": "Attacco mentale", "orig": "Mental Attack", "costo": 4, "tipo": "C", "res": true,
		"testo": "Un mostro in prima fila subisce 2D6+2 ferite, se non resiste."},
	"lk": {"nome": "Serratura", "orig": "Lock", "costo": 1, "tipo": "NC", "res": false,
		"testo": "Dopo aver aperto una porta e visto un mostro, la si richiude per sempre e si torna indietro."},
	"mr": {"nome": "Armatura magica", "orig": "Mage Armor", "costo": 1, "tipo": "NC", "res": false,
		"testo": "Il bersaglio assorbe 1D3+1 ferite prima di subirne."},
	"np": {"nome": "Neutralizza veleno", "orig": "Neutralize Poison", "costo": 1, "tipo": "NC", "res": false,
		"testo": "Annulla subito gli effetti di un veleno appena subito."},
	"sf": {"nome": "Pietra in carne", "orig": "Stone-Flesh", "costo": 3, "tipo": "NC", "res": false,
		"testo": "Riporta in vita un personaggio pietrificato dalla Medusa. Non su se stessi."},
	"st": {"nome": "Forza", "orig": "Strength", "costo": 1, "tipo": "NC", "res": false,
		"testo": "Come una pozione della Forza: +1D6 al Bonus di Combattimento nel prossimo scontro."},
	"he": {"nome": "Guarigione", "orig": "Heal", "costo": 1, "tipo": "NC", "res": false,
		"testo": "Cura 1D3+1 ferite di un altro personaggio. Usi limitati a 1D6 per partita."},
	"rj": {"nome": "Rigenerazione", "orig": "Rejuvenate", "costo": 2, "tipo": "NC", "res": false,
		"testo": "Cura 1D6+1 ferite di un altro personaggio. Usi limitati a 1D6 per partita."},
	"tl": {"nome": "Teletrasporto", "orig": "Teleport", "costo": 3, "tipo": "NC", "res": false,
		"testo": "Durante negoziazione o corruzione spedisce un mostro in un segmento già esplorato."},
	"tf": {"nome": "Ladro", "orig": "Thief", "costo": 1, "tipo": "NC", "res": false,
		"testo": "+3 al Disinnesco per un tentativo; solo su chi sa già disinnescare."},
	"or": {"nome": "Oratoria", "orig": "Oratory", "costo": 1, "tipo": "N", "res": false,
		"testo": "+4 al tiro di negoziazione."},
	"cw": {"nome": "Intimorire", "orig": "Cow", "costo": 2, "tipo": "N", "res": true,
		"testo": "Il mostro è intimidito senza tirare, se non resiste."},
	"dn": {"nome": "Soggiogare", "orig": "Daunt", "costo": 3, "tipo": "N", "res": true,
		"testo": "Come Intimorire, ma il mostro consegna tutto il tesoro."},
	"sw": {"nome": "Persuasione", "orig": "Sway", "costo": 1, "tipo": "B", "res": false,
		"testo": "-2 al tiro sulla Tabella della Corruzione."},
	"cj": {"nome": "Lusinga", "orig": "Cajole", "costo": 2, "tipo": "B", "res": false,
		"testo": "-4 al tiro sulla Tabella della Corruzione."},
	"wg": {"nome": "Ira di Dio", "orig": "Wrath of God", "costo": 3, "tipo": "S", "res": true,
		"testo": "Speciale, di combattimento: 2D6+2 ferite a un mostro, se non resiste. Si impara da Malthus o dal Manoscritto."},
	"rs": {"nome": "Resurrezione", "orig": "Resurrect", "costo": 5, "tipo": "S", "res": false,
		"testo": "Speciale: subito dopo il combattimento riporta in vita un caduto. Si impara dalla Libreria o con un anello."},
}
const INCANTESIMI_ORDINE := ["cm", "bl", "ex", "lt", "sl", "rd", "ms", "hs", "cf", "ma", "lk", "mr", "np", "sf", "st", "he", "rj", "tl", "tf", "or", "cw", "dn", "sw", "cj"]
const TIPI_INCANTESIMO := {"C": "Combattimento", "NC": "Fuori combattimento", "N": "Negoziazione", "B": "Corruzione", "S": "Speciale"}

# --- Mostri (8.2) ---------------------------------------------------------------------------
# bc: bonus di combattimento; dadi/agg: punti ferita = dadi D6 + agg (dadi 0.5 = 1D3)
const MOSTRI := {
	"chimera":   {"nome": "Chimera", "plur": "Chimere", "vr": 2, "vn": 7, "arma": "", "inc": "", "tesoro": "I", "spec": "Soffio di fuoco", "bc": 7, "dadi": 2, "agg": 2},
	"cronk":     {"nome": "Cronk", "plur": "Cronk", "vr": 1, "vn": 9, "arma": "", "inc": "", "tesoro": "E/B", "spec": "Fetore", "bc": 4, "dadi": 1, "agg": 1},
	"demone":    {"nome": "Demone", "plur": "Demoni", "vr": 4, "vn": -1, "arma": "", "inc": "", "tesoro": "D", "spec": "Guardiano della Porta", "bc": 5, "dadi": 1, "agg": 2},
	"lupo":      {"nome": "Lupo Crudele", "plur": "Lupi Crudeli", "vr": 1, "vn": 9, "arma": "", "inc": "", "tesoro": "A", "spec": "", "bc": 1, "dadi": 0.5, "agg": 1},
	"eroe_m":    {"nome": "Eroe Malvagio", "plur": "Eroi Malvagi", "vr": 2, "vn": 5, "arma": "spada", "arma_magica": true, "inc": "", "tesoro": "J/C", "spec": "Spada +1D6", "bc": 5, "dadi": 1, "agg": 4},
	"mago_m":    {"nome": "Mago Malvagio", "plur": "Maghi Malvagi", "vr": 3, "vn": 3, "arma": "pugnale", "inc": "lt", "tesoro": "J/C", "spec": "Fulmine", "bc": 4, "dadi": 1, "agg": 3},
	"gargoyle":  {"nome": "Gargoyle", "plur": "Gargoyle", "vr": 3, "vn": 4, "arma": "", "inc": "", "tesoro": "G", "spec": "", "bc": 9, "dadi": 3, "agg": 1},
	"arpia":     {"nome": "Arpia", "plur": "Arpie", "vr": 1, "vn": 5, "arma": "", "inc": "", "tesoro": "A", "spec": "", "bc": 0, "dadi": 0.5, "agg": 0},
	"idra":      {"nome": "Idra", "plur": "Idre", "vr": 3, "vn": 7, "arma": "", "inc": "", "tesoro": "J", "spec": "Ogni ferita +1 BC", "bc": 0, "dadi": 2, "agg": 3},
	"medusa":    {"nome": "Medusa", "plur": "Meduse", "vr": 2, "vn": 5, "arma": "", "inc": "", "tesoro": "G", "spec": "Pietrifica", "bc": 2, "dadi": 2, "agg": 0},
	"minotauro": {"nome": "Minotauro", "plur": "Minotauri", "vr": 3, "vn": 7, "arma": "", "inc": "", "tesoro": "J/C", "spec": "", "bc": 10, "dadi": 2, "agg": 4},
	"ogre":      {"nome": "Ogre", "plur": "Ogre", "vr": 2, "vn": 2, "arma": "martello", "inc": "", "tesoro": "J/E", "spec": "", "bc": 5, "dadi": 1, "agg": 2},
	"orco":      {"nome": "Orco", "plur": "Orchi", "vr": 1, "vn": 0, "arma": "spada", "inc": "", "tesoro": "H/B", "spec": "", "bc": 3, "dadi": 1, "agg": 0},
	"scheletro": {"nome": "Scheletro", "plur": "Scheletri", "vr": 1, "vn": 9, "arma": "", "inc": "", "tesoro": "F/A", "spec": "", "bc": 2, "dadi": 1, "agg": 1},
	"troll":     {"nome": "Troll", "plur": "Troll", "vr": 3, "vn": 4, "arma": "", "inc": "", "tesoro": "J", "spec": "Rigenera", "bc": 6, "dadi": 2, "agg": 3},
	"vampiro":   {"nome": "Vampiro", "plur": "Vampiri", "vr": 4, "vn": 6, "arma": "", "inc": "", "tesoro": "J", "spec": "Incanta", "bc": 11, "dadi": 3, "agg": 0},
	"warg":      {"nome": "Warg", "plur": "Warg", "vr": 1, "vn": 6, "arma": "", "inc": "", "tesoro": "A", "spec": "", "bc": 3, "dadi": 0.5, "agg": 2},
	"wight":     {"nome": "Spettro", "plur": "Spettri", "vr": 2, "vn": 4, "arma": "", "inc": "", "tesoro": "H", "spec": "", "bc": 6, "dadi": 2, "agg": 0},
	"wraith":    {"nome": "Ombra", "plur": "Ombre", "vr": 1, "vn": 2, "arma": "", "inc": "", "tesoro": "I/D", "spec": "", "bc": 3, "dadi": 1, "agg": 3},
	"x":         {"nome": "X lo Sconosciuto", "plur": "X lo Sconosciuto", "vr": 4, "vn": -1, "arma": "spada", "inc": "lt", "tesoro": "L", "spec": "Signore della Cittadella", "bc": 5, "dadi": 1, "agg": 6},
}

# --- Tabelle dei Mostri (8.3) ---------------------------------------------------------------
# [tipo, numero] dove numero è "1", "2", "1D3", "1D6", "1D3+2", "1D6+1", "1D6+2"
const MOSTRI_STANZA := [
	[["mago_m", "1"], ["eroe_m", "1"], ["cronk", "1D6"], ["gargoyle", "1"], ["chimera", "1"], ["medusa", "1"]],
	[["orco", "1D3"], ["troll", "1"], ["vampiro", "1"], ["arpia", "1D3+2"], ["ogre", "1"], ["minotauro", "1"]],
	[["lupo", "1D6"], ["wight", "1"], ["warg", "1D3"], ["mago_m", "1"], ["eroe_m", "1"], ["cronk", "1D6+1"]],
	[["gargoyle", "2"], ["chimera", "2"], ["medusa", "1"], ["orco", "1D6+1"], ["idra", "1"], ["vampiro", "1"]],
	[["arpia", "1D6+2"], ["ogre", "2"], ["minotauro", "1"], ["lupo", "1D6"], ["wight", "2"], ["warg", "1D6"]],
	[["scheletro", "1D3"], ["wraith", "1D3"], ["scheletro", "1D6"], ["wraith", "1D3+2"], ["troll", "1"], ["idra", "1"]],
]
# seconda colonna: 1-2, 3-4, 5-6
const MOSTRI_ERRANTI := [
	[["eroe_m", "1"], ["mago_m", "1"], ["chimera", "1"]],
	[["gargoyle", "1"], ["medusa", "1"], ["orco", "1D3"]],
	[["troll", "1"], ["vampiro", "1"], ["arpia", "1D3+2"]],
	[["ogre", "1"], ["minotauro", "1"], ["lupo", "1D6"]],
	[["wight", "1"], ["warg", "1D3"], ["wraith", "1D3"]],
	[["idra", "1"], ["scheletro", "1D3"], ["cronk", "1D6"]],
]

# --- Tabella dei Livelli (6.7) --------------------------------------------------------------
const LIVELLI := {
	"ferite": [0, 2, 4],
	"bc": [0, 1, 3],
	"vn": [0, 1, 2],
	"numero": [1, 1, 2],
	"tesoro": [0, 1, 2],
	"xp": [1, 1, 2],
}

# --- Trappole (7.1) -------------------------------------------------------------------------
const TRAPPOLE := ["freccia", "freccia_avvelenata", "gas", "esplosione", "olio", "doppia"]
const NOMI_TRAPPOLE := {
	"freccia": "Freccia", "freccia_avvelenata": "Freccia avvelenata", "gas": "Gas velenoso",
	"esplosione": "Esplosione", "olio": "Olio bollente", "doppia": "Tira due volte",
}

# --- Negoziazione (8.5) e Corruzione (8.9) --------------------------------------------------
static func esito_negoziazione(totale: int) -> String:
	if totale <= 6: return "fallimento"
	if totale <= 9: return "accordo"
	return "intimidazione"

const CORRUZIONE_OFFERTE := [20, 40, 60, 80, 100, 150, 200, 300, 400]
const CORRUZIONE_COLONNE := ["1-5", "6-9", "10-12", "13-16", "17-20", "21+"]
const CORRUZIONE := [
	[4, 2, 1, 1, 0, 0],
	[4, 3, 2, 1, 1, 0],
	[5, 4, 2, 2, 1, 1],
	[6, 5, 4, 2, 2, 1],
	[6, 6, 4, 3, 2, 1],
	[6, 6, 5, 4, 3, 2],
	[6, 6, 6, 4, 4, 2],
	[6, 6, 6, 5, 4, 3],
	[6, 6, 6, 5, 5, 4],
]
static func colonna_corruzione(v: int) -> int:
	if v <= 5: return 0
	if v <= 9: return 1
	if v <= 12: return 2
	if v <= 16: return 3
	if v <= 20: return 4
	return 5

# --- Elementi delle stanze (13.9) -----------------------------------------------------------
const ELEMENTI := {
	"fontana": "Fontana", "statua": "Statua", "botola": "Botola", "mobili": "Mobili",
	"altare": "Altare", "opera": "Opera d'arte", "specchio": "Specchio", "scala": "Scala",
}
const TABELLA_ELEMENTI := {
	"fontana": ["veleno", "pozione", "alcol", "gioiello", "acqua", "sangue"],
	"statua": ["medusa", "gioielli", "medaglione", "demone", "talismano", "x"],
	"botola": ["trappola", "trappola", "stanza", "stanza", "fossa", "hellgate"],
	"mobili": ["bara", "libreria", "scrittoio", "letto", "clavicembalo", "specchio"],
	"altare": ["alloces", "vassago", "avnas", "malthus", "leraje", "asmoday"],
	"opera": ["arazzo", "dipinto", "statua", "vetro", "icona", "manoscritto"],
}
const NOMI_RISULTATI := {
	"veleno": "Veleno", "pozione": "Pozione", "alcol": "Alcol", "gioiello": "Gioiello", "acqua": "Acqua", "sangue": "Sangue",
	"medusa": "Medusa", "gioielli": "Gioielli", "medaglione": "Medaglione", "demone": "Demone", "talismano": "Talismano", "x": "X lo Sconosciuto",
	"trappola": "Trappola", "stanza": "Stanza segreta", "fossa": "Fossa", "hellgate": "Porta dell'Inferno",
	"bara": "Bara", "libreria": "Libreria", "scrittoio": "Scrittoio", "letto": "Letto", "clavicembalo": "Clavicembalo", "specchio": "Specchio",
	"alloces": "Alloces, il Duca Guerriero", "vassago": "Vassago, il Principe della Profezia", "avnas": "Avnas, il Presidente del Fuoco",
	"malthus": "Malthus, il Conte della Morte e del Caos", "leraje": "Leraje, il Marchese degli Arcieri", "asmoday": "Asmoday, il Re Infernale",
	"arazzo": "Arazzo", "dipinto": "Dipinto", "statua": "Statua", "vetro": "Vetro intagliato", "icona": "Icona", "manoscritto": "Manoscritto",
}
# Specchio (13.9): [livello, segmenti]
const SPECCHIO := [[1, 3], [2, 4], [2, 5], [3, 6], [3, 7], [3, 8]]

# --- Tesori (14.9) --------------------------------------------------------------------------
# per tipo: [oro, gioielli, oggetti] ciascuno [soglia, dadi, facce, moltiplicatore, aggiunta]
const TESORI := {
	"A": [[0, 0, 6, 1], [0, 0, 6, 1], [0, 0, 6, 1]],
	"B": [[6, 1, 6, 1], [0, 0, 6, 1], [0, 0, 6, 1]],
	"C": [[6, 3, 6, 1], [0, 0, 6, 1], [1, 1, 0, 1]],
	"D": [[1, 3, 6, 1], [1, 1, 3, 1], [0, 0, 6, 1]],
	"E": [[2, 1, 6, 10], [2, 1, 6, 1], [2, 1, 0, 1]],
	"F": [[3, 1, 6, 5], [3, 1, 3, 1], [1, 1, 0, 1]],
	"G": [[6, 3, 6, 5], [3, 1, 6, 1], [2, 1, 0, 1]],
	"H": [[6, 2, 6, 1], [1, 1, 3, 1], [1, 1, 0, 1]],
	"I": [[6, 1, 6, 5], [2, 1, 6, 1], [2, 1, 0, 1]],
	"J": [[6, 1, 6, 20], [2, 1, 6, 1], [3, 1, 3, 1]],
	"K": [[6, 2, 6, 20], [3, 1, 6, 1], [3, 1, 3, 1]],
	"L": [[6, 3, 6, 20], [4, 1, 6, 1], [4, 1, 3, 1]],
}
# testo originale del codice, per mostrarlo nelle tabelle
const TESORI_TESTO := {
	"A": ["0:0", "0:0", "0:0"], "B": ["6:1D6", "0:0", "0:0"], "C": ["6:3D6", "0:0", "1:1"],
	"D": ["1:3D6", "1:1D3", "0:0"], "E": ["2:1D6×10", "2:1D6", "2:1"], "F": ["3:1D6×5", "3:1D3", "1:1"],
	"G": ["6:3D6×5", "3:1D6", "2:1"], "H": ["6:2D6", "1:1D3", "1:1"], "I": ["6:1D6×5", "2:1D6", "2:1"],
	"J": ["6:1D6×20", "2:1D6", "3:1D3"], "K": ["6:2D6×20", "3:1D6", "3:1D3"], "L": ["6:3D6×20", "4:1D6", "4:1D3"],
}
const GIOIELLI := {2: 1, 3: 5, 4: 10, 5: 15, 6: 20, 7: 25, 8: 35, 9: 50, 10: 75, 11: 100, 12: 150}
const OGGETTI_TIPI := ["arma", "armatura", "pozione", "talismano", "medaglione", "anello"]
const NOMI_OGGETTI_TIPI := {"arma": "Arma magica", "armatura": "Armatura magica", "pozione": "Pozione", "talismano": "Talismano", "medaglione": "Medaglione", "anello": "Anello"}
const OGGETTI := {
	"arma": ["spada", "martello", "ascia", "arco", "pugnale", "pugnale_lancio"],
	"armatura": [1, 1, 1, 2, 2, 0],
	"pozione": ["veleno", "forza", "forza", "fascino_persone", "fascino_mostri", "guarigione"],
	"talismano": ["mente", "sole_giallo", "sole_blu", "sole_rosso", "tutti_i_soli", "male"],
	"medaglione": ["neutralizza", "stima_pozioni", "oratoria", "destrezza", "neutralizza", "strangolamento"],
	"anello": ["resistenza1", "resistenza2", "sonno", "neutralizza", "guarigione", "resurrezione"],
}
const BONUS_ARMA := [1, 2, 2, 3, 3, 0]   # 0 = tira due volte
const NOMI_POZIONI := {"veleno": "Pozione: Veleno", "forza": "Pozione della Forza", "fascino_persone": "Pozione di Fascino sulle Persone", "fascino_mostri": "Pozione di Fascino sui Mostri", "guarigione": "Pozione di Guarigione"}
const NOMI_TALISMANI := {"mente": "Talismano della Mente", "sole_giallo": "Talismano del Sole giallo", "sole_blu": "Talismano del Sole blu", "sole_rosso": "Talismano del Sole rosso", "tutti_i_soli": "Talismano di Tutti i Soli", "male": "Talismano del Male"}
const NOMI_MEDAGLIONI := {"neutralizza": "Medaglione Neutralizza Veleno", "stima_pozioni": "Medaglione della Stima delle Pozioni", "oratoria": "Medaglione dell'Oratoria", "destrezza": "Medaglione della Destrezza", "strangolamento": "Medaglione Strangolatore"}
const NOMI_ANELLI := {"resistenza1": "Anello di Resistenza +1", "resistenza2": "Anello di Resistenza +2", "sonno": "Anello del Sonno", "neutralizza": "Anello Neutralizza Veleno", "guarigione": "Anello di Guarigione", "resurrezione": "Anello di Resurrezione"}

static func lettera_tesoro(lettera: String, spostamento: int) -> String:
	var lettere := "ABCDEFGHIJKL"
	var i := lettere.find(lettera)
	if i < 0: return lettera
	return lettere[min(i + spostamento, lettere.length() - 1)]

# --- Varie -----------------------------------------------------------------------------------
const DIREZIONI := ["N", "E", "S", "O"]
const VETTORI := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

static func nome_arma(a: String) -> String:
	return ARMI.get(a, a)
