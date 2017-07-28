extends Sprite

# class member variables go here, for example:
var currentAngle = 0
var angularVelocity = 3.14/3

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	currentAngle = 0
	set_process(true)

func _process(delta):
	
	#Update the angle
	currentAngle = angularVelocity * delta
	rotate(currentAngle)