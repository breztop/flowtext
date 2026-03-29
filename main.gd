extends Control

@onready var manager: TextFlowManager = $TextFlowManager
@onready var editor: Control = $EditorUI

var _is_preview: bool = false

# 触摸计数跟踪（用于多指点按检测）
var _touch_count := 0


func _ready():
	editor.play_requested.connect(_on_play)
	editor.preview_requested.connect(_on_preview)

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
        _touch_count += 1 if event.pressed else -1
        _touch_count = clamp(_touch_count, 0, 10)

    elif event is InputEventScreenTap:
        if event.tap_count == 2 and _touch_count == 1 and _is_editor_ready_for_input():
            editor._on_play()
            get_viewport().set_input_as_handled()
        elif event.tap_count == 1 and _touch_count == 2:
            _toggle_editor()
            get_viewport().set_input_as_handled()

    elif event is InputEventLongPress:
        if _touch_count == 1:
            _toggle_editor()
            get_viewport().set_input_as_handled()


func _toggle_editor() -> void:
    editor.visible = not editor.visible
    if editor.visible:
        manager.stop()
        _is_preview = false

func _is_editor_ready_for_input() -> bool:
    return editor.visible and not editor.input.has_focus()
