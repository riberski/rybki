extends Control

@onready var panel = $Panel
@onready var title_label = $Panel/Title
@onready var desc_label = $Panel/Description
@onready var timer = $Timer

var queue: Array = []
var is_showing: bool = false

func _ready():
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	panel.hide()

func _on_achievement_unlocked(id: String, success_data: Dictionary):
	queue.append(success_data)
	if not is_showing:
		show_next()

func show_next():
	if queue.is_empty():
		is_showing = false
		return
	
	is_showing = true
	var data = queue.pop_front()
	
	title_label.text = data["title"]
	desc_label.text = data["description"]
	
	panel.show()
	
	# Animate slide in (simple move)
	var tween = create_tween()
	panel.position.y = -100 # Start off screen
	tween.tween_property(panel, "position:y", 20.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	timer.start()

func _on_timer_timeout():
	# Animate slide out
	var tween = create_tween()
	tween.tween_property(panel, "position:y", -100.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(panel.hide)
	tween.tween_callback(show_next)
