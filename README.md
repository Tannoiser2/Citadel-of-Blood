# Citadel of Blood · versione digitale Reborn

Versione digitale per uso personale di **Citadel of Blood** (SPI, ARES n. 5, novembre 1980, di Eric Smith,
dal sistema di *DeathMaze* di Greg Costikyan e Redmond A. Simonsen), fatta in Godot 4.7 e pubblicata su GitHub Pages:
https://tannoiser2.github.io/Citadel-of-Blood/

Il gruppo di avventurieri entra nella Cittadella di X lo Sconosciuto, la esplora tessera dopo tessera, affronta trappole,
mostri e magie, raccoglie tesori e cerca la **Porta dell'Inferno** per distruggerla e uscire vivo.

## Che cosa c'è

- **Regole complete** del regolamento originale: sequenza di gioco, labirinto con le 100 tessere originali (porte con porte,
  corridoi con corridoi, niente vicoli ciechi prima della Porta), tre livelli con le scale, trappole e disinnesco,
  mostri della stanza ed erranti, negoziazione, corruzione, combattimento a file (9.3), riorganizzazione, i 26 incantesimi
  con i tre soli, resistenze, capacità speciali dei mostri, elementi delle stanze (fontane, statue, botole, mobili, altari,
  opere d'arte, specchi), tesori con oggetti magici, Porta dell'Inferno, esperienza, vittoria e campagna con miglioramenti.
- **Labirinto in 3D**: ogni tessera è costruita dalla pianta della pedina originale (muri estrusi), con pavimento di pietra,
  elementi illustrati, pedine in piedi del gruppo e dei mostri. Trascina per spostarti, rotella o pizzico per lo zoom,
  tasto destro o due dita per ruotare (anche su iPad).
- **Grafica Reborn** generata con Kling: 23 eroi, 6 iniziati, 20 mostri, gli elementi delle stanze, il Portale del Male,
  la Porta dell'Inferno e la copertina.
- **Tutto in italiano**: interfaccia, diario, **regolamento tradotto** con la numerazione originale e **tabelle** impaginate
  come le *Charts and Tables* dell'epoca.
- **Tutorial a turni guidati**: una partita vera con dadi preparati che spiega ogni regola quando serve.
- Salvataggio automatico nel browser (pulsante *Continua la partita*).

## Struttura

- `scripts/dati.gd` tabelle del gioco · `scripts/motore_base.gd`, `motore_comb.gd`, `motore.gd` il motore delle regole
- `scripts/vista3d.gd` il labirinto 3D · `scripts/main.gd` l'interfaccia · `scripts/tavola.gd` la tavola del combattimento
- `scripts/regolamento.gd` regolamento e tabelle in italiano · `scripts/tutorial.gd` il tutorial
- `data/tessere.json` le 100 tessere (uscite e pianta di ogni faccia), estratte dal modulo Tabletop Simulator
- `tests/` controlli automatici: regole, partite giocate da un bot, tutorial completo, screenshot

## Verifica e pubblicazione

A ogni modifica l'azione **Verifica** compila, controlla i glifi dei font, prova le regole, gioca 80 partite automatiche,
percorre tutto il tutorial, fa gli screenshot a varie risoluzioni (anche iPad e telefono) ed esporta la versione web;
i risultati vanno nel ramo `verifica`.
La pubblicazione su GitHub Pages parte solo a mano (Actions → *Pubblica* → *Run workflow*) o con un commit che contiene `[pubblica]`.
