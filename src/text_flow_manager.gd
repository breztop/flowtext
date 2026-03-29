extends Control
class_name TextFlowManager

signal signal_setting_warning(message: String)

@export var character_scene: PackedScene


var gap_percentage: float = 0.3 # 滚动首尾间的空白占比，默认为30%
var scroll_speed: float = 100.0

## 受到实际字体的大小影响，如果超过了屏幕宽度的情况，就算关闭了滚动也会被强制滚动，但是会发出文本警告
var is_scrolling: bool = true

## 表示文字的流动方向
var scroll_direction: Vector2 = Vector2.LEFT

## 计算文本的实际宽高，用于滚动和背景调整
var total_width: float = 0.0
var total_height: float = 0.0

var characters: Array[TextCharacter] = []

@onready var container: Control = $TextContainer
@onready var bg_panel: Panel = $BgPanel

func _ready():
	if not character_scene:
		character_scene = preload("res://src/text_character.tscn")



	var vp_size = get_viewport_rect().size
	if total_width > vp_size.x and not is_scrolling:
		is_scrolling = true
		message = "Text width exceeds viewport width but scrolling is disabled. Enabling scrolling to prevent text cutoff."
		signal_setting_warning.emit(message)
		print_warning(message)


func _process(delta):
	if not is_scrolling or characters.size() == 0:
		return

	container.position += scroll_direction * scroll_speed * delta
	var vp = get_viewport_rect().size
	if scroll_direction.x < 0 and container.position.x < -total_width:
		container.position.x = vp.x
	elif scroll_direction.x > 0 and container.position.x > vp.x:
		container.position.x = -total_width
	if scroll_direction.y < 0 and container.position.y < -total_height:
		container.position.y = vp.y
	elif scroll_direction.y > 0 and container.position.y > vp.y:
		container.position.y = -total_height

func stop():
	is_scrolling = false
	for ch in characters:
		if is_instance_valid(ch):
			ch.stop_animations()


