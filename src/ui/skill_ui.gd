extends Control

@onready var points_label = $Panel/PointsLabel
@onready var skill_container = $Panel/ScrollContainer/VBoxContainer

func _ready():
	hide()
	update_ui()
	if SkillManager:
		SkillManager.skill_points_changed.connect(_on_points_changed)
		SkillManager.skill_unlocked.connect(_on_skill_unlocked)

func show_skills():
	update_ui()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_skills():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_ui():
	if not SkillManager: return
	
	if points_label:
		points_label.text = "SP: " + str(SkillManager.skill_points)
	
	if not skill_container: return
	
	# Clear existing
	for child in skill_container.get_children():
		child.queue_free()
		
	for skill_id in SkillManager.skills:
		var skill = SkillManager.skills[skill_id]
		var btn = Button.new()
		var status_text = ""
		if skill.level >= skill.max_level:
			status_text = " [MAX]"
		elif not SkillManager.can_unlock_skill(skill_id):
			if SkillManager.skill_points < skill.cost:
				status_text = " [COST: " + str(skill.cost) + "]"
			else:
				status_text = " [LOCKED]"
		else:
			status_text = " [UPGRADE: " + str(skill.cost) + " SP]"
			
		btn.text = skill.name + " (Lvl " + str(skill.level) + "/" + str(skill.max_level) + ")" + status_text
		btn.tooltip_text = skill.description
		
		# Align left
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Disable if max level or cannot afford (but allow viewing tooltip)
		if skill.level >= skill.max_level:
			btn.disabled = true
		elif not SkillManager.can_unlock_skill(skill_id):
			# Gray out but keep clickable for info? 
			# Standard is disable button if can't afford
			btn.disabled = true
		
		# Connect press
		btn.pressed.connect(func(): _on_skill_pressed(skill_id))
		
		skill_container.add_child(btn)

func _on_skill_pressed(skill_id):
	if SkillManager.unlock_skill(skill_id):
		update_ui()

func _on_points_changed(points):
	if visible: update_ui()

func _on_skill_unlocked(skill_id, level):
	if visible: update_ui()
