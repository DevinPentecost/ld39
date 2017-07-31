extends Sprite

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
func _process(delta):
	if(Input.is_action_pressed("ui_accept")):
		get_tree().change_scene("res://scenes/test2/TestCube.tscn")
	if(Input.is_action_pressed("ui_cancel")):
		print("Quitting")
		get_tree().quit()