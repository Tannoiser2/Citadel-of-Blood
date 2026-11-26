extends RefCounted
class_name Tutorial
## Tutorial a turni guidati: una vera partita con dadi e tessere preparati, che spiega ogni regola
## nel momento in cui serve. Il giocatore può premere solo l'azione indicata (evidenziata in oro).

var motore: Motore
var passi: Array = []
var indice := 0
var finito := false
var _avviso := 0.0

const CONFIG := {
	"seme": 2024, "tutorial": true,
	"eroi": ["almuric", "gislan", "dalmilandril"],
	"iniziati": [
		{"nome": "Borin", "razza": "nano", "femmina": false, "arma2": "pugnale", "esperienza": "arma", "tiro_pm": 1},
		{"nome": "Lithiel", "razza": "elfo", "femmina": true, "arma2": "pugnale", "esperienza": "pf", "tiro_pm": 6},
		{"nome": "Corrado", "razza": "umano", "femmina": false, "arma2": "pugnale_lancio", "esperienza": "abilita", "tiro_pm": 1}],
	"incantesimi": {
		"almuric": ["bl", "or"], "gislan": ["bl", "he", "lt", "or"], "dalmilandril": ["bl", "lt", "he", "sl", "cm"], "ini2": ["bl", "sl"]},
}

func avvia(m: Motore) -> void:
	motore = m
	_prepara_passi()
	indice = 0
	# dadi della preparazione: sole giallo, usi di Guarigione di Gislan e Dalmilandril
	motore.dadi_forzati = [3, 3, 4]
	motore.nuova_partita(CONFIG)

func passo() -> Dictionary:
	if indice >= passi.size(): return {}
	return passi[indice]

func consenti(id: String) -> bool:
	if finito: return true
	var p = passo()
	if p.is_empty(): return true
	if p.get("attendi", "") == "": return false
	if id != p["attendi"]: return false
	motore.dadi_forzati = p.get("dadi", []).duplicate()
	motore.tessere_forzate = p.get("tessere", []).duplicate()
	indice += 1
	return true

func blocca_tocchi() -> bool:
	return false

func avvisa(main) -> void:
	_avviso = 2.0
	dopo_aggiornamento(main)

func avanti(main) -> void:
	indice += 1
	if indice >= passi.size():
		_concludi(main)
		return
	dopo_aggiornamento(main)

## Solo per i test automatici: avanza oltre i passi informativi
func prova_avanti(main) -> void:
	if passo().get("attendi", "x") == "":
		avanti(main)

func _concludi(main) -> void:
	finito = true
	main.pan_tutorial.visible = false
	main.tutorial = null
	main.aggiorna()

func dopo_aggiornamento(main) -> void:
	var p = passo()
	var pan: PanelContainer = main.pan_tutorial
	Widget.svuota(pan)
	if p.is_empty():
		pan.visible = false
		return
	# se l'azione attesa non c'è (la partita ha preso un'altra strada) si continua liberamente
	var att: String = p.get("attendi", "")
	if att != "":
		var trovata = false
		for o in motore.s.get("scelta", {}).get("opzioni", []):
			if o["id"] == att: trovata = true
		if not trovata:
			finito = true
			pan.visible = false
			main.tutorial = null
			return
	pan.visible = true
	var v = VBoxContainer.new()
	pan.add_child(v)
	var h = HBoxContainer.new()
	v.add_child(h)
	var t = Widget.titolo("Tutorial · %d di %d" % [indice + 1, passi.size()], 22)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(t)
	var esci = Widget.bottone("Esci dal tutorial", func(): _concludi(main), 14)
	esci.size_flags_horizontal = Control.SIZE_SHRINK_END
	esci.custom_minimum_size.x = 150
	h.add_child(esci)
	var testo: String = p["testo"]
	if _avviso > 0:
		testo = "[color=#ffb070][b]Nel tutorial premi l'azione evidenziata in oro.[/b][/color]\n" + testo
		_avviso = 0.0
	var r = Widget.testo_ricco(testo, 16 if not main._compatto else 14)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(r)
	v.add_child(sc)
	if att == "":
		var b = Widget.bottone("Avanti", func(): avanti(main), 17)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.custom_minimum_size.x = 160
		v.add_child(b)
	else:
		_evidenzia(main, att)
	main._layout()

func _evidenzia(main, att: String) -> void:
	var azione_attesa = ""
	for o in motore.s.get("scelta", {}).get("opzioni", []):
		if o["id"] == att: azione_attesa = o.get("azione", "")
	for b in main.box_azioni.get_children():
		if not b is Button: continue
		var id_b: String = b.get_meta("id_opzione", "")
		var az_b: String = b.get_meta("azione", "")
		if id_b == att or (id_b == "" and az_b != "" and az_b == azione_attesa):
			b.add_theme_stylebox_override("normal", Risorse.box(Color(0.55, 0.38, 0.05), Color(1, 0.88, 0.45), 4, 6, 12))
			b.add_theme_stylebox_override("hover", Risorse.box(Color(0.65, 0.45, 0.08), Color(1, 0.95, 0.6), 4, 6, 12))
		elif id_b != "" or az_b != "":
			b.modulate = Color(1, 1, 1, 0.45)

# --------------------------------------------------------------------------------------------
func _prepara_passi() -> void:
	passi = [
		{"testo": "[b]Benvenuto nella Cittadella di Sangue![/b]\nX lo Sconosciuto, il più potente mago del mondo, possiede la [b]Porta dell'Inferno[/b], un congegno capace di scatenare i demoni sull'Impero. Il tuo gruppo di avventurieri deve [b]trovarla, distruggerla e uscire vivo[/b] dalla Cittadella.\nNon c'è una mappa: il labirinto si costruisce un pezzo alla volta pescando tessere di stanze e corridoi. Questo tutorial è una partita vera, con dadi preparati, che ti spiega ogni regola quando serve."},
		{"testo": "[b]Il gruppo (4.1).[/b] In solitario guidi [b]tre Eroi[/b] pescati a caso fra i 23 della Lega e [b]tre Iniziati[/b] creati da te. Qui hai Almuric (guerriero), Gislan (nano guerriero e mago, ottimo a disinnescare) e Dalmilandril (elfo arciere e mago), con gli iniziati Borin, Lithiel e Corrado.\nA sinistra c'è una scheda per ciascuno: [b]PF[/b] sono i Punti Ferita, [b]BC[/b] il Bonus di Combattimento che si somma ai tiri d'attacco. Tocca una scheda in qualsiasi momento per vedere tutto il personaggio: Resistenza, armi, abilità, incantesimi e tesori."},
		{"testo": "[b]L'ordine di marcia (4.1 C).[/b] Il gruppo si muove come un'unica pedina, ma i personaggi sono disposti in [b]file di tre[/b]: la prima fila combatte in mischia, la seconda tira con l'arco, lancia pugnali e incantesimi, la terza non può fare nulla. La prima fila deve avere almeno due personaggi. Lo vedi in 3D attorno alla pedina del gruppo, e puoi cambiarlo con il pulsante [b]Ordine[/b] finché non comincia un combattimento.\n[b]La vista 3D:[/b] trascina per spostarti, rotella o pizzico per lo zoom, tasto destro o due dita per ruotare. [b]Centra[/b] riporta la vista sul gruppo."},
		{"testo": "[b]I tre soli (4.1 D).[/b] Sopra la valle brillano tre soli: a ogni ingresso nella Cittadella un dado stabilisce quello dominante. È uscito 3: [b]sole giallo[/b]. Ogni mago ha un Potenziale Magico per ciascun sole (per esempio 3/4/5) e sotto il sole dominante può usare solo quel numero dei suoi incantesimi.\nDalmilandril ne conosce 5 ma sotto il sole giallo ne può usare 4; Almuric 1 su 2. A destra trovi le caselle già spuntate con una buona scelta: premi [b]Conferma ed entra[/b].", "attendi": "ok", "dadi": []},
		{"testo": "[b]Primo turno (5.0 A).[/b] Ogni turno il gruppo si sposta di un segmento. Davanti al Portale del Male scegli se entrare da una porta (si pescherà una [b]stanza[/b]) o da un corridoio (si pescherà un [b]corridoio[/b]): ogni tessera ha una stanza da un lato e un corridoio dall'altro.\nScegli [b]Entra nella Cittadella da un corridoio[/b].", "attendi": "esp|0|C", "dadi": [4], "tessere": [0]},
		{"testo": "[b]Un corridoio.[/b] La tessera è stata pescata e piazzata in modo che il suo corridoio combaci con l'ingresso: porte con porte, corridoi con corridoi, muri con muri (6.1).\nEntrando in un segmento si controllano i mostri (5.0 C): in un corridoio o in una stanza già visitata arrivano [b]mostri erranti[/b] solo con un 1; in una stanza mai vista ci sono mostri con 1, 2 o 3. È uscito 4: nessun mostro. Il diario in alto a destra racconta ogni tiro.\nProsegui a nord: [b]Esplora a nord (corridoio)[/b]. Puoi anche toccare la freccia dorata sul pavimento.", "attendi": "esp|0|C", "dadi": [], "tessere": [20]},
		{"testo": "[b]Orientare la tessera (6.2).[/b] Il nuovo corridoio combacia in due modi: con una porta a ovest o con una porta a est. Quando ci sono più possibilità decide il gruppo; passando sopra le opzioni vedi l'anteprima in 3D.\nScegli quella con la [b]porta a est[/b].", "attendi": "rot|3", "dadi": [5]},
		{"testo": "[b]Una porta![/b] Uscendo da una porta si pesca il lato stanza della tessera. Attenzione però (5.0 B): la prima volta che si entra in una stanza [b]la porta può avere una trappola[/b] (con 1 su un dado).\nEntra: [b]Esplora a est (porta)[/b].", "attendi": "esp|1|D", "dadi": [1], "tessere": [21]},
		{"testo": "[b]Trappola! (7.0)[/b] È uscito 1. Un personaggio con l'abilità di [b]Disinnesco[/b] tira un dado: se fa meno o uguale alla sua abilità, la trappola è disinnescata. Chi non sa disinnescare la fa scattare di sicuro e si tira sulla Tabella delle Trappole: frecce, veleni, esplosioni.\nGislan ha Disinnesco 3: fallo controllare a lui.", "attendi": "tr|gislan|", "dadi": [2, 2, 2, 1, 5, 3, 2, 4]},
		{"testo": "[b]Orchi! (8.0)[/b] Gislan ha disinnescato (2 su 3). Poi il controllo dei mostri ha dato 2: la stanza è abitata. Sulla Tabella dei Mostri della Stanza i dadi 2 e 1 danno [b]Orchi: 1D3[/b], e ne sono arrivati 3. Ogni mostro ha i suoi Punti Ferita tirati sulla pedina (gli Orchi: 1D6).\nPrima di combattere puoi [b]negoziare[/b]: si tirano 2D6, si toglie il Valore di Negoziazione del mostro (Orchi: 0) e si aggiunge l'abilità di chi tratta. Con 7-9 c'è un Accordo, con 10 o più i mostri sono intimiditi e cedono parte dell'oro.\nFai negoziare [b]Dalmilandril[/b] (+2).", "attendi": "neg|dalmilandril", "dadi": [2, 1]},
		{"testo": "[b]Negoziazione fallita.[/b] 2+1−0+2 = 5: con 6 o meno è un fallimento. Con dell'oro si potrebbe tentare la [b]corruzione[/b] (8.7), ma il gruppo è povero. Non resta che combattere.\nIn tavola vedi i mostri in alto e il tuo ordine di marcia in basso, come le file 1-2-3 e A-B-C del regolamento. Premi [b]Combatti![/b]", "attendi": "comb", "dadi": []},
		{"testo": "[b]Il combattimento (9.0).[/b] Ogni round ha cinque fasi: [b]gruppo[/b], [b]mostri[/b], [b]Porta[/b] (solo davanti alla Porta dell'Inferno), [b]riorganizzazione del gruppo[/b], [b]riorganizzazione dei mostri[/b]. Si combatte finché una parte è eliminata.\n[b]Bersagli (9.3):[/b] chi è in prima fila attacca il nemico che ha di fronte; se nessuno gli sta davanti, il più vicino. Gislan ha di fronte l'Orco più forte.\n[b]Attacco (9.5):[/b] si tira un dado, si somma l'abilità con l'arma e il Bonus di Combattimento e si legge la colonna dell'arma nella Tabella del Combattimento. Gislan: 5 + 2 (ascia) + 4 (bonus) = 11, che con l'ascia fa 2 ferite. Attacca!", "attendi": "att|m:3", "dadi": [5]},
		{"testo": "[b]Almuric[/b] (prima fila, al centro) attacca l'Orco davanti a lui con la spada: 4 + 2 + 3 = 9, nella colonna Spada vale 1 ferita.", "attendi": "att|m:1", "dadi": [4]},
		{"testo": "[b]Borin[/b] chiude la prima fila con l'ascia: 6 + 2 + 0 = 8 → 1 ferita.", "attendi": "att|m:2", "dadi": [6]},
		{"testo": "[b]La seconda fila.[/b] Da qui non si combatte in mischia: si tira con l'[b]arco[/b], si lancia il [b]pugnale da lancio[/b] (una volta per combattimento) o si lanciano [b]incantesimi[/b]. Corrado ha in mano la spada, inutile in seconda fila. Cambiare arma costa l'attacco di questa fase (9.4): fagli impugnare il [b]pugnale da lancio[/b], potrà lanciarlo dal prossimo round.", "attendi": "cambia", "dadi": []},
		{"testo": "[b]Dalmilandril[/b] ha l'arco: dalla seconda fila può colpire qualsiasi mostro della prima fila nemica. L'Orco di destra ha solo 1 Punto Ferita: premi [b]Scocca una freccia[/b] e poi tocca quell'Orco sulla tavola (riquadro dorato) o il suo nome nell'elenco.", "attendi": "arc|m:2", "dadi": [5]},
		{"testo": "[b]La magia (10.0).[/b] Gli incantesimi costano [b]Punti Ferita[/b] a chi li lancia e i bersagli possono [b]resistere[/b]: tirano un dado e se fanno meno o uguale alla loro Resistenza l'incantesimo non ha effetto (11.0). Gli Orchi hanno Resistenza 1.\nLithiel lancia [b]Scarica[/b] (1 PF: 2 ferite a un mostro della prima fila) sull'Orco ferito al centro.", "attendi": "inc|bl|m:1", "dadi": [4, 1, 3]},
		{"testo": "[b]La fase dei mostri.[/b] Due Orchi sono morti. L'ultimo Orco aveva di fronte Gislan, ma anche Almuric e Borin erano senza avversario: i mostri scelgono a caso fra i bersagli alla stessa distanza (9.3). Il dado ha scelto Gislan, ferito di 1.\n[b]Riorganizzazione (9.8):[/b] ora puoi spostare un personaggio di un posto (tocca un personaggio e poi un posto libero). Non serve: premi [b]Nessuno spostamento[/b].", "attendi": "prosegui", "dadi": []},
		{"testo": "[b]Secondo round.[/b] Gislan può finire l'ultimo Orco.", "attendi": "att|m:3", "dadi": [4, 1, 3, 4, 1, 2, 2, 5, 4, 2, 2, 2, 3, 1, 3, 6, 5, 6, 6, 6, 6]},
		{"testo": "[b]Vittoria![/b] [b]Esperienza (12.0):[/b] si sommano i Punti Ferita iniziali dei mostri (9), si moltiplicano per 6 e si dividono fra i sopravvissuti: 9 punti a testa.\n[b]Tesori (14.0):[/b] ogni mostro ha una lettera di tesoro (gli Orchi della stanza: H). Si sono trovati marchi d'oro, un gioiello e una [b]pozione misteriosa[/b]. Oro e gioielli si dividono da soli; per gli oggetti scegli tu chi li prende. Le pozioni vanno [b]provate[/b] (14.5): chi la beve ne subisce subito l'effetto e ne conserva una dose. Dalla a [b]Gislan[/b], che è ferito.", "attendi": "a|gislan", "dadi": [3]},
		{"testo": "[b]Era una Pozione di Guarigione![/b] Gislan è guarito e ne conserva una dose (la trovi nella sua scheda: fuori dal combattimento puoi berla quando vuoi).\n[b]Gli elementi delle stanze (13.0).[/b] Questa stanza ha una [b]fontana di bronzo[/b] con tre iene. Un personaggio può indagare e tirare sulla Tabella degli Elementi: può trovare veleno, pozioni, alcol, gioielli, acqua o sangue. Rischioso ma spesso redditizio. Fai indagare [b]Corrado[/b].", "attendi": "ind|ini3", "dadi": [4, 6, 6]},
		{"testo": "[b]Un gioiello da 150 marchi![/b] Ricchezza ed esperienza servono alla [b]vittoria personale[/b] (17.0): chi esce vivo con almeno 100 punti esperienza e 100 marchi è un vincitore, e vince chi ne ha di più. Tra una spedizione e l'altra si possono spendere 100 punti e 100 marchi per migliorare il personaggio (12.2).\nAltri elementi: [b]statue[/b], [b]botole[/b], [b]mobili magici[/b], [b]altari[/b] dei sei demoni, [b]opere d'arte[/b] e soprattutto gli [b]specchi[/b] (13.7): il primo specchio rivela il livello della Porta dell'Inferno, un secondo specchio su quel livello rivela quanti segmenti nuovi mancano. Premi [b]Prosegui[/b].", "attendi": "ok", "dadi": []},
		{"testo": "[b]Una stanza senza altre uscite.[/b] Prima di trovare la Porta il labirinto non può chiudersi in un vicolo cieco (6.4), ma una singola stanza sì. Torna indietro: [b]Vai a ovest[/b]. Nei segmenti già esplorati non si pescano tessere, ma possono arrivare [b]mostri erranti[/b].", "attendi": "vai|3", "dadi": [1, 2, 5, 1, 4]},
		{"testo": "[b]Un Orco errante![/b] Il controllo dei mostri erranti ha dato 1 e la Tabella dei Mostri Erranti un Orco.\n[b]Incantesimi di negoziazione (10.7):[/b] prima di tirare si possono lanciare [b]Oratoria[/b] (+4 alla negoziazione), [b]Intimorire[/b] o [b]Soggiogare[/b]; durante la corruzione [b]Persuasione[/b] e [b]Lusinga[/b]. Fai lanciare a [b]Gislan[/b] l'Oratoria (1 PF).", "attendi": "incn|gislan|or", "dadi": []},
		{"testo": "Ora fai negoziare [b]Gislan[/b]: avrà +4 grazie all'Oratoria.", "attendi": "neg|gislan", "dadi": [5, 4, 3, 4]},
		{"testo": "[b]Intimidazione![/b] 5+4−0+4 = 13: l'Orco cede un quarto del suo oro e lascia in pace il gruppo. Potresti attaccarlo comunque per prendere tutto il suo tesoro, ma un'intesa risparmia ferite. Chi viene lasciato in pace [b]resta sulla mappa[/b] (6.9): se torni qui lo ritroverai, come un mostro nuovo.\nPremi [b]Lasciali in pace e prosegui[/b].", "attendi": "lascia", "dadi": []},
		{"testo": "[b]Le altre regole che incontrerai.[/b]\n[b]Scale (6.5-6.6):[/b] alcune stanze hanno una scala che porta al livello 2 o al 3. Più in basso i mostri sono più forti, più numerosi e con tesori migliori (Tabella dei Livelli).\n[b]Incantesimi fuori combattimento:[/b] Guarigione e Rigenerazione (usi limitati a 1D6 per spedizione), Armatura magica, Forza: toccando la scheda di un personaggio vedi cosa può fare. [b]Esitazione[/b] permette di curarsi prima di uno scontro.\n[b]Mostri speciali (15.0):[/b] il fetore dei Cronk, il soffio della Chimera, lo sguardo pietrificante della Medusa, il Troll che rigenera, il Vampiro che incanta, l'Idra che si infuria a ogni ferita, i maghi che scagliano fulmini."},
		{"testo": "[b]La Porta dell'Inferno (16.0).[/b] La difendono X lo Sconosciuto e da 3 a 5 demoni, che non trattano. Ogni round la Porta scaglia tre Scariche finché X è vivo. Ucciso X, i demoni svaniscono e un personaggio con l'abilità contro la Porta tira un dado: se fa meno o uguale alla sua abilità, la Porta è distrutta; altrimenti subisce una ferita e può ritentare.\n[b]Vittoria (17.0):[/b] distrutta la Porta, torna al livello 1 e al Portale del Male ed esci vivo. Se il gruppo è troppo malconcio puoi uscire prima, curarti, migliorare i personaggi e rientrare (campagna): il labirinto resta com'è.\nI pulsanti [b]Regole[/b] e [b]Tabelle[/b] in alto contengono il regolamento completo in italiano e tutte le tabelle. Buona fortuna: la partita ora continua liberamente!"},
	]
