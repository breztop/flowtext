extends Label
class_name TextCharacter

var is_jumping: bool = false
var original_pos: Vector2 = Vector2.ZERO
var _tween: Tween
var _glow_shader: Shader
var _gradient_shader: Shader

func setup(char: String, size: int, color: Color, font: Font = null, outline_color: Color = Color.TRANSPARENT, outline_size: int = 0):
	text = char
	if font:
		add_theme_font_override("font", font)
	add_theme_font_size_override("font_size", size)
	add_theme_color_override("font_color", color)
	if outline_size > 0 and outline_color.a > 0:
		add_theme_color_override("font_outline_color", outline_color)
		add_theme_constant_override("outline_size", outline_size)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pivot_offset = Vector2(size, size) * 0.5

func apply_glow(glow_color: Color, intensity: float, size: float, softness: float):
	if not _glow_shader:
		_glow_shader = load("res://effects/glow.shader")
	var mat = ShaderMaterial.new()
	mat.shader = _glow_shader
	mat.set_shader_parameter("glow_color", glow_color)
	mat.set_shader_parameter("glow_intensity", intensity)
	mat.set_shader_parameter("glow_size", size)
	mat.set_shader_parameter("glow_softness", softness)
	material = mat

func apply_gradient(color_start: Color, color_end: Color, animate: bool = false, speed: float = 1.0):
	if not _gradient_shader:
		_gradient_shader = load("res://effects/gradient.shader")
	var mat = material as ShaderMaterial
	if not mat:
		mat = ShaderMaterial.new()
	# 不能同时使用辉光和渐变，渐变会覆盖辉光
	mat.shader = _gradient_shader
	mat.set_shader_parameter("color_start", color_start)
	mat.set_shader_parameter("color_end", color_end)
	mat.set_shader_parameter("animate", animate)
	mat.set_shader_parameter("gradient_speed", speed)
	material = mat

func clear_effects():
	material = null

func do_jump():
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position:y", original_pos.y - 30, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", original_pos.y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func do_fade_in(delay: float = 0.0, duration: float = 0.3):
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, duration).set_delay(delay)

func do_scale_in(delay: float = 0.0, duration: float = 0.3):
	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, duration).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func stop_animations():
	is_jumping = false
	if _tween and _tween.is_running():
		_tween.kill()