extends Control

@onready var manager: TextFlowManager = $TextFlowManager
@onready var editor: Control = $EditorUI
@onready var splash: ColorRect = %SplashPage

var _is_preview: bool = false
var _on_splash: bool = true

# 触摸检测
var _touch_count := 0
var _last_tap_time := 0
var _long_press_timer: Timer

# 启动页呼吸动画
var _hint_tween: Tween


func _ready():
	editor.play_requested.connect(_on_play)
	editor.preview_requested.connect(_on_preview)
	# 长按计时器
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.wait_time = 0.6
	_long_press_timer.timeout.connect(_on_long_press)
	add_child(_long_press_timer)
	# 启动页提示文字呼吸闪烁
	_start_hint_blink()

func _on_play(config: Dictionary):
	var segments = config.get("segments", [])
	if segments.is_empty():
		manager.stop()
		_is_preview = false
		print("No segments to play.")
		return
	manager.generate_flow(config)
	if not _is_preview:
		editor.visible = false

func _on_preview(config: Dictionary):
	_is_preview = true
	manager.generate_flow(config)

## 输入事件处理
## esc / 返回事件: 显示/隐藏编辑器界面
## space / 双击: 播放/暂停文本流（当编辑器界面可见且输入焦点不在编辑器输入框时）
## ctrl + s: 保存当前配置
## ctrl + l: 加载配置
func _unhandled_input(event):
	# ====================== 0. 启动页拦截 ======================
	if _on_splash:
		var clicked = false
		if event is InputEventKey and event.pressed:
			clicked = true
		elif event is InputEventMouseButton and event.pressed:
			clicked = true
		elif event is InputEventScreenTouch and event.pressed:
			clicked = true
		if clicked:
			_dismiss_splash()
			get_viewport().set_input_as_handled()
		return

	# ====================== 1. 键盘事件处理 ======================
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_ESCAPE, KEY_BACK]:
			_toggle_editor()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and _is_editor_ready_for_input():
			editor._on_play()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S and event.ctrl_pressed:
			editor._on_save()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_L and event.ctrl_pressed:
			editor._on_load()
			get_viewport().set_input_as_handled()

	# ====================== 2. 鼠标事件处理  ======================
	elif event is InputEventMouseButton:
		# 检测鼠标左键双击
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click and event.pressed:
			if _is_editor_ready_for_input():
				editor._on_play()
				get_viewport().set_input_as_handled()

	# ====================== 3. 移动端触摸事件处理 ======================
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_count += 1
			_long_press_timer.start()
			# 双击检测
			var now = Time.get_ticks_msec()
			if now - _last_tap_time < 400 and _touch_count == 1:
				if _is_editor_ready_for_input():
					editor._on_play()
					get_viewport().set_input_as_handled()
					_long_press_timer.stop()
			_last_tap_time = now
			# 双指轻触切换编辑器
			if _touch_count == 2:
				_toggle_editor()
				get_viewport().set_input_as_handled()
				_long_press_timer.stop()
		else:
			_touch_count -= 1
			_touch_count = max(_touch_count, 0)
			_long_press_timer.stop()


func _on_long_press() -> void:
	if _touch_count == 1:
		_toggle_editor()

func _toggle_editor() -> void:
	editor.visible = not editor.visible
	if editor.visible:
		manager.stop()
		_is_preview = false

func _is_editor_ready_for_input() -> bool:
	return editor.visible and not editor.input.has_focus()

## ====================== 启动页 ======================

func _start_hint_blink() -> void:
	var hint_label = splash.get_node("HintLabel")
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_property(hint_label, "modulate:a", 0.3, 1.2).set_trans(Tween.TRANS_SINE)
	_hint_tween.tween_property(hint_label, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)

func _dismiss_splash() -> void:
	if not _on_splash:
		return
	_on_splash = false
	if _hint_tween:
		_hint_tween.kill()
		_hint_tween = null
	var tween = create_tween()
	tween.tween_property(splash, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		splash.visible = false
		editor.visible = true
	)
