extends Node3D
class_name Vista3D
## Il labirinto in 3D: ogni tessera è costruita dalla sua pianta originale (muri estrusi),
## con pavimento di pietra, elementi delle stanze, pedine in piedi del gruppo e dei mostri.
## Camera: trascina per spostare, rotella/pizzico per lo zoom, tasto destro/due dita per ruotare.

signal cella_toccata(liv: int, xy: Vector2i)

const LATO := 4.0                 # lato di una tessera
const N := 10                     # celle della pianta
const H_MURO := 0.6
const SPESSORE_MURO := 0.07

var motore: Motore
var radice: Node3D
var tessere_nodi = {}            # "liv|x,y" -> Node3D
var pedine = {}                  # uid -> Node3D
var livello_mostrato = 1
var cam: Camera3D
var perno: Node3D
var yaw = -0.6
var pitch = -0.95
var dist = 11.0
var bersaglio_perno = Vector3.ZERO
var luce_torcia: OmniLight3D
var mat_pav: StandardMaterial3D
var mat_pav_corr: StandardMaterial3D
var mat_fondo: StandardMaterial3D
var mat_muro: StandardMaterial3D
var mat_cima: StandardMaterial3D
var fantasma: Node3D
var segnalini: Node3D
var _seguire = true
# combattimento nella stanza: bersagli evidenziati, personaggio di turno, posti liberi
var interazione = {"attivo": false, "evidenziati": {}, "selezionato": "", "attore": "", "posti": [], "in_comb": false}
var nodo_posti: Node3D

func _ready() -> void:
	radice = Node3D.new()
	add_child(radice)
	segnalini = Node3D.new()
	add_child(segnalini)
	_materiali()
	_ambiente()
	perno = Node3D.new()
	add_child(perno)
	cam = Camera3D.new()
	cam.fov = 45
	cam.near = 0.1
	cam.far = 200
	perno.add_child(cam)
	cam.current = true
	_aggiorna_camera()

func _materiali() -> void:
	mat_pav = StandardMaterial3D.new()
	mat_pav.albedo_texture = Risorse.tex("pavimento")
	mat_pav.albedo_color = Color(0.95, 0.9, 0.85)
	mat_pav.roughness = 0.95
	mat_pav.uv1_scale = Vector3(1, 1, 1)
	mat_pav_corr = mat_pav.duplicate()
	mat_fondo = StandardMaterial3D.new()
	mat_fondo.albedo_color = Color(0.06, 0.045, 0.04)
	mat_fondo.roughness = 1.0
	mat_pav_corr.albedo_color = Color(0.78, 0.74, 0.72)
	mat_muro = StandardMaterial3D.new()
	mat_muro.albedo_texture = Risorse.tex("muro")
	mat_muro.albedo_color = Color(0.78, 0.7, 0.66)
	mat_muro.roughness = 1.0
	mat_muro.uv1_triplanar = true
	mat_muro.uv1_scale = Vector3(0.6, 0.6, 0.6)
	mat_cima = StandardMaterial3D.new()
	mat_cima.albedo_texture = Risorse.tex("muro")
	mat_cima.uv1_triplanar = true
	mat_cima.uv1_scale = Vector3(0.8, 0.8, 0.8)
	mat_cima.albedo_color = Color(0.42, 0.36, 0.34)
	mat_cima.roughness = 1.0

func _ambiente() -> void:
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.54, 0.5)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.05, 0.05)
	env.fog_density = 0.006
	we.environment = env
	add_child(we)
	var sole = DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-62, 35, 0)
	sole.light_color = Color(0.85, 0.78, 0.72)
	sole.light_energy = 0.7
	sole.shadow_enabled = false
	add_child(sole)
	luce_torcia = OmniLight3D.new()
	luce_torcia.light_color = Color(1.0, 0.72, 0.45)
	luce_torcia.light_energy = 1.4
	luce_torcia.omni_range = 9.0
	luce_torcia.omni_attenuation = 1.2
	luce_torcia.position = Vector3(0, 2.4, 0)
	add_child(luce_torcia)

# --------------------------------------------------------------------------------------------
# Camera
# --------------------------------------------------------------------------------------------
func _aggiorna_camera() -> void:
	pitch = clamp(pitch, -1.45, -0.25)
	dist = clamp(dist, 3.5, 60.0)
	perno.rotation = Vector3(0, yaw, 0)
	var dir = Vector3(0, 0, 1).rotated(Vector3.RIGHT, pitch)
	cam.position = dir * dist
	cam.look_at(perno.global_position, Vector3.UP)

func _process(delta: float) -> void:
	if _seguire:
		perno.position = perno.position.lerp(bersaglio_perno, clamp(delta * 4.0, 0.0, 1.0))
		_aggiorna_camera()
	luce_torcia.position = luce_torcia.position.lerp(bersaglio_perno + Vector3(0, 2.4, 0), clamp(delta * 3.0, 0.0, 1.0))

func centra_su(liv: int, k: String) -> void:
	var xy = MotoreBase.da_chiave(k)
	bersaglio_perno = Vector3(xy.x * LATO, 0, xy.y * LATO)
	_seguire = true

func sposta(delta_schermo: Vector2) -> void:
	_seguire = false
	var f = dist / 600.0
	var dx = Vector3(cos(yaw), 0, -sin(yaw))
	var dz = Vector3(sin(yaw), 0, cos(yaw))
	perno.position -= (dx * delta_schermo.x + dz * delta_schermo.y) * f
	bersaglio_perno = perno.position
	_aggiorna_camera()

func ruota(dyaw: float, dpitch: float) -> void:
	yaw += dyaw
	pitch += dpitch
	_aggiorna_camera()

func zoom(fattore: float) -> void:
	dist *= fattore
	_aggiorna_camera()

func ricentra() -> void:
	_seguire = true

## Punto del pavimento sotto una posizione dello schermo (coordinate della SubViewport)
func cella_sotto(pos: Vector2) -> Vector2i:
	var o = cam.project_ray_origin(pos)
	var d = cam.project_ray_normal(pos)
	if absf(d.y) < 0.0001: return Vector2i(99999, 99999)
	var t = -o.y / d.y
	var p = o + d * t
	return Vector2i(int(round(p.x / LATO)), int(round(p.z / LATO)))

# --------------------------------------------------------------------------------------------
# Costruzione del labirinto
# --------------------------------------------------------------------------------------------
func ricostruisci() -> void:
	if motore == null or motore.s.is_empty(): return
	var liv = int(motore.s["pos"]["liv"])
	if liv != livello_mostrato:
		livello_mostrato = liv
		for k in tessere_nodi:
			tessere_nodi[k].queue_free()
		tessere_nodi.clear()
	var segs: Dictionary = motore.mappa(liv)["seg"]
	for k in segs:
		var chiave_n = "%d|%s" % [liv, k]
		var seg: Dictionary = segs[k]
		var firma = "%s|%s|%s|%s" % [seg.get("t", -1), seg.get("rot", 0), seg.get("uscite", ""), seg.get("hellgate", false)]
		if tessere_nodi.has(chiave_n):
			if tessere_nodi[chiave_n].get_meta("firma", "") == firma:
				continue
			tessere_nodi[chiave_n].queue_free()
		var n = _costruisci_tessera(seg)
		n.set_meta("firma", firma)
		radice.add_child(n)
		tessere_nodi[chiave_n] = n
	aggiorna_pedine()

func _griglia(seg: Dictionary) -> Array:
	if seg.get("tipo", "") == "portale":
		var g = []
		for r in N:
			var riga = ""
			for c in N:
				riga += "1" if (c >= 3 and c <= 6 and r <= 6) else "0"
			g.append(riga)
		return g
	var f = motore.faccia(int(seg["t"]), seg["lato"])
	var gr: Array = f.get("griglia", [])
	if gr.size() != N:
		gr = []
		for r in N: gr.append("1111111111")
	# rotazione della pianta (in senso orario) e lati chiusi
	var rot = int(seg.get("rot", 0)) % 4
	var out = []
	for r in N:
		var riga2 = ""
		for c in N:
			var sr = r
			var sc = c
			for i in rot:
				var tmp = sr
				sr = N - 1 - sc
				sc = tmp
			riga2 += String(gr[sr])[sc]
		out.append(riga2)
	# porte sigillate (Serratura) e lati impraticabili: chiude la fascia esterna
	for d in seg.get("chiuse", []):
		out = _chiudi_lato(out, int(d))
	for d in 4:
		if String(seg["uscite"])[d] == "W":
			out = _chiudi_lato(out, d)
	return out

func _chiudi_lato(g: Array, d: int) -> Array:
	var out = []
	for r in N:
		var riga = ""
		for c in N:
			var ch: String = String(g[r])[c]
			if (d == 0 and r == 0) or (d == 2 and r == N - 1) or (d == 3 and c == 0) or (d == 1 and c == N - 1):
				ch = "0"
			riga += ch
		out.append(riga)
	return out

func _costruisci_tessera(seg: Dictionary) -> Node3D:
	var n = Node3D.new()
	n.position = Vector3(float(seg["x"]) * LATO, 0, float(seg["y"]) * LATO)
	var g = _griglia(seg)
	var cella = LATO / N
	if seg.get("tipo", "") != "corridoio" and seg.get("tipo", "") != "portale":
		g = _allarga_stanza(g)
	# fondo scuro della tessera (la roccia fuori dalle stanze)
	var fondo = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(LATO, LATO)
	fondo.mesh = pm
	fondo.material_override = mat_fondo
	fondo.position.y = -0.005
	n.add_child(fondo)
	# pavimento: solo le celle calpestabili, con la texture continua su tutta la tessera
	var sp = SurfaceTool.new()
	sp.begin(Mesh.PRIMITIVE_TRIANGLES)
	# muri sottili lungo il bordo delle celle calpestabili
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st2 = SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	var usc: String = String(seg.get("uscite", "WWWW"))
	for d in seg.get("chiuse", []):
		usc = usc.substr(0, int(d)) + "W" + usc.substr(int(d) + 1)
	for r in N:
		for c in N:
			if String(g[r])[c] != "1": continue
			var x0 = -LATO / 2 + c * cella
			var z0 = -LATO / 2 + r * cella
			_pavimento(sp, x0, z0, cella)
			# nord, est, sud, ovest
			var lati = [[r == 0, r > 0 and String(g[r - 1])[c] != "1", 0, c],
				[c == N - 1, c < N - 1 and String(g[r])[c + 1] != "1", 1, r],
				[r == N - 1, r < N - 1 and String(g[r + 1])[c] != "1", 2, c],
				[c == 0, c > 0 and String(g[r])[c - 1] != "1", 3, r]]
			for L in lati:
				var muro = L[1]
				if L[0]:
					muro = not _apertura(usc[L[2]], int(L[3]))
				if muro:
					_muro_sottile(st, st2, x0, z0, cella, int(L[2]), L[0])
	var pav = MeshInstance3D.new()
	sp.generate_normals()
	pav.mesh = sp.commit()
	if pav.mesh != null and pav.mesh.get_surface_count() > 0:
		pav.mesh.surface_set_material(0, mat_pav if seg.get("tipo", "") != "corridoio" else mat_pav_corr)
	n.add_child(pav)
	var mw = MeshInstance3D.new()
	st.generate_normals()
	mw.mesh = st.commit()
	if mw.mesh != null and mw.mesh.get_surface_count() > 0:
		mw.mesh.surface_set_material(0, mat_muro)
	n.add_child(mw)
	var mt = MeshInstance3D.new()
	st2.generate_normals()
	mt.mesh = st2.commit()
	if mt.mesh != null and mt.mesh.get_surface_count() > 0:
		mt.mesh.surface_set_material(0, mat_cima)
	n.add_child(mt)
	# elementi
	var el: String = seg.get("elemento", "")
	if seg.get("tipo", "") == "portale":
		_portale(n)
	elif seg.get("hellgate", false):
		_cartello(n, "hellgate", Vector3(0, 0, -0.6), 1.9, Color(1.0, 0.3, 0.1))
		var l = OmniLight3D.new()
		l.light_color = Color(1.0, 0.35, 0.15)
		l.light_energy = 1.3
		l.omni_range = 5.0
		l.position = Vector3(0, 1.5, 0)
		n.add_child(l)
	elif el == "scala":
		_scala(n)
	elif el != "":
		_cartello(n, "f_" + el, Vector3(0, 0, 0), 0.85, Color(0.8, 0.7, 0.5))
	return n

## Le stanze occupano più spazio della pianta originale: il blocco centrale si allarga di una cella
## per lato (senza toccare il bordo della tessera), così c'è posto per il combattimento.
func _allarga_stanza(g: Array) -> Array:
	var nucleo = {}
	for r in range(1, N - 1):
		for c in range(1, N - 1):
			var pieno = true
			for dr in [-1, 0, 1]:
				for dc in [-1, 0, 1]:
					if String(g[r + dr])[c + dc] != "1": pieno = false
			if pieno: nucleo[Vector2i(c, r)] = true
	if nucleo.is_empty(): return g
	var out = []
	for r in N:
		var riga = ""
		for c in N:
			var ch: String = String(g[r])[c]
			if ch != "1" and r >= 1 and r <= N - 2 and c >= 1 and c <= N - 2:
				for dr in [-2, -1, 0, 1, 2]:
					for dc in [-2, -1, 0, 1, 2]:
						if nucleo.has(Vector2i(c + dc, r + dr)): ch = "1"
			riga += ch
		out.append(riga)
	return out

## Sul bordo della tessera si passa solo dove c'è un'uscita: porta (celle 4-5) o corridoio (3-6)
func _apertura(tipo: String, i: int) -> bool:
	if tipo == "*": tipo = "C"
	if tipo == "D": return i >= 4 and i <= 5
	if tipo == "C": return i >= 3 and i <= 6
	return false

func _pavimento(st: SurfaceTool, x: float, z: float, s: float) -> void:
	var u0 = (x + LATO / 2) / LATO
	var v0 = (z + LATO / 2) / LATO
	var du = s / LATO
	var a = [Vector3(x, 0, z), Vector3(x + s, 0, z), Vector3(x + s, 0, z + s), Vector3(x, 0, z + s)]
	var uv = [Vector2(u0, v0), Vector2(u0 + du, v0), Vector2(u0 + du, v0 + du), Vector2(u0, v0 + du)]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_normal(Vector3.UP)
		st.set_uv(uv[k])
		st.add_vertex(a[k])

## Un tratto di muro sottile sul lato d (0 N, 1 E, 2 S, 3 O) di una cella, costruito verso l'esterno
func _muro_sottile(st: SurfaceTool, cima: SurfaceTool, x: float, z: float, s: float, d: int, interno: bool = false) -> void:
	var t = SPESSORE_MURO
	var x0 = x - t
	var x1 = x + s + t
	var z0 = z - t
	var z1 = z + s + t
	match d:
		0: z1 = z; z0 = z - t
		2: z0 = z + s; z1 = z + s + t
		1: x0 = x + s; x1 = x + s + t
		3: x1 = x; x0 = x - t
	if interno:
		# sul bordo della tessera il muro sta dentro la cella, per non invadere la tessera vicina
		match d:
			0: z0 = z; z1 = z + t
			2: z0 = z + s - t; z1 = z + s
			1: x0 = x + s - t; x1 = x + s
			3: x0 = x; x1 = x + t
	var h = H_MURO
	_quad(cima, Vector3(x0, h, z0), Vector3(x1, h, z0), Vector3(x1, h, z1), Vector3(x0, h, z1), 0.3)
	_quad(st, Vector3(x1, h, z0), Vector3(x0, h, z0), Vector3(x0, 0, z0), Vector3(x1, 0, z0), 0.5)
	_quad(st, Vector3(x0, h, z1), Vector3(x1, h, z1), Vector3(x1, 0, z1), Vector3(x0, 0, z1), 0.5)
	_quad(st, Vector3(x0, h, z0), Vector3(x0, h, z1), Vector3(x0, 0, z1), Vector3(x0, 0, z0), 0.5)
	_quad(st, Vector3(x1, h, z1), Vector3(x1, h, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), 0.5)

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv_scala: float) -> void:
	st.set_uv(Vector2(0, 0) * uv_scala); st.add_vertex(a)
	st.set_uv(Vector2(1, 0) * uv_scala); st.add_vertex(b)
	st.set_uv(Vector2(1, 1) * uv_scala); st.add_vertex(c)
	st.set_uv(Vector2(0, 0) * uv_scala); st.add_vertex(a)
	st.set_uv(Vector2(1, 1) * uv_scala); st.add_vertex(c)
	st.set_uv(Vector2(0, 1) * uv_scala); st.add_vertex(d)

func _blocco(st: SurfaceTool, cima: SurfaceTool, x: float, z: float, s: float, h: float, fn: bool, fs: bool, fo: bool, fe: bool) -> void:
	var x1 = x + s
	var z1 = z + s
	_quad(cima, Vector3(x, h, z), Vector3(x1, h, z), Vector3(x1, h, z1), Vector3(x, h, z1), 1.0)
	if fn: _quad(st, Vector3(x1, h, z), Vector3(x, h, z), Vector3(x, 0, z), Vector3(x1, 0, z), 0.5)
	if fs: _quad(st, Vector3(x, h, z1), Vector3(x1, h, z1), Vector3(x1, 0, z1), Vector3(x, 0, z1), 0.5)
	if fo: _quad(st, Vector3(x, h, z), Vector3(x, h, z1), Vector3(x, 0, z1), Vector3(x, 0, z), 0.5)
	if fe: _quad(st, Vector3(x1, h, z1), Vector3(x1, h, z), Vector3(x1, 0, z), Vector3(x1, 0, z1), 0.5)

## Un'illustrazione in piedi su un piedistallo (elementi della stanza, Porta dell'Inferno)
func _cartello(padre: Node3D, nome_tex: String, pos: Vector3, alto: float, bordo: Color) -> void:
	var base = MeshInstance3D.new()
	var cil = CylinderMesh.new()
	cil.top_radius = alto * 0.42
	cil.bottom_radius = alto * 0.48
	cil.height = 0.08
	base.mesh = cil
	var mb = StandardMaterial3D.new()
	mb.albedo_color = Color(0.2, 0.15, 0.12)
	base.material_override = mb
	base.position = pos + Vector3(0, 0.04, 0)
	padre.add_child(base)
	var q = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(alto * 0.82, alto * 0.82, 0.03)
	q.mesh = bm
	var mq = StandardMaterial3D.new()
	mq.albedo_texture = Risorse.tex(nome_tex)
	mq.albedo_color = Color(0.95, 0.92, 0.88)
	mq.roughness = 0.9
	q.material_override = mq
	q.position = pos + Vector3(0, 0.08 + alto * 0.41, 0)
	q.set_meta("cartello", true)
	padre.add_child(q)
	var cornice = MeshInstance3D.new()
	var cm = BoxMesh.new()
	cm.size = Vector3(alto * 0.9, alto * 0.9, 0.02)
	cornice.mesh = cm
	var mc = StandardMaterial3D.new()
	mc.albedo_color = bordo.darkened(0.4)
	mc.metallic = 0.4
	mc.roughness = 0.5
	cornice.material_override = mc
	cornice.position = q.position + Vector3(0, 0, -0.02)
	padre.add_child(cornice)

func _scala(padre: Node3D) -> void:
	var m = StandardMaterial3D.new()
	m.albedo_texture = Risorse.tex("muro")
	m.albedo_color = Color(0.6, 0.55, 0.52)
	m.uv1_triplanar = true
	for i in 5:
		var b = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(1.1, 0.12 * (i + 1), 0.24)
		b.mesh = bm
		b.material_override = m
		b.position = Vector3(0.6, 0.06 * (i + 1), 0.6 - i * 0.24)
		padre.add_child(b)
	_cartello(padre, "f_scala", Vector3(-0.7, 0, 0.1), 0.85, Color(0.8, 0.7, 0.5))

func _portale(padre: Node3D) -> void:
	var m = StandardMaterial3D.new()
	m.albedo_texture = Risorse.tex("muro")
	m.albedo_color = Color(0.5, 0.4, 0.38)
	m.uv1_triplanar = true
	for x in [-0.95, 0.95]:
		var p = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.4, 2.0, 0.4)
		p.mesh = bm
		p.material_override = m
		p.position = Vector3(x, 1.0, 1.4)
		padre.add_child(p)
	var arch = MeshInstance3D.new()
	var am = BoxMesh.new()
	am.size = Vector3(2.4, 0.4, 0.5)
	arch.mesh = am
	arch.material_override = m
	arch.position = Vector3(0, 2.1, 1.4)
	padre.add_child(arch)
	_cartello(padre, "gateway", Vector3(0, 0, 1.75), 1.6, Color(0.6, 0.5, 0.3))
	for x in [-1.3, 1.3]:
		var fuoco = OmniLight3D.new()
		fuoco.light_color = Color(1, 0.55, 0.25)
		fuoco.light_energy = 0.8
		fuoco.omni_range = 3.0
		fuoco.position = Vector3(x, 1.2, 1.2)
		padre.add_child(fuoco)

# --------------------------------------------------------------------------------------------
# Anteprima di una tessera da orientare
# --------------------------------------------------------------------------------------------
func mostra_anteprima(liv: int, k: String, t: int, lato: String, rot: int) -> void:
	togli_anteprima()
	var xy = MotoreBase.da_chiave(k)
	var seg = motore.nuovo_segmento(t, lato, rot, xy)
	fantasma = _costruisci_tessera(seg)
	for c in fantasma.get_children():
		if c is MeshInstance3D:
			var mm = StandardMaterial3D.new()
			mm.albedo_color = Color(0.95, 0.75, 0.35, 0.45)
			mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			c.material_override = mm
	radice.add_child(fantasma)

func togli_anteprima() -> void:
	if fantasma != null and is_instance_valid(fantasma):
		fantasma.queue_free()
	fantasma = null

## Frecce luminose sulle uscite percorribili
func mostra_uscite(direzioni: Array) -> void:
	for c in segnalini.get_children():
		c.queue_free()
	if motore == null or motore.s.is_empty(): return
	var xy = MotoreBase.da_chiave(motore.s["pos"]["xy"])
	for d in direzioni:
		var v: Vector2i = Dati.VETTORI[int(d)]
		var m = MeshInstance3D.new()
		var pm = PrismMesh.new()
		pm.size = Vector3(0.7, 0.7, 0.06)
		m.mesh = pm
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.78, 0.35, 0.85)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.55, 0.15)
		mat.emission_energy_multiplier = 0.6
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.material_override = mat
		var centro = Vector3((xy.x + v.x * 0.5) * LATO, 0.08, (xy.y + v.y * 0.5) * LATO)
		m.position = centro
		m.rotation = Vector3(-PI / 2, -atan2(float(v.x), float(-v.y)), 0)
		segnalini.add_child(m)

# --------------------------------------------------------------------------------------------
# Pedine in piedi
# --------------------------------------------------------------------------------------------
func _pedina(uid: String, nome_tex: String, scala: float, colore: Color, etichetta: String) -> Node3D:
	var n = Node3D.new()
	var base = MeshInstance3D.new()
	var cil = CylinderMesh.new()
	cil.top_radius = 0.2 * scala
	cil.bottom_radius = 0.22 * scala
	cil.height = 0.05
	base.mesh = cil
	var mb = StandardMaterial3D.new()
	mb.albedo_color = colore
	mb.roughness = 0.6
	base.material_override = mb
	base.position.y = 0.025
	n.add_child(base)
	var an = MeshInstance3D.new()
	an.name = "Anello"
	var tor = TorusMesh.new()
	tor.inner_radius = 0.27 * scala
	tor.outer_radius = 0.33 * scala
	an.mesh = tor
	var ma = StandardMaterial3D.new()
	ma.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ma.emission_enabled = true
	an.material_override = ma
	an.position.y = 0.03
	an.visible = false
	n.add_child(an)
	# la carta del personaggio sta in piedi, ferma sul tavolo (non segue la camera)
	var carta = Node3D.new()
	carta.name = "Carta"
	carta.position.y = 0.05
	n.add_child(carta)
	# standee di cartoncino sagomato ad arco, con spessore: il ritratto si vede da entrambe le facce
	var w = 0.5 * scala
	var hh = 0.66 * scala
	var sp = 0.04
	var bordo = 0.03 * scala
	var est = _profilo_arco(w, hh, 0.0)
	var inn = _profilo_arco(w - 2.0 * bordo, hh - bordo, bordo)
	var mq = StandardMaterial3D.new()
	mq.albedo_texture = Risorse.tex(nome_tex)
	mq.albedo_color = Color(0.86, 0.84, 0.82)
	mq.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mc = StandardMaterial3D.new()
	mc.albedo_color = colore
	mc.roughness = 0.7
	var mcart = StandardMaterial3D.new()
	mcart.albedo_color = Color(0.62, 0.52, 0.38)
	mcart.roughness = 0.95
	for m in [mq, mc, mcart]:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var facce = MeshInstance3D.new()
	facce.mesh = _mesh_facce(inn, hh, sp)
	facce.material_override = mq
	carta.add_child(facce)
	var cornice = MeshInstance3D.new()
	cornice.mesh = _mesh_cornice(est, inn, sp)
	cornice.material_override = mc
	carta.add_child(cornice)
	var fianco = MeshInstance3D.new()
	fianco.mesh = _mesh_fianco(est, sp)
	fianco.material_override = mcart
	carta.add_child(fianco)
	if etichetta != "":
		for lato in [1.0, -1.0]:
			var l = Label3D.new()
			l.text = etichetta
			l.font = Risorse.font("Testo")
			l.font_size = 40
			l.pixel_size = 0.0028
			l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			l.outline_size = 10
			l.modulate = Color(1, 0.93, 0.8)
			l.outline_modulate = Color(0, 0, 0, 0.9)
			l.double_sided = false
			l.position = Vector3(0, bordo + 0.04 * scala, lato * (sp / 2.0 + 0.004))
			if lato < 0: l.rotation.y = PI
			l.render_priority = 2
			carta.add_child(l)
	n.set_meta("uid", uid)
	return n

## contorno dello standee: rettangolo con la cima ad arco (punti in senso antiorario, base in basso)
func _profilo_arco(w: float, h: float, y0: float) -> Array:
	var r = w / 2.0
	var pts = [Vector2(-r, y0), Vector2(r, y0)]
	var seg = 14
	for i in seg + 1:
		var ang = PI * float(i) / float(seg)
		pts.append(Vector2(cos(ang) * r, h - r + sin(ang) * r))
	return pts

func _uv_ritratto(p: Vector2, h: float, dietro: bool) -> Vector2:
	# il ritratto copre tutta l'altezza; dietro è specchiato perché si legga dritto
	var u = 0.5 + p.x / h
	if dietro: u = 0.5 - p.x / h
	return Vector2(u, 1.0 - p.y / h)

func _mesh_facce(pts: Array, h: float, sp: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c = Vector2.ZERO
	for p in pts: c += p
	c /= float(pts.size())
	for lato in [1.0, -1.0]:
		var z = lato * sp / 2.0
		var dietro = lato < 0
		for i in pts.size():
			var p1: Vector2 = pts[i]
			var p2: Vector2 = pts[(i + 1) % pts.size()]
			var tri = [c, p1, p2] if not dietro else [c, p2, p1]
			for q in tri:
				st.set_normal(Vector3(0, 0, lato))
				st.set_uv(_uv_ritratto(q, h, dietro))
				st.add_vertex(Vector3(q.x, q.y, z))
	return st.commit()

func _mesh_cornice(est: Array, inn: Array, sp: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for lato in [1.0, -1.0]:
		var z = lato * (sp / 2.0 + 0.0005)
		for i in est.size():
			var j = (i + 1) % est.size()
			var a: Vector2 = est[i]
			var b: Vector2 = est[j]
			var c: Vector2 = inn[j]
			var d: Vector2 = inn[i]
			var tri = [a, b, c, a, c, d] if lato > 0 else [a, c, b, a, d, c]
			for q in tri:
				st.set_normal(Vector3(0, 0, lato))
				st.add_vertex(Vector3(q.x, q.y, z))
	return st.commit()

func _mesh_fianco(pts: Array, sp: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var d = (b - a)
		var nrm = Vector3(d.y, -d.x, 0).normalized()
		var v = [Vector3(a.x, a.y, sp / 2.0), Vector3(b.x, b.y, sp / 2.0), Vector3(b.x, b.y, -sp / 2.0), Vector3(a.x, a.y, -sp / 2.0)]
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_normal(nrm)
			st.add_vertex(v[k])
	return st.commit()

func aggiorna_pedine() -> void:
	if motore == null or motore.s.is_empty(): return
	var vivi = {}
	var liv = int(motore.s["pos"]["liv"])
	var xy = MotoreBase.da_chiave(motore.s["pos"]["xy"])
	var centro = Vector3(xy.x * LATO, 0, xy.y * LATO)
	var c: Dictionary = motore.s.get("comb", {})
	var in_comb = not c.is_empty() and c.get("esito", "") == ""
	# gruppo: in formazione secondo l'ordine di marcia
	var ord: Array = motore.ordine_gruppo() if in_comb else motore.s["ordine"]
	for r in ord.size():
		for col in 3:
			var uid: String = ord[r][col]
			if uid == "": continue
			var u = motore.unita(uid)
			if u.is_empty(): continue
			var pos = centro + Vector3((col - 1) * 0.72, 0, 0.4 + r * 0.64)
			if not in_comb: pos.z -= 0.1
			_metti_pedina(uid, u.get("ritratto", ""), pos, 1.0, Color(0.55, 0.45, 0.25), u.get("nome", ""), 0.0, vivi)
	# mostri in combattimento o nell'incontro
	var mostri_ord: Array = []
	if in_comb:
		mostri_ord = c["ordine_m"]
	elif not motore.s.get("incontro", {}).is_empty():
		var lista: Array = motore.s["incontro"]["mostri"].keys()
		var o2 = [["", "", ""], ["", "", ""], ["", "", ""]]
		for i in lista.size():
			if i < 9: o2[int(i / 3)][i % 3] = lista[i]
		mostri_ord = o2
	for r in mostri_ord.size():
		for col in 3:
			var uid2: String = mostri_ord[r][col]
			if uid2 == "": continue
			var nome_tex = "hellgate"
			var nm = "Porta dell'Inferno"
			if uid2 != "hellgate":
				var u2 = motore.unita(uid2)
				if u2.is_empty(): continue
				nome_tex = u2.get("ritratto", "")
				nm = u2.get("nome", "")
			var pos2 = centro + Vector3((col - 1) * 0.72, 0, -0.5 - r * 0.64)
			_metti_pedina(uid2, nome_tex, pos2, 1.15 if uid2 != "hellgate" else 1.6, Color(0.45, 0.08, 0.08), nm, PI, vivi)
	# mostri lasciati in altri segmenti
	for k in motore.mappa(liv)["seg"]:
		var seg: Dictionary = motore.mappa(liv)["seg"][k]
		if k == motore.s["pos"]["xy"]: continue
		var i = 0
		for m in seg.get("mostri", []):
			var sxy = MotoreBase.da_chiave(k)
			var p3 = Vector3(sxy.x * LATO + (i % 3 - 1) * 0.6, 0, sxy.y * LATO + int(i / 3) * 0.5)
			_metti_pedina("fermo|%s|%d" % [k, i], m.get("ritratto", ""), p3, 1.0, Color(0.4, 0.1, 0.1), "", 0.0, vivi)
			i += 1
	for k in pedine.keys():
		if not vivi.has(k):
			pedine[k].queue_free()
			pedine.erase(k)
	luce_torcia.visible = true
	# posti liberi dove spostare il personaggio scelto (riorganizzazione / ordine di marcia)
	if nodo_posti == null:
		nodo_posti = Node3D.new()
		radice.add_child(nodo_posti)
	for ch in nodo_posti.get_children(): ch.queue_free()
	for p in interazione["posti"]:
		var pp = posto_3d(p.x, p.y)
		var disco = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.24
		cm.bottom_radius = 0.24
		cm.height = 0.02
		disco.mesh = cm
		var md = StandardMaterial3D.new()
		md.albedo_color = Color(1.0, 0.8, 0.3, 0.55)
		md.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		md.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		disco.material_override = md
		disco.position = pp + Vector3(0, 0.02, 0)
		nodo_posti.add_child(disco)
		var lq = Label3D.new()
		lq.text = "Qui"
		lq.font = Risorse.font("Testo")
		lq.font_size = 48
		lq.pixel_size = 0.004
		lq.outline_size = 10
		lq.modulate = Color(1, 0.9, 0.6)
		lq.rotation.x = -PI / 2
		lq.position = pp + Vector3(0, 0.04, 0)
		nodo_posti.add_child(lq)

## Posizione sul tavolo di un posto dell'ordine di marcia del gruppo (colonna, fila)
func posto_3d(col: int, riga: int) -> Vector3:
	var xy = MotoreBase.da_chiave(motore.s["pos"]["xy"])
	var centro = Vector3(xy.x * LATO, 0, xy.y * LATO)
	var p = centro + Vector3((col - 1) * 0.72, 0, 0.4 + riga * 0.64)
	if not interazione["in_comb"]: p.z -= 0.1
	return p

## Pedina sotto un punto dello schermo (la più vicina alla camera), "" se nessuna
func pedina_sotto(pos: Vector2) -> String:
	var migliore = ""
	var dist_min = INF
	for uid in pedine:
		if String(uid).begins_with("fermo"): continue
		var n: Node3D = pedine[uid]
		if not is_instance_valid(n): continue
		var sc = float(n.get_meta("scala", 1.0))
		var base: Vector3 = n.get_meta("pos", n.position)
		if cam.is_position_behind(base): continue
		var p0 = cam.unproject_position(base)
		var p1 = cam.unproject_position(base + Vector3(0, 0.7 * sc, 0))
		var raggio = cam.unproject_position(base).distance_to(cam.unproject_position(base + cam.global_transform.basis.x * 0.28 * sc))
		var top = minf(p0.y, p1.y) - 4
		var bot = maxf(p0.y, p1.y) + raggio * 0.5
		var cx = (p0.x + p1.x) / 2.0
		if pos.y >= top and pos.y <= bot and absf(pos.x - cx) <= raggio + 4:
			var d = cam.global_position.distance_to(base)
			if d < dist_min:
				dist_min = d
				migliore = uid
	return migliore

## Posto libero sotto un punto dello schermo, (-1,-1) se nessuno
func posto_sotto(pos: Vector2) -> Vector2i:
	for p in interazione["posti"]:
		var c = posto_3d(p.x, p.y)
		var sp = cam.unproject_position(c)
		var r = sp.distance_to(cam.unproject_position(c + cam.global_transform.basis.x * 0.28))
		if pos.distance_to(sp) <= r + 6: return p
	return Vector2i(-1, -1)

## Avvicina la camera alla stanza del combattimento
func inquadra_stanza() -> void:
	centra_su(int(motore.s["pos"]["liv"]), motore.s["pos"]["xy"])
	dist = 7.0
	pitch = -0.95
	_aggiorna_camera()

func _metti_pedina(uid: String, nome_tex: String, pos: Vector3, scala: float, colore: Color, etichetta: String, rot_y: float, vivi: Dictionary) -> void:
	vivi[uid] = true
	var n: Node3D
	if pedine.has(uid) and is_instance_valid(pedine[uid]):
		n = pedine[uid]
		var tw = create_tween()
		tw.tween_property(n, "position", pos, 0.45).set_trans(Tween.TRANS_SINE)
	else:
		n = _pedina(uid, nome_tex, scala, colore, etichetta)
		n.position = pos
		radice.add_child(n)
		pedine[uid] = n
	n.rotation.y = rot_y
	n.set_meta("scala", scala)
	n.set_meta("pos", pos)
	# nome (e Punti Ferita durante combattimenti e incontri) su entrambe le facce
	var testo = etichetta
	if interazione["attivo"] and uid != "hellgate" and not uid.begins_with("fermo"):
		var u = motore.unita(uid)
		if not u.is_empty():
			testo = "%s\n%d/%d PF" % [etichetta, motore.pf_residui(u), int(u.get("pf_max", 0)) + int(u.get("pf_armatura", 0))]
	var carta = n.get_node_or_null("Carta")
	if carta:
		for ch in carta.get_children():
			if ch is Label3D: ch.text = testo
	# anello sul tavolo: dorato = bersaglio valido, azzurro = di turno, bianco = selezionato
	var an: MeshInstance3D = n.get_node_or_null("Anello")
	if an:
		var col_an = Color(0, 0, 0, 0)
		if interazione["attivo"]:
			if interazione["selezionato"] == uid: col_an = Color(1, 1, 1)
			elif interazione["evidenziati"].has(uid): col_an = Color(1.0, 0.78, 0.2)
			elif interazione["attore"] == uid: col_an = Color(0.35, 0.8, 1.0)
		an.visible = col_an.a > 0
		if an.visible:
			(an.material_override as StandardMaterial3D).albedo_color = col_an
			(an.material_override as StandardMaterial3D).emission = col_an * 0.6

func colpo(uid: String) -> void:
	## piccolo sobbalzo della pedina colpita
	if not pedine.has(uid): return
	var n: Node3D = pedine[uid]
	var tw = create_tween()
	var p = n.position
	tw.tween_property(n, "position", p + Vector3(0, 0.18, 0), 0.08)
	tw.tween_property(n, "position", p, 0.14)
