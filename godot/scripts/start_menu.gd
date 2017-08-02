extends Control

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here

	set_process(true)
	
func _process(delta):
	if(Input.is_action_pressed("ui_accept")):
		get_tree().change_scene("res://scenes/test2/TestCube.tscn")
	if(Input.is_action_pressed("player_attack")):
		get_tree().change_scene("res://scenes/test2/TestCube.tscn")
	if(Input.is_action_pressed("ui_cancel")):
		print("Quitting")
		get_tree().quit()