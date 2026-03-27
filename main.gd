extends Control

@onready var manager: TextFlowManager = $TextFlowManager
@onready var editor: Control = $EditorUI

var _is_preview: bool = false

func _ready():
	editor.play_requested.connect(_on_play)
	editor.preview_requested.connect(_on_preview)

func _on_play(config: Dictionary):
	var segments = config.get("segments", [])
	if segments.is_empty():
		manager.stop()
		_is_preview = false
		return
	manager.generate_flow(config)
	if not _is_preview:
		editor.visible = false

func _on_preview(config: Dictionary):
	_is_preview = true
	manager.generate_flow(config)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			editor.visible = not editor.visible
			if editor.visible:
				manager.stop()
				_is_preview = false
		elif event.keycode == KEY_SPACE and not editor.input.has_focus():
			if editor.visible:
				editor._on_play()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S and event.ctrl_pressed:
			editor._on_save()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_L and event.ctrl_pressed:
			editor._on_load()
			get_viewport().set_input_as_handled()