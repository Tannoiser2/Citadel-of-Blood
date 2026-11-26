extends RefCounted
class_name Widget
## Piccoli costruttori di controlli con lo stile del gioco.

static func etichetta(testo: String, dim: int = 17, colore: Color = Risorse.COL_PERGAMENA, font_nome: String = "Testo") -> Label:
	var l = Label.new()
	l.text = testo
	l.add_theme_font_override("font", Risorse.font(font_nome) if font_nome != "grassetto" else Risorse.font_grassetto())
	l.add_theme_font_size_override("font_size", dim)
	l.add_theme_color_override("font_color", colore)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 40
	return l

static func titolo(testo: String, dim: int = 34) -> Label:
	var l = etichetta(testo, dim, Risorse.COL_ORO, "Titoli")
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)
	return l

static func bottone(testo: String, cb: Callable, dim: int = 17) -> Button:
	var b = Button.new()
	b.text = testo
	b.add_theme_font_size_override("font_size", dim)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(80, 38)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

static func testo_ricco(bb: String, dim: int = 16) -> RichTextLabel:
	var r = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bb
	r.add_theme_font_size_override("normal_font_size", dim)
	r.add_theme_font_size_override("bold_font_size", dim)
	r.custom_minimum_size.x = 60
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r

static func pannello(fondo: Color = Color(0.08, 0.05, 0.05, 0.92), bordo: Color = Color(0.5, 0.36, 0.18)) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", Risorse.box(fondo, bordo, 2, 8, 12))
	return p

static func pergamena() -> PanelContainer:
	var p = PanelContainer.new()
	var s = Risorse.box(Risorse.COL_PERGAMENA, Color(0.35, 0.22, 0.1), 3, 4, 18)
	p.add_theme_stylebox_override("panel", s)
	return p

static func barra(valore: float, massimo: float, colore: Color, larghezza: float = 80, altezza: float = 7) -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(larghezza, altezza)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var disegna = func():
		var w = c.size.x
		c.draw_rect(Rect2(0, 0, w, altezza), Color(0, 0, 0, 0.6))
		var f = 0.0 if massimo <= 0 else clamp(valore / massimo, 0.0, 1.0)
		c.draw_rect(Rect2(1, 1, (w - 2) * f, altezza - 2), colore)
	c.draw.connect(disegna)
	return c

static func ritratto(nome_tex: String, lato: float) -> TextureRect:
	var t = TextureRect.new()
	t.texture = Risorse.tex(nome_tex)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.custom_minimum_size = Vector2(lato, lato)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func scorrevole(contenuto: Control) -> ScrollContainer:
	var s = ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenuto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(contenuto)
	return s

static func svuota(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()
