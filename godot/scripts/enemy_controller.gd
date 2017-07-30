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
var attack_timer = Timer.new()

# How much health does this have
var current_power = 100
var power_lost_on_hit = 5

# How long between attacks?
# This is after the attack ends
var attack_min_cooldown = 0.75
var attack_max_cooldown = 1.75


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
	#Grab the player
	player = get_node('../Player')
	area = get_node('./Area')
	
	#Set up the timer
	attack_timer.connect("timeout", self, "_on_attack_timer_timeout")
	attack_timer.set_one_shot(true)
	add_child(attack_timer)
	
	#Launch an attack
	tween = get_node('./Tween')
	tween.set_repeat(false)
	_attack_finished()
	
	
func take_hit():
	#We die or whatever
	current_power -= power_lost_on_hit
	print("UR HURT BADGUY  ", current_power)
	
func _attack_finished():
	#How long to wait?
	var wait_time = rand_range(attack_min_cooldown, attack_max_cooldown)
	attack_timer.set_wait_time(wait_time)
	attack_timer.start()
	
func _on_attack_timer_timeout():
	#It's time to launch an attack
	
	#TODO: Pick an attack some how
	var possible_attacks = 2
	var attack = randi()%possible_attacks
	if attack == 0:
		_launch_player_circle_attack()
	elif attack == 1:
		_launch_semi_circle_attack()
	

func _launch_semi_circle_attack(quadrant=null):
	#Was a quadrant specified?
	if quadrant == null:
		quadrant = randi()%4
	
	#Launch a bunch of radii in a half circle
	var start_angle = 0 + 90 * quadrant
	var end_angle = 210 + 90 * quadrant
	var target_position = get_transform().origin
	tween.interpolate_callback(self, 0, "_launch_semi_cirle_attack", target_position, 0, start_angle, end_angle)
	tween.interpolate_callback(self, .25, "_launch_semi_cirle_attack", target_position, 1, start_angle, end_angle)
	tween.interpolate_callback(self, .5, "_launch_semi_cirle_attack", target_position, 2, start_angle, end_angle)
	tween.interpolate_callback(self, .75, "_launch_semi_cirle_attack", target_position, 3, start_angle, end_angle)
	tween.interpolate_callback(self, 1, "_launch_semi_cirle_attack", target_position, 4, start_angle, end_angle)
	tween.interpolate_callback(self, 1.25, "_launch_semi_cirle_attack", target_position, 5, start_angle, end_angle)
	tween.interpolate_callback(self, 1.5, "_attack_finished")
	tween.start()

func _launch_player_circle_attack():
	#Fire off the attack
	var player_origin = player.get_transform().origin
	tween.interpolate_callback(self, 0, "_launch_circle_attack", player_origin, 0)
	tween.interpolate_callback(self, .25, "_launch_circle_attack", player_origin, 1)
	tween.interpolate_callback(self, .5, "_launch_circle_attack", player_origin, 2)
	tween.interpolate_callback(self, 1, "_attack_finished")
	tween.start()

func _attack_under_player(radius):
	#Make an attack under the player
	#It's size depends on the radius
	
	#Where is the player?
	var player_origin = player.get_transform().origin
	_launch_circle_attack(player_origin, radius)
	
func _launch_circle_attack(target_position, radius):
	
	#Launch the attack in a full circle
	_launch_semi_cirle_attack(target_position, radius, 0, 360)
	
func _launch_semi_cirle_attack(target_position, radius, start_angle, end_angle):
	
	#What angle are we at?
	var current_angle = 0
	
	#We need to figure out how many steps to make
	var attack_radius = attack_script.attack_radius * 2
	var current_radius = radius * attack_radius
	
	
	#Determine the step size
	var total_angle = end_angle - start_angle
	var angle_step = total_angle
	if current_radius > 0:
		var circumference = 2*PI*current_radius
		var distance = attack_radius
		angle_step = 360*distance/circumference
	
	#How many attacks can be made at this radius?
	var attack_count = int(total_angle/angle_step)
	angle_step = int(total_angle/attack_count)
	
	#Now add them until it's full
	for attack in range(attack_count):
		#Add the attack
		var attack_angle = attack * angle_step
		var new_attack = attack_scene.instance()
		
		#Position it in the circle
		var angle = attack_angle + start_angle
		var angle_radians = angle * 0.01745329252
		var x = cos(angle_radians) * current_radius
		var z = sin(angle_radians) * current_radius
		var attack_offset = Vector3(x, 0, z)
		
		var new_attack_transform = new_attack.get_transform()
		new_attack_transform.origin = target_position + attack_offset
		new_attack.set_transform(new_attack_transform)
		
		get_parent().add_child(new_attack)
	#We've made the attack I think
