extends Node3D
class_name Vista3D
## Il labirinto in 3D: ogni tessera è costruita dalla sua pianta originale (muri estrusi),
## con pavimento di pietra, elementi delle stanze, pedine in piedi del gruppo e dei mostri.
## Camera: trascina per spostare, rotella/pizzico per lo zoom, tasto destro/due dita per ruotare.

signal cella_toccata(liv: int, xy: Vector2i)

const LATO := 4.0                 # lato di una tessera
const N := 10                     # celle della pianta
const H_MURO := 0.95

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
var mat_muro: StandardMaterial3D
var mat_cima: StandardMaterial3D
var fantasma: Node3D
var segnalini: Node3D
var _seguire = true

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
	mat_pav.albedo_color = Color(0.92, 0.86, 0.8)
	mat_pav.roughness = 0.95
	mat_pav.uv1_scale = Vector3(1, 1, 1)
	mat_pav_corr = mat_pav.duplicate()
	mat_pav_corr.albedo_color = Color(0.72, 0.68, 0.66)
	mat_muro = StandardMaterial3D.new()
	mat_muro.albedo_texture = Risorse.tex("muro")
	mat_muro.albedo_color = Color(0.7, 0.62, 0.58)
	mat_muro.roughness = 1.0
	mat_muro.uv1_triplanar = true
	mat_muro.uv1_scale = Vector3(0.6, 0.6, 0.6)
	mat_cima = StandardMaterial3D.new()
	mat_cima.albedo_color = Color(0.11, 0.08, 0.08)
	mat_cima.roughness = 1.0

func _ambiente() -> void:
	var we = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.45, 0.42)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.05, 0.05)
	env.fog_density = 0.012
	we.environment = env
	add_child(we)
	var sole = DirectionalLight3D.new()
	sole.rotation_degrees = Vector3(-62, 35, 0)
	sole.light_color = Color(0.85, 0.78, 0.72)
	sole.light_energy = 0.45
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
	# pavimento
	var pav = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(LATO, LATO)
	pav.mesh = pm
	pav.material_override = mat_pav if seg.get("tipo", "") != "corridoio" else mat_pav_corr
	n.add_child(pav)
	# muri: un unico blocco per tessera
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st2 = SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in N:
		for c in N:
			if String(g[r])[c] == "1": continue
			var x0 = -LATO / 2 + c * cella
			var z0 = -LATO / 2 + r * cella
			var muro_n = r == 0 or String(g[r - 1])[c] == "1"
			var muro_s = r == N - 1 or String(g[r + 1])[c] == "1"
			var muro_o = c == 0 or String(g[r])[c - 1] == "1"
			var muro_e = c == N - 1 or String(g[r])[c + 1] == "1"
			_blocco(st, st2, x0, z0, cella, H_MURO, muro_n, muro_s, muro_o, muro_e)
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
	var q = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.42 * scala, 0.52 * scala, 0.025)
	q.mesh = bm
	var mq = StandardMaterial3D.new()
	mq.albedo_texture = Risorse.tex(nome_tex)
	mq.albedo_color = Color(0.95, 0.92, 0.9)
	mq.roughness = 0.85
	q.material_override = mq
	q.position.y = 0.05 + 0.26 * scala
	n.add_child(q)
	var cor = MeshInstance3D.new()
	var cb = BoxMesh.new()
	cb.size = Vector3(0.46 * scala, 0.56 * scala, 0.018)
	cor.mesh = cb
	var mc = StandardMaterial3D.new()
	mc.albedo_color = colore
	cor.material_override = mc
	cor.position = q.position + Vector3(0, 0, -0.008)
	n.add_child(cor)
	if etichetta != "":
		var l = Label3D.new()
		l.text = etichetta
		l.font = Risorse.font("Testo")
		l.font_size = 40
		l.pixel_size = 0.004
		l.outline_size = 10
		l.modulate = Color(1, 0.93, 0.8)
		l.outline_modulate = Color(0, 0, 0, 0.85)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position.y = 0.05 + 0.56 * scala
		l.no_depth_test = true
		n.add_child(l)
	n.set_meta("uid", uid)
	return n

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
			var pos = centro + Vector3((col - 1) * 0.62, 0, 0.35 + r * 0.55)
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
			var pos2 = centro + Vector3((col - 1) * 0.62, 0, -0.45 - r * 0.55)
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

func colpo(uid: String) -> void:
	## piccolo sobbalzo della pedina colpita
	if not pedine.has(uid): return
	var n: Node3D = pedine[uid]
	var tw = create_tween()
	var p = n.position
	tw.tween_property(n, "position", p + Vector3(0, 0.18, 0), 0.08)
	tw.tween_property(n, "position", p, 0.14)
