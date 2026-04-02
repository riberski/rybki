extends Area3D

var current_player = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("set_interactable"):
		print("Player can interact with Shop")
		body.set_interactable(self)

func _on_body_exited(body):
	if body.has_method("set_interactable"):
		# Safety check? 
		body.set_interactable(null)

func interact(player):
	print("Interacted with Shop!, Player:", player)
	if player and player.has_method("open_shop"):
		player.open_shop()

func get_interact_text() -> String:
	return "Open Shop"
