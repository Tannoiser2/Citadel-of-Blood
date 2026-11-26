extends RefCounted
class_name Regolamento
## Il regolamento di Citadel of Blood (ARES n. 5, novembre 1980) tradotto in italiano,
## con la stessa numerazione dei paragrafi, e le tabelle impaginate come quelle originali.

const D = preload("res://scripts/dati.gd")

const SEZIONI := [
["1.0", "Introduzione", """Nella Valle della Grande Spada sorge una fortezza imponente: è il rifugio del più potente Mago del mondo, X lo Sconosciuto. Con l'aiuto di un esercito di Orchi ha trasformato delle rovine nella più forte delle fortezze. Al sicuro nella Cittadella, il Mago ha tradito i Popoli Liberi della valle consegnandoli all'Impero durante la Terza Guerra della Lega di Ararlve, e da allora il suo potere è cresciuto. Ora possiede l'antica e terribile Porta dell'Inferno, che minaccia l'Impero stesso.
[i]Citadel of Blood[/i] è una serie di incursioni nella Cittadella di X lo Sconosciuto da parte di un gruppo misto di Popoli Liberi, rappresentanti dell'Impero e mercenari. Somiglia ai giochi di ruolo, ma non richiede un master. Si gioca in solitario (come in questa versione digitale) o in 2-6 giocatori. Personaggi e ambientazione vengono da [i]Swords and Sorcery[/i] della SPI."""],
["2.0", "Materiale", """Il gioco consiste nel regolamento e in 200 pedine: tessere di stanze e corridoi, mostri, eroi e iniziati, elementi delle stanze. Servono tre dadi a sei facce.
[b]2.1[/b] I giocatori costruiscono la superficie di gioco con le tessere stanza/corridoio mentre esplorano la Cittadella. Ogni tessera ha una stanza su un lato e un corridoio sull'altro; si accostano come tessere del domino. Ogni tessera, e ogni area accanto a una tessera già piazzata, è un [b]segmento[/b] della Cittadella.
[b]2.2[/b] Le pedine rappresentano stanze e corridoi, mostri, eroi e le altre creature che difendono o assaltano la Cittadella.
[b]2.3[/b] Le regole sono pensate per essere modificate: in caso di dubbio si usa il buon senso o un tiro di dado."""],
["3.0", "Codici dei dadi", """[b]3.1[/b] Un codice è un numero seguito da "D" e da un altro numero, a volte con un terzo numero (per esempio 1D6+1). Il primo numero indica quanti dadi tirare, il secondo se sono dadi a sei o a tre facce (per un dado a tre facce si tira un D6, si divide per due e si arrotonda per eccesso: da 1 a 3). Il terzo numero si somma o si moltiplica al risultato: 1D6×4 significa tirare un dado e moltiplicarlo per 4; 1D3+1 significa tirare un dado, dividerlo per due arrotondando in alto e aggiungere 1.
[b]3.2[/b] Sulle pedine dei mostri il codice è abbreviato: il primo numero è il numero di D6, seguito dall'aggiunta. Così 1+1 vale 1D6+1 (e ½ vale 1D3)."""],
["4.0", "Preparazione", """[b]4.1 A. Scelta dei personaggi.[/b] I personaggi sono divisi in Eroi e Iniziati. Gli Eroi si mescolano coperti, così la scelta è casuale. In solitario si prendono 3 Eroi e 3 Iniziati (si può giocare con meno di sei personaggi, almeno quattro consigliati, ma mai con più di sei).
[b]B. Caratteristiche.[/b] Gli Eroi usano la Tabella delle Caratteristiche degli Eroi (4.3). Per gli Iniziati si sceglie la razza: [b]Elfo[/b] 5 PF, Resistenza 2, +1 con l'arco, +1 Negoziazione; [b]Nano[/b] 6 PF, Resistenza 2, +1 con l'ascia, Disinnesco 1; [b]Umano[/b] 7 PF, Resistenza 1, +1 con la spada, 1 contro la Porta dell'Inferno. Si scelgono un'arma primaria e una secondaria e si tira sulla Tabella del Potenziale Magico (4.4). Ogni personaggio con Potenziale Magico sceglie tanti incantesimi quanto il numero più alto dei suoi tre valori (con 4/3/2 ne conosce 4). Per l'esperienza fatta nel mondo, ogni Iniziato può avere: +1 Punto Ferita, oppure +1 con un'arma, oppure +1 a Negoziazione, Porta o Disinnesco.
[b]C. Ordine di marcia.[/b] Il gruppo si muove con un'unica pedina, ma i personaggi sono disposti in file di al massimo tre; la prima fila deve averne almeno due (salvo che il gruppo sia di uno). L'ordine si cambia liberamente finché non comincia un combattimento; durante lo scontro solo nella fase di Riorganizzazione (9.8).
[b]D. Sole dominante.[/b] A ogni ingresso nella Cittadella si tira 1D6: 1-2 sole rosso (valore di sinistra), 3-4 sole giallo (valore centrale), 5-6 sole blu (valore di destra). Ogni mago può usare, fra quelli che conosce, tanti incantesimi quanto il suo Potenziale per quel sole: con 3 e un Potenziale 4/5/6 ne usa 5. Si usano solo gli incantesimi scelti, per tutta la spedizione.
[b]E. Tessere.[/b] Le tessere stanza/corridoio vanno in una tazza. Il Portale del Male, la Porta dell'Inferno e X lo Sconosciuto si mettono da parte finché non servono.
[b]F. Inizio.[/b] Il Portale del Male segna l'ingresso della Cittadella e il gruppo vi si posa sopra."""],
["5.0", "Sequenza di gioco", """Le decisioni si prendono insieme (in solitario, le prendi tu). Il gioco finisce quando tutti i personaggi sono usciti dalla Cittadella o sono morti.
[b]A. Fase del segmento.[/b] 1) Scegli il percorso: una porta o un corridoio in uscita dal segmento in cui si trova il gruppo. 2) Pesca una tessera. 3) Piazzala accanto all'uscita scelta: dal lato stanza se si esce da una porta, dal lato corridoio se si esce da un corridoio. Se si può piazzare in più modi, decide il gruppo.
[b]B. Fase delle trappole[/b] (solo entrando in una stanza). 1) Si tira 1D6: con 1 la porta ha una trappola. 2) Un personaggio con Disinnesco può provare a disinnescarla (7.0). 3) Se non ci si prova o si fallisce, si tira sulla Tabella delle Trappole (7.1).
[b]C. Fase dei mostri.[/b] 1) Il gruppo entra nel nuovo segmento. 2) Controllo dei mostri: una stanza mai visitata contiene mostri con 1, 2 o 3; una stanza già visitata o qualsiasi corridoio contiene mostri erranti con 1, salvo che vi siano ancora mostri incontrati prima (6.9). 3) Il gruppo può negoziare o corrompere (8.0). 4) Altrimenti si combatte (9.2): fase del gruppo, fase dei mostri, fase della Porta, riorganizzazione del gruppo, riorganizzazione dei mostri. 5) Uccisi i mostri, si raccoglie il tesoro (14.0). 6) Si guadagna esperienza (12.0).
[b]D. Fase degli elementi[/b] (solo nelle stanze, a scelta del gruppo). Un personaggio indaga l'elemento e tira sulla Tabella degli Elementi (13.9), tranne per gli specchi (13.7)."""],
["6.0", "Movimento nella Cittadella", """Non c'è una mappa: il labirinto si costruisce piazzando tessere accostate. Ogni volta che il gruppo lascia un segmento verso uno spazio vuoto, si pesca una tessera e la si piazza in modo che una porta tocchi sempre una porta e un corridoio sempre un corridoio. Rientrando in un segmento già esplorato non si pesca nulla.
[b]6.1[/b] Porte con porte, corridoi con corridoi, muri con muri. Se la tessera pescata non combacia si rimette nella tazza e se ne pesca un'altra. Se nessuna combacia (raro) si usa quella più adatta: i lati che non combaciano sono impraticabili. Uscendo da una porta, se la tessera ha corridoi su entrambi i lati, si piazza dal lato stanza, porta contro porta.
[b]6.2[/b] Se la tessera può stare in più posizioni, sceglie il gruppo.
[b]6.3[/b] Il gruppo si muove di un segmento per turno.
[b]6.4[/b] Finché non si trova la Porta dell'Inferno il labirinto non può chiudersi in un vicolo cieco: la tessera che lo chiuderebbe torna nella tazza e se ne pesca un'altra.
[b]6.5[/b] La Cittadella ha fino a tre livelli. Alcune stanze hanno una scala che collega il primo livello al secondo e al terzo. La Porta dell'Inferno può trovarsi su uno qualunque dei tre livelli. Più si scende, più i mostri sono feroci.
[b]6.6[/b] Cambiare livello vale come entrare in una stanza, con tutte le procedure. Scendendo per la prima volta si comincia un nuovo labirinto da una seconda tessera con la scala.
[b]6.8[/b] La Tabella dei Livelli (6.7) modifica i mostri e i guadagni: [i]Ferite dei mostri[/i] si sommano al tiro dei loro Punti Ferita; [i]Bonus di combattimento[/i] si somma al loro bonus; [i]Negoziazione[/i] aumenta il loro valore; [i]Numero dei mostri[/i] moltiplica quelli incontrati (al livello 3 tre Cronk diventano sei); [i]Tipo di tesoro[/i] sposta il tipo verso il basso della tabella (un tesoro C al livello 3 diventa E); [i]Esperienza[/i] moltiplica i punti guadagnati.
[b]6.9[/b] Un mostro aggirato resta sulla mappa. Se il gruppo rientra in quel segmento lo tratta come un mostro nuovo: accordi e corruzioni precedenti non valgono più. Dove c'è un mostro non si controllano i mostri erranti."""],
["7.0", "Trappole e disinnesco", """La prima volta che il gruppo entra in una stanza, un personaggio controlla la porta; anche i forzieri del tesoro vanno controllati. Chi ha l'abilità di Disinnesco tira 1D6: se il risultato è minore o uguale alla sua abilità la trappola è disinnescata, altrimenti scatta e si tira sulla Tabella delle Trappole. Su chi non sa disinnescare la trappola scatta sempre.
[b]7.2[/b] [b]Freccia:[/b] si tira 1D6 sulla colonna Arco della Tabella del Combattimento per vedere se e quanto ferisce. [b]Freccia avvelenata:[/b] come sopra, e se colpisce il veleno causa 1D3 ferite in più. [b]Gas velenoso:[/b] 1D3 ferite. [b]Esplosione:[/b] tutti i membri del gruppo (anche i mostri incantati) subiscono 1 ferita. [b]Olio bollente:[/b] 1 ferita. [b]Tira due volte:[/b] scattano due trappole; con un altro 6 se ne tirano altre due, e così via.
[b]7.3[/b] Il Disinnesco non può mai superare 5."""],
["8.0", "Mostri, negoziazione e corruzione", """La Cittadella è popolata da un'orda di mostri e da un supercattivo, X lo Sconosciuto. Il gruppo può negoziare, corrompere o combattere. Un'intesa permette di proseguire senza combattere; se negoziazione e corruzione falliscono si combatte, finché muoiono i mostri o il gruppo. Uccisi i mostri, il gruppo prende il loro tesoro e può indagare gli elementi della stanza.
[b]8.1[/b] Si tira 1D6 due volte e si incrociano i risultati sulla Tabella dei Mostri della Stanza o dei Mostri Erranti (modificati dalla Tabella dei Livelli).
[b]8.4[/b] Si può negoziare con qualsiasi mostro tranne i Demoni e X lo Sconosciuto. Un personaggio tira 2D6 e sottrae il Valore di Negoziazione del mostro; aggiunge la propria abilità di Negoziazione e gli eventuali incantesimi (10.7), poi legge il risultato sulla Tabella della Negoziazione.
[b]8.6[/b] [b]Fallimento:[/b] si può tentare la corruzione o si combatte. [b]Accordo:[/b] il mostro lascia in pace il gruppo, salvo che sia il gruppo ad attaccarlo; si possono indagare gli elementi e uscire, e il mostro resta sulla mappa. [b]Intimidazione:[/b] i mostri lasciano in pace il gruppo e quelli con un tesoro cedono un quarto dei loro marchi d'oro; il gruppo può comunque attaccarli.
[b]8.7[/b] La corruzione è possibile se la negoziazione fallisce (non con Demoni né con X). Sulla Tabella della Corruzione si incrocia la somma di Punti Ferita e Valore di Negoziazione del mostro più forte con i marchi offerti: il numero indicato è quello da fare o meno con 1D6. Riuscire vale come un Accordo. Se fallisce, i mostri attaccano per primi (il gruppo perde la sua prima fase di combattimento); dopo lo scontro il gruppo riprende l'oro offerto insieme al tesoro dei mostri.
[b]8.8[/b] Un solo tentativo di corruzione per incontro."""],
["9.0", "Combattimento", """Il combattimento è fatto di round, ognuno diviso in fasi; una volta cominciato non si interrompe finché una delle due parti non è eliminata. Si stabiliscono tipo e numero dei mostri e i loro Punti Ferita, si dispone il loro ordine di marcia e comincia la sequenza.
[b]9.1[/b] Se i mostri sono più di tre, i tre con più Punti Ferita vanno in prima fila, gli altri in seconda e terza. Un mostro solo va al centro; due mostri al primo e al terzo posto.
[b]9.2[/b] [b]1. Fase del gruppo:[/b] chi è in prima fila attacca un mostro della prima fila nemica; chi è in seconda fila può tirare con l'arco, lanciare pugnali e incantesimi. [b]2. Fase dei mostri:[/b] ogni mostro in prima fila attacca un personaggio della prima fila, in mischia o con incantesimi (i maghi malvagi possono lanciare dalla prima fila); quelli in seconda fila tirano con l'arco o lanciano incantesimi. [b]3. Fase della Porta:[/b] solo davanti alla Porta dell'Inferno, che lancia 3 Scariche. [b]4. Riorganizzazione del gruppo:[/b] un personaggio può cambiare posto; nessuna fila può superare tre. [b]5. Riorganizzazione dei mostri:[/b] un mostro avanza per riempire la prima fila.
[b]9.3[/b] Con tre personaggi contro tre mostri ognuno attacca chi ha di fronte (A contro 1, B contro 2, C contro 3). Se in una fila ci sono meno di tre unità, si attacca il nemico di fronte, salvo che ce ne siano altri alla stessa distanza: i mostri tirano a caso, i personaggi scelgono. Esempi: con i mostri A e B davanti a 1, 2 e 3, A attacca 1 e B tira (1-3 attacca 2, 4-6 attacca 3). Un mostro solo al centro sceglie con un dado fra 1, 2 e 3; un personaggio solo al centro sceglie lui. Dalla seconda fila un personaggio può attaccare qualsiasi mostro della prima fila; un mostro dalla seconda fila (o la Porta dalla terza) tira a caso fra i personaggi della prima fila.
[b]9.4[/b] I personaggi attaccano solo nella fase del gruppo e i mostri solo nella loro. Ogni personaggio combatte con una delle sue due armi; per cambiarla rinuncia ad attaccare in quella fase. Si attacca una sola volta per fase e un solo nemico; un nemico può essere attaccato da molti (fino a 6). I danni hanno effetto subito.
[b]9.5[/b] Per un attacco si tira 1D6, si aggiungono abilità con l'arma e Bonus di Combattimento e si legge il totale nella colonna dell'arma della Tabella del Combattimento: il numero indica le ferite inflitte. Esempio: Almuric tira 4, aggiunge +2 (abilità con la spada) e +3 (bonus): 9 nella colonna Spada. Il pugnale da lancio si lancia una sola volta per combattimento; l'arco tira in ogni fase del gruppo, ma solo dalla seconda fila.
[b]9.6[/b] I mostri senz'arma usano la colonna Mostri; quelli armati (W sulla pedina) la colonna della loro arma, sommando il loro bonus.
[b]9.7[/b] Chi subisce tante ferite quanti i suoi Punti Ferita muore.
[b]9.8[/b] [b]Riorganizzazione del gruppo:[/b] un personaggio si sposta nella stessa fila senza scavalcare nessuno, oppure in una fila davanti o dietro, anche in diagonale. Se in prima fila ne è rimasto uno solo, bisogna farne avanzare uno dalla seconda. Se in prima fila ce ne sono due, nessuno può arretrare. [b]Riorganizzazione dei mostri:[/b] se in prima fila ci sono meno di tre mostri, uno avanza dalla seconda; con la prima fila piena, uno può avanzare dalla terza alla seconda. Possono muoversi in diagonale (con più posti liberi si tira), mai indietro o di lato."""],
["10.0", "Magia", """Chi ha Potenziale Magico può lanciare incantesimi. Ogni incantesimo costa Punti Ferita; alcuni si possono resistere (11.0) e in quel caso non hanno effetto.
[b]10.1[/b] Si lanciano incantesimi in combattimento, negoziazione e corruzione; quelli non di combattimento in qualsiasi fase tranne il combattimento.
[b]10.2[/b] Un incantesimo si lancia quante volte si vuole, finché si regge il costo.
[b]10.3[/b] Chi lancia un incantesimo in combattimento non attacca con le armi in quella fase.
[b]10.4[/b] I personaggi lanciano in combattimento solo dalla seconda fila.
[b]10.5 Incantesimi di combattimento.[/b] [b]Incantamento[/b] (3): un mostro di prima o seconda fila che non resiste passa dalla parte del gruppo; se il mago muore, il mostro attacca il gruppo. I mostri incantati non guadagnano esperienza. [b]Scarica[/b] (1): 2 ferite a un mostro di prima fila. [b]Esplosione[/b] (1): tutti, mostri e personaggi, fanno la Resistenza; chi fallisce subisce 1 ferita. [b]Fulmine[/b] (2): 1D3+2 ferite a un mostro di prima fila. [b]Sonno[/b] (2): un mostro di qualsiasi fila si addormenta e non combatte; quando gli altri sono uccisi o addormentati, chi dorme è ucciso senza tiri. [b]Redenzione[/b] (3): un personaggio incantato torna nel gruppo. [b]Scudo magico[/b] (2): immunità agli incantesimi che feriscono per tutto lo scontro. [b]Esitazione[/b] (2): il gruppo ha il tempo di curarsi prima del combattimento; non si resiste. [b]Tregua[/b] (3): come un Accordo, fine immediata del combattimento; non si resiste; non funziona contro X. [b]Attacco mentale[/b] (4): 2D6+2 ferite a un mostro di prima fila.
[b]10.6 Incantesimi fuori combattimento.[/b] [b]Serratura[/b] (1): aperta una porta e visto il mostro, invece di trattare o combattere si richiude la porta per sempre; il mostro resta dentro. [b]Armatura magica[/b] (1): assorbe 1D3+1 ferite (non quelle degli incantesimi del lanciatore). [b]Neutralizza veleno[/b] (1): subito dopo un avvelenamento ne annulla gli effetti. [b]Pietra in carne[/b] (3): riporta in vita chi è stato pietrificato dalla Medusa; non in combattimento, non su se stessi. [b]Forza[/b] (1): come la Pozione della Forza. [b]Teletrasporto[/b] (3): durante negoziazione o corruzione manda un personaggio o un mostro in un segmento già visitato; non contro X, i Demoni o la Porta. [b]Guarigione[/b] (1): cura 1D3+1 ferite; non su se stessi; prima di entrare si tira 1D6 per sapere quante volte si potrà lanciare. [b]Rigenerazione[/b] (2): come Guarigione ma cura 1D6+1. [b]Ladro[/b] (1): +3 al Disinnesco per un tentativo, solo su chi sa disinnescare.
[b]10.7 Negoziazione e corruzione.[/b] [b]Oratoria[/b] (1): +4 al tiro di negoziazione. [b]Intimorire[/b] (2): il mostro è intimidito senza tirare (si può resistere). [b]Soggiogare[/b] (3): come Intimorire, ma il mostro consegna tutto il tesoro. [b]Persuasione[/b] (1): −2 al tiro di corruzione. [b]Lusinga[/b] (2): −4 al tiro di corruzione.
[b]10.8 Incantesimi speciali.[/b] Si imparano solo durante il gioco. [b]Ira di Dio[/b] (combattimento, 3): 2D6+2 ferite a un mostro, che può resistere; si impara da Malthus o dal Manoscritto. [b]Resurrezione[/b] (5): subito dopo il combattimento riporta in vita un caduto, con le ferite che aveva entrando nella Cittadella; si impara dalla Libreria o si trova in un Anello."""],
["11.0", "Prove di Resistenza", """Quando un incantesimo, un oggetto o un elemento lo richiede, si tira 1D6: con un risultato minore o uguale al Valore di Resistenza la prova riesce, altrimenti fallisce. La Resistenza non può mai superare 5."""],
["12.0", "Esperienza", """Si guadagna esperienza uccidendo mostri. Si sommano i Punti Ferita che i mostri avevano all'inizio dello scontro, si moltiplicano per sei e si dividono fra i personaggi rimasti vivi (arrotondando per difetto).
[b]12.1[/b] I mostri incantati non guadagnano esperienza; i personaggi prendono tutti i punti.
[b]12.2[/b] A fine partita un personaggio può spendere 100 punti esperienza e 100 marchi (anche in gioielli) per aumentare di 1: i Punti Ferita, l'abilità con un'arma, la Resistenza (massimo 5), il Disinnesco, l'abilità contro la Porta, la Negoziazione o il Potenziale Magico per un sole.
[b]12.3[/b] Con 150 punti e 150 marchi si aumenta di 1 il Bonus di Combattimento."""],
["13.0", "Elementi delle stanze", """Alcune stanze contengono una fontana, una statua, una botola, dei mobili, una scala, uno specchio o un'opera d'arte. Risolti i mostri, il gruppo può far indagare un personaggio: si tira 1D6 sulla colonna dell'elemento; solo chi indaga ne subisce o ne gode gli effetti.
[b]13.1 Fontane[/b] (tre iene di bronzo versano liquidi): [b]Veleno[/b] 1D3 ferite. [b]Pozione[/b]: si tira sulla Tabella degli Oggetti Magici, colonna Pozioni; chi indaga ne subisce gli effetti e può portarne via una dose. [b]Alcol[/b]: ubriaco, −2 al Bonus di Combattimento per il resto della partita. [b]Gioiello[/b]: si tira sulla Tabella dei Gioielli. [b]Acqua[/b]: nessun effetto. [b]Sangue[/b]: nausea, −1 al Bonus di Combattimento per il resto della partita.
[b]13.2 Statue[/b] di alabastro: [b]Medusa[/b]: prende vita; chi indaga fa la Resistenza o diventa di pietra, poi si tratta o si combatte con la Medusa. [b]Gioielli[/b]: un ariete con due gemme per occhi. [b]Medaglione[/b]: colonna Medaglioni. [b]Demone[/b]: si tira sulla colonna Altari e la statua vale come quell'altare. [b]Talismano[/b]: colonna Talismani. [b]X[/b]: statua di X lo Sconosciuto; chi fallisce la Resistenza diventa suo strumento e attacca il gruppo dal centro della fila dei mostri, finché muore, il gruppo muore o viene redento.
[b]13.3 Botole:[/b] [b]Trappola[/b]: si tira sulle Trappole, poi si raccoglie un tesoro di tipo J. [b]Stanza[/b]: chi indaga cade da solo in una stanza sottostante, dove si controllano i mostri; c'è un tesoro J e il gruppo non può aiutarlo. [b]Fossa[/b]: una fossa con 1D3 Cronk, da affrontare da soli. [b]Porta dell'Inferno[/b]: un pozzo porta chi indaga nella bocca della Porta; resta prigioniero finché la Porta non è distrutta.
[b]13.4 Mobili:[/b] [b]Bara[/b]: si leva un Vampiro (15.5) che combatte subito con chi indaga, senza trattative; dal secondo round il gruppo può aiutare. [b]Libreria[/b]: 1D6, con 1-3 crolla (1D3 ferite), con 4-6 si impara Resurrezione. [b]Scrittoio[/b]: il cassetto ha una trappola; superata, c'è un medaglione. [b]Letto[/b]: chi ci si sdraia recupera 1D3 Punti Ferita. [b]Clavicembalo[/b]: suona da solo; chi fallisce la Resistenza vi infila metà dei suoi marchi, recuperabili subendo 1 ferita. [b]Specchio[/b]: Tabella dello Specchio (13.7).
[b]13.5 Altari[/b] dei sei demoni della Cittadella: chi indaga fa la Resistenza; se riesce ottiene il dono, se fallisce la maledizione. [b]Alloces[/b], il Duca Guerriero: incantesimi di combattimento gratis nel prossimo scontro / −1 al Bonus di Combattimento. [b]Vassago[/b], il Principe della Profezia: +3 al Disinnesco / perde il Disinnesco. [b]Avnas[/b], il Presidente del Fuoco: Fulmine a 1 PF / l'altare gli scaglia un Fulmine. [b]Malthus[/b], il Conte della Morte e del Caos: impara l'Ira di Dio / l'altare gli scaglia l'Ira di Dio. [b]Leraje[/b], il Marchese degli Arcieri: +3 con l'arco / tre frecce magiche. [b]Asmoday[/b], il Re Infernale: +3 al Bonus di Combattimento e Fulmine a 1 PF / −1 al Potenziale Magico sotto ogni sole.
[b]13.6 Opere d'arte:[/b] [b]Arazzo[/b] elfico: si può lasciare un'arma per portarlo via; vale come un gioiello tirando con +4. [b]Dipinto[/b]: ognuno tira 1D6, con 1 è ritratto ed è maledetto (1D3 ferite). [b]Statua[/b]: si tira sulla colonna Statue. [b]Vetro intagliato[/b]: 1D6, con 1-3 è un talismano, con 4-6 un medaglione. [b]Icona[/b] di un demone: colonna Altari. [b]Manoscritto[/b]: si impara l'Ira di Dio.
[b]13.7 Gli specchi rivelano la Porta.[/b] Il primo specchio rivela il [i]livello[/i] della Porta dell'Inferno (colonna Livello). Se è il livello in cui si trova il gruppo, un secondo tiro dice quanti segmenti inesplorati bisogna ancora entrare prima di trovarla. Se è un altro livello, il secondo tiro si fa con uno specchio di quel livello. Esempio: uno specchio al primo livello indica il terzo; scesi al terzo e trovato un altro specchio si tira 6: la Porta è nel sesto segmento inesplorato.
[b]13.8[/b] Le scale funzionano come descritto in 6.6."""],
["14.0", "Tesori", """Uccisi i mostri (o a volte dopo un'intesa) si determina il loro tesoro: marchi d'oro, gioielli e oggetti magici, che il gruppo divide come vuole. Gli oggetti magici si usano per tutta la partita e si conservano per la campagna. Se un personaggio muore, i compagni si dividono il suo tesoro.
[b]Procedura.[/b] La colonna Tesoro dei mostri dà una lettera, o due separate da una barra (la prima per i mostri della stanza, la seconda per quelli erranti). Sulla Tabella dei Tesori ogni colonna ha un codice come "3:1D6×5": si tira 1D6 e, se il risultato è minore o uguale al primo numero, si tira il codice dopo i due punti. Ogni gioiello vale 2D6 sulla Tabella dei Gioielli; per ogni oggetto magico si tira prima il tipo e poi la varietà. I marchi si dividono fra il gruppo.
[b]14.1[/b] I tesori J, K e L sono sempre in forzieri, che con 1-3 su 1D6 hanno una trappola.
[b]14.2[/b] Il tesoro di ogni mostro si determina separatamente.
[b]14.3 Armi.[/b] Un terzo tiro sulla Tabella delle Armi dà il bonus; con "tira due volte" si sommano due tiri (anche più volte). Chi ha già due armi ne lascia una per prendere quella magica.
[b]14.4 Armature.[/b] Danno Punti Ferita aggiuntivi a chi le indossa; si passano da un personaggio all'altro fuori dal combattimento, ma chi la toglie perde il bonus (e può morirne).
[b]14.5 Pozioni.[/b] Chi la prova ne subisce l'effetto; poi resta una dose da usare quando si vuole. [b]Veleno[/b]: 1D3 ferite. [b]Forza[/b]: +1D6 al Bonus di Combattimento nel prossimo scontro. [b]Fascino sulle persone[/b]: si prende il controllo di un Eroe Malvagio, Mago Malvagio, Orco o Troll presente. [b]Fascino sui mostri[/b]: lo stesso con un mostro che non sia uno di quelli. [b]Guarigione[/b]: cura 1D6 ferite.
[b]14.6 Talismani.[/b] [b]della Mente[/b]: battaglia mentale contro un nemico per 1 PF, 1D6 ferite se fallisce la Resistenza; usi limitati a 1D6. [b]del Sole giallo, blu, rosso[/b]: +1D3 al Potenziale Magico per quel sole. [b]di Tutti i Soli[/b]: +1D3 a ogni sole. [b]del Male[/b]: chi fallisce la Resistenza attacca il gruppo, per primo, finché muore, il gruppo muore o viene incantato o redento.
[b]14.7 Medaglioni.[/b] [b]Neutralizza Veleno[/b]: immunità al veleno. [b]Stima delle Pozioni[/b]: riconosce le pozioni senza provarle (due dosi, i veleni si gettano). [b]Oratoria[/b]: +3 alle negoziazioni. [b]Destrezza[/b]: +2 al Bonus di Combattimento. [b]Strangolatore[/b]: 1D6 ferite a chi lo prova.
[b]14.8 Anelli.[/b] [b]Resistenza +1 o +2[/b] finché lo si porta. [b]Sonno, Neutralizza Veleno, Guarigione, Resurrezione[/b]: si lancia l'incantesimo una volta per spedizione senza costo."""],
["15.0", "Capacità speciali dei mostri", """[b]15.1[/b] Il fetore dei Cronk: all'inizio dello scontro ognuno fa la Resistenza; chi fallisce ha −2 al Bonus di Combattimento finché dura.
[b]15.2[/b] La Chimera, a ogni attacco, soffia fuoco: chi fallisce la Resistenza subisce 1 ferita in più.
[b]15.3[/b] La Medusa, a ogni attacco, tira 1D6: con 6 il bersaglio è pietrificato e lascia l'ordine di marcia. A fine scontro Pietra in carne può salvarlo, altrimenti è morto.
[b]15.4[/b] Il Troll, alla fine di ogni terza fase dei mostri dopo la prima ferita, rigenera 1 Punto Ferita.
[b]15.5[/b] Il Vampiro, nelle prime due fasi dei mostri, tenta di incantare chi attacca (senza costo): chi fallisce la Resistenza passa in prima fila fra i mostri e attacca il gruppo; torna libero se il Vampiro muore o con Redenzione.
[b]15.6[/b] Ogni ferita inflitta all'Idra aumenta di 1 il suo Bonus di Combattimento.
[b]15.7[/b] I Maghi Malvagi (e X) conoscono il Fulmine e lo lanciano in ogni fase dei mostri, salvo che ne morirebbero."""],
["16.0", "La Porta dell'Inferno", """La Porta è un enorme congegno simile a una montagna, di immenso potere magico, che il gruppo deve trovare e distruggere. È difesa da 1D3+2 demoni (senza modifiche di livello) e da X lo Sconosciuto. Demoni in prima e seconda fila, X in seconda, la Porta in terza. Nella fase della Porta lancia 3 Scariche contro uno o più personaggi, senza costo, finché X vive. Morto X la Porta si spegne e i demoni svaniscono. Poi un personaggio con l'abilità contro la Porta tira 1D6: se il risultato è minore o uguale alla sua abilità la Porta è distrutta, altrimenti subisce 1 ferita; si può ritentare finché si riesce, si muore o si rinuncia. A Demoni e X si applicano solo le righe Ferite, Bonus, Tesoro ed Esperienza della Tabella dei Livelli. L'abilità contro la Porta non supera mai 5."""],
["17.0", "Condizioni di vittoria", """Il gruppo vince se distrugge la Porta dell'Inferno e almeno un personaggio esce vivo dalla Cittadella per raccontarlo; possono servire più partite. Vince come singolo chi esce vivo con almeno 100 punti esperienza e almeno 100 marchi in oro o gioielli; fra più vincitori prevale chi ha il totale più alto di esperienza e ricchezza. Il gruppo può uscire prima di distruggere la Porta, ma allora niente vittoria di squadra. Per uscire bisogna tornare al primo livello e al segmento del Portale del Male. Si può rientrare dopo essersi curati di tutte le ferite: nella stessa sessione il labirinto resta com'è.
[b]17.1[/b] Oro e gioielli di una spedizione restano a casa quando si rientra, e servono per i miglioramenti (12.2).
[b]17.2[/b] I mostri incantati se ne vanno prima del rientro.
[b]17.3[/b] Rientrando si può riportare il gruppo a sei con nuovi Eroi o Iniziati.
[b]17.4[/b] Prima di rientrare si possono cambiare le armi (mai più di due).
[b]17.5[/b] Fra una spedizione e l'altra passano sei mesi: dopo la terza uscita i punti necessari ai miglioramenti crescono del 10% a ogni uscita."""],
["", "Crediti", """[b]Progetto e sviluppo:[/b] Eric Smith. [b]Sistemi fisici e grafica:[/b] Redmond A. Simonsen. [b]Sistema di gioco originale:[/b] Greg Costikyan e Redmond A. Simonsen. [b]Revisione delle regole:[/b] Brad Hessel. Pubblicato da Simulations Publications Inc. su ARES n. 5, novembre 1980.
Versione digitale per uso personale: traduzione italiana, grafica Reborn generata per questa edizione."""],
]

static func contenuto() -> Control:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	for s in SEZIONI:
		var t = Widget.etichetta(("[%s] " % s[0] if s[0] != "" else "") + s[1], 26, Risorse.COL_SANGUE, "Titoli")
		v.add_child(t)
		var r = Widget.testo_ricco(s[2], 17)
		r.add_theme_color_override("default_color", Risorse.COL_INCHIOSTRO)
		v.add_child(r)
	return v

# --------------------------------------------------------------------------------------------
# Tabelle, impaginate come le "Charts and Tables" originali: righe alternate grigie e bianche
# --------------------------------------------------------------------------------------------
static func tabella(titolo: String, intest: Array, righe: Array, larghezze: Array = []) -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var t = Widget.etichetta(titolo, 22, Risorse.COL_INCHIOSTRO, "grassetto")
	box.add_child(t)
	var g = GridContainer.new()
	g.columns = intest.size()
	g.add_theme_constant_override("h_separation", 0)
	g.add_theme_constant_override("v_separation", 0)
	box.add_child(g)
	for i in intest.size():
		g.add_child(_cella(str(intest[i]), true, false, larghezze[i] if i < larghezze.size() else 90))
	var n = 0
	for r in righe:
		for i in r.size():
			g.add_child(_cella(str(r[i]), false, n % 2 == 0, larghezze[i] if i < larghezze.size() else 90))
		n += 1
	return box

static func _cella(testo: String, testa: bool, grigia: bool, larghezza: float) -> Control:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.82, 0.8, 0.76) if grigia else Color(0.96, 0.94, 0.9)
	if testa: sb.bg_color = Color(0.93, 0.9, 0.84)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.x = larghezza
	var l = Widget.etichetta(testo, 15, Risorse.COL_INCHIOSTRO, "grassetto" if testa else "Testo")
	if testa: l.add_theme_font_override("font", Risorse.font_grassetto())
	p.add_child(l)
	return p

static func tabelle() -> Control:
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	# 9.9 Combattimento
	var righe = []
	for i in D.CRT_RIGHE.size():
		var r = [D.CRT_RIGHE[i]]
		for a in ["pugnale", "pugnale_lancio", "arco", "spada", "martello", "ascia", "mostro"]:
			r.append(D.CRT[a][i])
		righe.append(r)
	v.add_child(tabella("[9.9] Tabella dei Risultati del Combattimento", ["Dado", "Pugnale", "Pugnale da lancio", "Arco", "Spada", "Martello", "Ascia", "Mostri"], righe, [60, 90, 150, 70, 70, 90, 70, 80]))
	# 4.3 Eroi
	righe = []
	for e in D.EROI:
		var armi = []
		for a in e["armi"]: armi.append(D.nome_arma(a))
		var ab = []
		for k in e["abil"]: ab.append("+%d %s" % [e["abil"][k], D.nome_arma(k)])
		var sp = ""
		if e.has("hellgate"): sp = "%d Porta" % e["hellgate"]
		if e.has("disinnesco"): sp = "%d Disinnesco" % e["disinnesco"]
		if e.has("negoziazione"): sp = "+%d Negoziazione" % e["negoziazione"]
		righe.append([e["nome"], e["razza"], e["pf"], "%d/%d/%d" % e["pm"], e["vr"], e["bc"], ", ".join(armi), ", ".join(ab) if not ab.is_empty() else "nessuna", sp])
	v.add_child(tabella("[4.3] Tabella delle Caratteristiche degli Eroi", ["Nome", "Razza", "PF", "PM", "VR", "BC", "Armi", "Abilità armi", "Abilità"], righe, [150, 110, 40, 60, 40, 40, 170, 110, 130]))
	# 4.4 Potenziale
	righe = []
	for i in 6:
		righe.append([i + 1, D.POTENZIALE[i][0], D.POTENZIALE[i][1], D.POTENZIALE[i][2]])
	v.add_child(tabella("[4.4] Tabella del Potenziale Magico", ["Dado", "Rosso", "Giallo", "Blu"], righe, [60, 70, 70, 70]))
	# 6.7 Livelli
	v.add_child(tabella("[6.7] Tabella dei Livelli", ["Caratteristica", "Livello 1", "Livello 2", "Livello 3"], [
		["Ferite dei mostri", "+0", "+2", "+4"], ["Bonus di combattimento", "+0", "+1", "+3"], ["Negoziazione dei mostri", "+0", "+1", "+2"],
		["Numero dei mostri", "×1", "×1", "×2"], ["Tipo di tesoro", "+0", "+1", "+2"], ["Punti esperienza", "×1", "×1", "×2"]], [220, 90, 90, 90]))
	# 7.1 Trappole
	righe = []
	for i in 6: righe.append([i + 1, D.NOMI_TRAPPOLE[D.TRAPPOLE[i]]])
	v.add_child(tabella("[7.1] Tabella delle Trappole", ["Dado", "Trappola"], righe, [60, 200]))
	# 8.2 Mostri
	righe = []
	for k in ["chimera", "cronk", "demone", "lupo", "eroe_m", "mago_m", "gargoyle", "arpia", "idra", "medusa", "minotauro", "ogre", "orco", "scheletro", "troll", "vampiro", "warg", "wight", "wraith", "x"]:
		var m: Dictionary = D.MOSTRI[k]
		var dadi = ("½" if m["dadi"] < 1 else str(int(m["dadi"]))) + "+%d" % int(m["agg"])
		righe.append([m["nome"], m["bc"], dadi, m["vr"], m["vn"] if int(m["vn"]) >= 0 else "nessuno", D.nome_arma(m["arma"]) if m["arma"] != "" else "–", "Fulmine" if m["inc"] == "lt" else "–", m["tesoro"], m["spec"] if m["spec"] != "" else "–"])
	v.add_child(tabella("[8.2] Tabella delle Caratteristiche dei Mostri", ["Mostro", "BC", "PF", "VR", "VN", "Arma", "Incantesimi", "Tesoro", "Speciale"], righe, [150, 40, 50, 40, 70, 80, 90, 60, 170]))
	# 8.3 Mostri della stanza
	righe = []
	for i in 6:
		var r2 = [i + 1]
		for j in 6:
			var x: Array = D.MOSTRI_STANZA[i][j]
			r2.append(_voce_mostro(x))
		righe.append(r2)
	v.add_child(tabella("[8.3] Tabella dei Mostri della Stanza (primo dado in riga, secondo in colonna)", ["", "1", "2", "3", "4", "5", "6"], righe, [40, 120, 120, 120, 120, 120, 120]))
	righe = []
	for i in 6:
		var r3 = [i + 1]
		for j in 3:
			r3.append(_voce_mostro(D.MOSTRI_ERRANTI[i][j]))
		righe.append(r3)
	v.add_child(tabella("[8.3] Tabella dei Mostri Erranti", ["", "1-2", "3-4", "5-6"], righe, [40, 150, 150, 150]))
	v.add_child(tabella("[8.5] Tabella della Negoziazione", ["Dado", "Risultato"], [["6 o meno", "Fallimento"], ["7-9", "Accordo"], ["10 o più", "Intimidazione"]], [100, 160]))
	righe = []
	for i in D.CORRUZIONE_OFFERTE.size():
		righe.append([D.CORRUZIONE_OFFERTE[i]] + D.CORRUZIONE[i])
	v.add_child(tabella("[8.9] Tabella della Corruzione (PF + Negoziazione del mostro più forte)", ["Marchi offerti"] + D.CORRUZIONE_COLONNE, righe, [130, 60, 60, 70, 70, 70, 60]))
	# 10.9 Incantesimi
	righe = []
	for k in D.INCANTESIMI_ORDINE + ["wg", "rs"]:
		var inc: Dictionary = D.INCANTESIMI[k]
		righe.append([inc["nome"], inc["orig"], inc["costo"], D.TIPI_INCANTESIMO[inc["tipo"]]])
	v.add_child(tabella("[10.9] Riepilogo degli Incantesimi", ["Incantesimo", "Originale", "Costo", "Tipo"], righe, [170, 150, 60, 170]))
	# 13.9 Elementi
	righe = []
	for i in 6:
		var r4 = [i + 1]
		for el in ["fontana", "statua", "botola", "mobili", "altare", "opera"]:
			r4.append(D.NOMI_RISULTATI[D.TABELLA_ELEMENTI[el][i]].split(",")[0])
		righe.append(r4)
	v.add_child(tabella("[13.9] Tabella degli Elementi", ["Dado", "Fontana", "Statua", "Botola", "Mobili", "Altare", "Opera d'arte"], righe, [50, 100, 110, 140, 120, 100, 130]))
	righe = []
	for i in 6: righe.append([i + 1, D.SPECCHIO[i][0], D.SPECCHIO[i][1]])
	v.add_child(tabella("[13.9] Tabella dello Specchio", ["Dado", "Livello", "Segmenti"], righe, [60, 80, 100]))
	# 14.9 Tesori
	righe = []
	for l in "ABCDEFGHIJKL":
		righe.append([l] + D.TESORI_TESTO[l])
	v.add_child(tabella("[14.9] Tabella dei Tesori", ["Tipo", "Marchi d'oro", "Gioielli", "Oggetti magici"], righe, [50, 130, 100, 130]))
	righe = []
	for k in range(2, 13): righe.append([k, D.GIOIELLI[k]])
	v.add_child(tabella("[14.9] Tabella dei Gioielli (2D6)", ["Dadi", "Valore in marchi"], righe, [60, 150]))
	righe = []
	for i in 6:
		righe.append([D.NOMI_OGGETTI_TIPI[D.OGGETTI_TIPI[i]], i + 1, D.nome_arma(D.OGGETTI["arma"][i]),
			("+%d" % D.OGGETTI["armatura"][i]) if int(D.OGGETTI["armatura"][i]) > 0 else "Tira due volte",
			D.NOMI_POZIONI[D.OGGETTI["pozione"][i]].replace("Pozione: ", "").replace("Pozione ", "").replace("della ", "").replace("di ", ""),
			D.NOMI_TALISMANI[D.OGGETTI["talismano"][i]].replace("Talismano ", ""),
			D.NOMI_MEDAGLIONI[D.OGGETTI["medaglione"][i]].replace("Medaglione ", ""),
			D.NOMI_ANELLI[D.OGGETTI["anello"][i]].replace("Anello ", "")])
	v.add_child(tabella("[14.9] Tabella degli Oggetti Magici (primo tiro: tipo; secondo: varietà)", ["Tipo", "Dado", "Arma", "Armatura", "Pozione", "Talismano", "Medaglione", "Anello"], righe, [140, 50, 110, 110, 150, 140, 170, 160]))
	v.add_child(tabella("[14.9] Tabella delle Armi magiche", ["Dado", "Bonus"], [[1, "+1"], [2, "+2"], [3, "+2"], [4, "+3"], [5, "+3"], [6, "Tira due volte"]], [60, 140]))
	return v

static func _voce_mostro(x: Array) -> String:
	var m: Dictionary = D.MOSTRI[x[0]]
	if x[1] == "1": return m["nome"]
	return "%s: %s" % [m["plur"], x[1]]
