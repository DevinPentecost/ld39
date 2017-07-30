extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#Some scenes to instance
onready var attack_script = preload("res://scripts/attack_controller.gd").new()
var attack_scene = preload("res://scenes/objects/Attack.tscn")


var player = null
var tween = null
var area = null

# How much health does this have
var current_power = 100
var power_lost_on_hit = 5


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
	#Grab the player
	player = get_node('../Player')
	tween = get_node('./Tween')
	area = get_node('./Area')
	
	#Launch the attack
	"""
	tween.interpolate_callback(self, 1, "_attack_under_player", 0)
	tween.interpolate_callback(self, 1.1, "_attack_under_player", 1)
	tween.interpolate_callback(self, 1.2, "_attack_under_player", 2)
	tween.set_repeat(true)
	tween.start()
	"""
	
func take_hit():
	#We die or whatever
	current_power -= power_lost_on_hit
	print("UR HURT BADGUY  ", current_power)
	
func _attack_under_player(radius=0):
	#Make an attack under the player
	#It's size depends on the radius
	
	#Where is the player?
	var player_origin = player.get_transform().origin
	
	#What angle are we at?
	var current_angle = 0
	
	#We need to figure out how many steps to make
	var attack_radius = attack_script.attack_radius * 2
	var current_radius = radius * attack_radius
	
	
	#Determine the step size
	var angle_step = 360
	if current_radius > 0:
		var circumference = 2*PI*current_radius
		var distance = attack_radius
		angle_step = 360*distance/circumference
	
	#How many attacks can be made at this radius?
	var attack_count = int(360/angle_step)
	angle_step = int(360/attack_count)
	
	#Now add them until it's full
	for attack in range(attack_count):
		#Add the attack
		var attack_angle = attack * angle_step
		var new_attack = attack_scene.instance()
		
		#Position it in the circle
		var x = cos(attack_angle) * current_radius
		var z = sin(attack_angle) * current_radius
		var attack_offset = Vector3(x, 0, z)
		
		var new_attack_transform = new_attack.get_transform()
		new_attack_transform.origin = player_origin + attack_offset
		new_attack.set_transform(new_attack_transform)
		
		get_parent().add_child(new_attack)
	#We've made the attack I think
