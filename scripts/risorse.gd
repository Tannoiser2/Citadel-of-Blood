extends RefCounted
class_name Risorse
## Immagini e font del gioco. Se un'immagine manca, ne disegna una provvisoria (mai quadratini).

static var _cache = {}
static var _font = {}

const COL_ORO := Color(0.86, 0.71, 0.42)
const COL_SANGUE := Color(0.55, 0.06, 0.07)
const COL_SANGUE_SCURO := Color(0.24, 0.03, 0.04)
const COL_PERGAMENA := Color(0.93, 0.86, 0.72)
const COL_INCHIOSTRO := Color(0.16, 0.1, 0.07)
const COL_FONDO := Color(0.07, 0.05, 0.05)
const COL_PIETRA := Color(0.18, 0.15, 0.14)

static func font(nome: String) -> Font:
	if _font.has(nome):
		return _font[nome]
	var f: Font = null
	var p = "res://assets/font/%s.ttf" % nome
	if ResourceLoader.exists(p):
		f = load(p)
	if f == null:
		f = ThemeDB.fallback_font
	_font[nome] = f
	return f

static func font_grassetto() -> Font:
	if _font.has("_grassetto"):
		return _font["_grassetto"]
	var fv = FontVariation.new()
	fv.base_font = font("Testo")
	fv.variation_opentype = {"wght": 700}
	_font["_grassetto"] = fv
	return fv

## Texture per nome: cerca in assets/ritratti, assets/texture, assets/ui (webp, png, jpg)
static func tex(nome: String) -> Texture2D:
	if _cache.has(nome):
		return _cache[nome]
	var t: Texture2D = null
	for cartella in ["ritratti", "texture", "ui", "elementi"]:
		for est in ["webp", "png", "jpg"]:
			var p = "res://assets/%s/%s.%s" % [cartella, nome, est]
			if ResourceLoader.exists(p):
				t = load(p)
				break
		if t != null: break
	if t == null:
		t = _provvisoria(nome)
	_cache[nome] = t
	return t

static func esiste(nome: String) -> bool:
	for cartella in ["ritratti", "texture", "ui", "elementi"]:
		for est in ["webp", "png", "jpg"]:
			if ResourceLoader.exists("res://assets/%s/%s.%s" % [cartella, nome, est]):
				return true
	return false

static func _provvisoria(nome: String) -> Texture2D:
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var h = absi(nome.hash())
	var c1 = Color.from_hsv(float(h % 360) / 360.0, 0.45, 0.32)
	var c2 = Color.from_hsv(float((h / 7) % 360) / 360.0, 0.35, 0.16)
	for y in 128:
		for x in 128:
			var t = float(y) / 127.0
			var c = c1.lerp(c2, t)
			var dx = x - 64
			var dy = y - 52
			if dx * dx + dy * dy < 26 * 26 or (y > 80 and absi(dx) < 34 + (y - 80) / 2):
				c = c.lightened(0.22)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

static func box(fondo: Color, bordo: Color, spessore: int = 2, raggio: int = 6, margine: int = 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = bordo
	s.set_border_width_all(spessore)
	s.set_corner_radius_all(raggio)
	s.content_margin_left = margine
	s.content_margin_right = margine
	s.content_margin_top = margine * 0.7
	s.content_margin_bottom = margine * 0.7
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 4
	return s

static func tema() -> Theme:
	var t = Theme.new()
	t.default_font = font("Testo")
	t.default_font_size = 17
	t.set_color("font_color", "Label", COL_PERGAMENA)
	t.set_color("font_color", "RichTextLabel", COL_PERGAMENA)
	t.set_color("default_color", "RichTextLabel", COL_PERGAMENA)
	t.set_font("bold_font", "RichTextLabel", font_grassetto())
	t.set_font("normal_font", "RichTextLabel", font("Testo"))
	t.set_stylebox("panel", "Panel", box(Color(0.08, 0.05, 0.05, 0.92), Color(0.5, 0.36, 0.18), 2, 8))
	t.set_stylebox("panel", "PanelContainer", box(Color(0.08, 0.05, 0.05, 0.92), Color(0.5, 0.36, 0.18), 2, 8))
	var b_n = box(Color(0.33, 0.05, 0.06), Color(0.72, 0.55, 0.28), 2, 6, 12)
	var b_h = box(Color(0.47, 0.08, 0.08), Color(0.95, 0.78, 0.45), 2, 6, 12)
	var b_p = box(Color(0.22, 0.03, 0.04), Color(0.95, 0.78, 0.45), 2, 6, 12)
	var b_d = box(Color(0.18, 0.13, 0.12), Color(0.35, 0.28, 0.2), 1, 6, 12)
	var b_f = box(Color(0.47, 0.08, 0.08), Color(1, 0.9, 0.55), 3, 6, 12)
	t.set_stylebox("normal", "Button", b_n)
	t.set_stylebox("hover", "Button", b_h)
	t.set_stylebox("pressed", "Button", b_p)
	t.set_stylebox("disabled", "Button", b_d)
	t.set_stylebox("focus", "Button", b_f)
	t.set_color("font_color", "Button", COL_PERGAMENA)
	t.set_color("font_hover_color", "Button", Color(1, 0.94, 0.8))
	t.set_color("font_pressed_color", "Button", COL_ORO)
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.5, 0.45))
	t.set_font_size("font_size", "Button", 17)
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.1, 0.07, 0.06), COL_ORO, 1, 4))
	t.set_color("font_color", "TooltipLabel", COL_PERGAMENA)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.5, 0.36, 0.18, 0.7)
	sb.set_corner_radius_all(4)
	t.set_stylebox("grabber", "VScrollBar", sb)
	t.set_stylebox("grabber_highlight", "VScrollBar", sb)
	t.set_stylebox("grabber_pressed", "VScrollBar", sb)
	var sc = StyleBoxFlat.new()
	sc.bg_color = Color(0, 0, 0, 0.3)
	sc.set_corner_radius_all(4)
	sc.content_margin_left = 6
	t.set_stylebox("scroll", "VScrollBar", sc)
	t.set_constant("separation", "VBoxContainer", 6)
	t.set_constant("separation", "HBoxContainer", 6)
	var le = box(Color(0.12, 0.08, 0.07), Color(0.5, 0.36, 0.18), 1, 4, 8)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", box(Color(0.12, 0.08, 0.07), COL_ORO, 1, 4, 8))
	t.set_color("font_color", "LineEdit", COL_PERGAMENA)
	t.set_stylebox("normal", "OptionButton", b_n)
	t.set_stylebox("hover", "OptionButton", b_h)
	t.set_stylebox("pressed", "OptionButton", b_p)
	t.set_stylebox("focus", "OptionButton", b_f)
	t.set_stylebox("panel", "PopupMenu", box(Color(0.1, 0.06, 0.05), COL_ORO, 1, 4))
	t.set_color("font_color", "PopupMenu", COL_PERGAMENA)
	t.set_color("font_hover_color", "PopupMenu", COL_ORO)
	t.set_stylebox("hover", "PopupMenu", box(Color(0.35, 0.06, 0.06), COL_ORO, 0, 2, 4))
	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_color("font_color", "CheckBox", COL_PERGAMENA)
	t.set_color("font_hover_color", "CheckBox", COL_ORO)
	t.set_color("font_pressed_color", "CheckBox", COL_PERGAMENA)
	return t
