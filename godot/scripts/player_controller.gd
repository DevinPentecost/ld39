extends Position3D

# class member variables go here, for example:aaaaaa
# var a = 2
# var b = "textvar"

#Attack scene
var scene_path = "res://scenes/test2/TestCube.tscn"
var player_attack_scene = preload("res://scenes/objects/PlayerAttack.tscn")
var player_dash_scene = preload("res://scenes/objects/PlayerDashGhost.tscn")

#Our enemy
var enemy = null

#Get nodes
var area = null
var camera = null
var sample_player = null
var animation_player = null
var animation_blocked = false
var trail = null

#Aiming
var view_angle = 30
var use_mouse_aim = false
var mouse_aim_pos = null
var joys = null

#Better WASD movement
var pressed_w = false
var pressed_a = false
var pressed_s = false
var pressed_d = false
var use_keyboard = false


#Movement
var move_angle = 0
var move_speed = 0
var speed = .004
var speed_threshold = 0.1

#Dash related
var dash_distance = .2
var dash_cooldown = 0.5
var min_dash_speed = 0.001
var dash_ready = true
var dash_timer = null

#Player's current power
var current_power = 100
var max_power = 100
var power_drain_rate = 1
var dash_power_drain = 15
var attack_power_drain = 5
var attack_power_gain = 15

#For combo attacks
var can_attack = true
var attack_max_combo = 3
var attack_current_combo = 0
var attack_cooldown = 0.85 #When you aren't in a combo
var attack_combo_cooldown = 0.25 #Wait this long before you combo
var attack_combo_miss_time = 0.65 #Wait this long and leave combo

#Make a bunch of tweens?
var timer_attack = Timer.new()
var timer_attack_combo = Timer.new()
var timer_attack_combo_miss = Timer.new()


#Did you lose?
var alive = true
var all_done = false

enum JOYSTICK_AXIS{
	LEFT_STICK_VERTICAL=0,
	LEFT_STICK_HORIZONTAL=1,
	RIGHT_STICK_VERTICAL=2,
	RIGHT_STICK_HORIZONTAL=3,
	LEFT_TRIGGER=6,
	RIGHT_TRIGGER=7
}

enum JOYSTICK_BUTTONS{
	A=0,
	B=1,
	X=2,
	Y=3,
	LEFT_BUMPER=4,
	RIGHT_BUMPER=5,
	LEFT_TRIGGER=6,
	RIGHT_TRIGGER=7,
	LEFT_JOYSTICK=8,
	RIGHT_JOYSTICK=9,
	SELECT=10,
	START=11,
}

enum KEYBOARD_KEYS{
	W=87,
	A=65,
	S=83,
	D=68,
	
}

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	enemy = get_node("../Enemy")
	area = get_node('./Area')
	camera = get_node('../Camera')
	sample_player = get_node("./SamplePlayer")
	animation_player = get_node('./player/AnimationPlayer')
	animation_player.connect("finished", self, "_animation_player_finished_callback")
	trail = get_node('../Player/player/rig/Skeleton/Lhand/axe/trailanchor')	
	
	# are there joysticks?
	joys = Input.get_connected_joysticks()
	
	set_process_input(true)
	set_process(true)
	set_fixed_process(true)
	
	#Create the dash timer
	dash_timer = Timer.new()
	dash_timer.connect("timeout", self, "_on_dash_timer_timeout")
	dash_timer.set_wait_time(dash_cooldown)
	dash_timer.set_one_shot(true)
	add_child(dash_timer)
	
	#Create the attack timers
	timer_attack.connect("timeout", self, "_on_attack_timer_timeout")
	timer_attack.set_wait_time(attack_cooldown)
	timer_attack.set_one_shot(true)
	add_child(timer_attack)
	timer_attack_combo.connect("timeout", self, "_on_attack_combo_timer_timeout")
	timer_attack_combo.set_wait_time(attack_combo_cooldown)
	timer_attack_combo.set_one_shot(true)
	add_child(timer_attack_combo)
	timer_attack_combo_miss.connect("timeout", self, "_on_attack_combo_miss_timer_timeout")
	timer_attack_combo_miss.set_wait_time(attack_combo_miss_time)
	timer_attack_combo_miss.set_one_shot(true)
	add_child(timer_attack_combo_miss)
	
	#Hide the mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(2)
	
func _on_dash_timer_timeout():
	#Re-enable dash
	print("Can dash")
	dash_ready = true
	
func _on_attack_timer_timeout():
	#We can attack again
	print("Can start a new combo")
	attack_current_combo = 0
	can_attack = true

func _on_attack_combo_timer_timeout():
	#We can attack again
	print("Can combo again")
	can_attack = true

func _on_attack_combo_miss_timer_timeout():
	#We waited too long to combo
	print("Combo over...")
	attack_current_combo = 0
	can_attack = false
	
	#Now we gotta wait
	timer_attack.start()
	

func take_hit():
	#We die or whatever
	if all_done:
		return
		
	alive = false
	print("UR DED PAL")
	sample_player.play("player_dead")
	
	
func recover_power(amount=-1):
	#Just add it
	if amount < 0:
		amount = attack_power_gain
	current_power += amount
	
func _make_attack():
	
	#Are we in the middle of a cooldown? Have we attacked too much?
	if not can_attack or attack_current_combo >= attack_max_combo:
		#We can't attack
		return
		
	
	#Make the attack
	attack_current_combo += 1
	var new_player_attack = player_attack_scene.instance()
	
	#Move it to the player
	var new_attack_transform = new_player_attack.get_transform()
	new_attack_transform.origin = get_transform().origin
	
	#Rotate it to match the player
	new_attack_transform = new_attack_transform.rotated(Vector3(0, 1, 0), view_angle)
	new_player_attack.set_transform(new_attack_transform)
	
	#Add it
	get_parent().add_child(new_player_attack)
	
	#Fire off timers
	can_attack = false
	timer_attack_combo.stop()
	timer_attack_combo.start()
	timer_attack_combo_miss.stop()
	timer_attack_combo_miss.start()
	
	#Play the animation
	var animation_name = 'atk'+str(attack_current_combo)
	_play_animation(animation_name, true, true)
	

func _process(delta):
	#Is our enemy dead?
	if enemy.current_power <= 0:
		_play_animation("victory", true, true)
		all_done = true
		return
	
	if all_done:
		return
	
	
		
	#Are we dead?
	if not alive:
		_play_animation("death", true, true)
		all_done = true
		return
		
	#Are we moving with WASD?
	if use_keyboard:
		if pressed_w or pressed_a or pressed_s or pressed_d:
			#But which way?
			var x = 0
			var z = 0
			if pressed_w:
				x -= 1
			if pressed_s:
				x += 1
			if pressed_a:
				z -= 1
			if pressed_d:
				z += 1
			
			#Now calculate angle and speed
			move_angle = atan2(x, z)
			move_speed = Vector2(x, z).length() * speed
		else:
			move_angle = 0
			move_speed = 0
	
	#Move according to our vector
	#Are we moving?
	if move_speed > 0:
		#Play the move animation if we aren't already
		_play_animation("walk")
	else:
		_play_animation("idle")
		
	#Move the object
	var movement = Vector3(move_speed * cos(move_angle), 0, move_speed * sin(move_angle))
	var transform = get_transform()
	transform = transform.translated(movement)
	set_transform(transform)
	
	#Drain power
	current_power -= power_drain_rate*delta
	
	#Don't go over max power
	if current_power > max_power:
		current_power = max_power
		
	if attack_current_combo > 0:
		trail.show()
	else: 
		trail.hide()
	
	
func _fixed_process(delta):
	#Are we looking with the mouse?
	if mouse_aim_pos != null and use_mouse_aim:
		var mouse_aim_source = camera.project_ray_origin(mouse_aim_pos)
		var mouse_aim_target = mouse_aim_source + camera.project_ray_normal(mouse_aim_pos) * 1000
		mouse_aim_target.z = mouse_aim_source.z
		var space_state = get_world().get_direct_space_state()
		var intersection = space_state.intersect_ray(mouse_aim_source, mouse_aim_target)
		
		#Did we click?
		if not intersection.empty():
			var click_location = intersection["position"]
			print(click_location)
			var my_pos = Vector2(get_transform().origin.x, get_transform().origin.z)
			var target_pos = Vector2(click_location.x, click_location.z)
			var angle = atan2(target_pos.x - my_pos.x, my_pos.y - target_pos.y)
			print(angle)
			view_angle = angle
		
		#Clear it so joypad can take over
		mouse_aim_pos = null

func _animation_player_finished_callback():
	#We are no longer blocked
	animation_blocked = false

func _play_animation(animation_name, blocking=false, override=false):
	
	#aim player at mouse
	
	var w = get_viewport().get_rect().size.x
	var h = get_viewport().get_rect().size.y
	if joys.size() == 0:
		var x = get_viewport().get_mouse_pos().x
		if x > w/2 + 200:
			x = w/2 + 200
		elif x < w/2 - 200:
			x = w/2 - 200
		var y = get_viewport().get_mouse_pos().y
		if y > h/2 + 200:
			y = h/2 + 200
		elif y < h/2 - 200:
			y = h/2 - 200
		Input.warp_mouse_pos(Vector2(x,y))
		view_angle = atan2( 2*PI*(y-h/2)/h,2*PI*(x-w/2)/w)
		
	#Are we already playing the animation?
	if (not animation_blocked or override) and (not animation_player.is_playing() or animation_player.get_current_animation() != animation_name):
		#Play this animation
		animation_player.play(animation_name)

	#Are we playing a blocking animation?
	if blocking:
		#We need to add a block
		animation_blocked = true
	

func _input(event):
	if event.type != InputEvent.MOUSE_MOTION:
		print(event)
	
	#What event did we get?
	if event.is_action("player_aim"):
		#We need to handle aiming
		_handle_player_aim(event)
	elif event.is_action("player_move"):
		#Handle movement
		_handle_player_move(event)
	elif event.is_action("player_dash"):
		#We dash
		_handle_player_dash(event)
	elif event.is_action("player_attack"):
		#We're attacking
		_handle_player_attack(event)
	elif event.is_action("player_quit"):
		#We quit
		_handle_player_quit(event)
	elif event.is_action("player_restart"):
		#We quit
		_handle_player_restart(event)
	
	#Track the mouse position
	if event.type == InputEvent.MOUSE_MOTION:
		mouse_aim_pos = event.pos 

func _handle_player_aim(input_event):
	print("Look changed!")
	#What kind of aim was it?
	if input_event.type == InputEvent.JOYSTICK_MOTION:
		#We are aiming via analogue
		var x = Input.get_joy_axis(0, JOYSTICK_AXIS.RIGHT_STICK_HORIZONTAL)
		var y = Input.get_joy_axis(0, JOYSTICK_AXIS.RIGHT_STICK_VERTICAL)
		if !(x == 0 or y == 0):
			view_angle = atan2(x, y)
	else:
		#We have a mouse button or something
		pass
		#mouse_aim_source = camera.project_ray_origin(input_event.pos)
		#mouse_aim_target = mouse_aim_source + camera.project_ray_normal(input_event.pos) * 1000
		

func _handle_player_move(input_event):
	print("Moving!")
	#Using the joystick to move?
	if input_event.type == InputEvent.JOYSTICK_MOTION:
		#We are moving via analogue
		#Figure out movement angle and direction
		var x = Input.get_joy_axis(0, JOYSTICK_AXIS.LEFT_STICK_HORIZONTAL)
		var y = Input.get_joy_axis(0, JOYSTICK_AXIS.LEFT_STICK_VERTICAL)
		move_angle = atan2(x, y)
		var move_velocity = sqrt(x*x + y*y)
		
		#Are we moving fast enough
		if move_velocity > speed_threshold:
			move_speed = move_velocity * speed
			use_keyboard = false
		else:
			move_speed = 0
	else:
		#Moving via the keys when they are pressed
		var pressed = input_event.is_pressed()
		use_keyboard = true
		
		#Was it W A S D?
		if input_event.scancode == KEYBOARD_KEYS.W:
			pressed_w = pressed
		if input_event.scancode == KEYBOARD_KEYS.S:
			pressed_s = pressed
		if input_event.scancode == KEYBOARD_KEYS.A:
			pressed_a = pressed
		if input_event.scancode == KEYBOARD_KEYS.D:
			pressed_d = pressed

func _handle_player_dash(input_event):
	#Make a dash motion?
	if input_event.type == InputEvent.KEY and not input_event.is_pressed() or all_done:
		return
		
	#We are dashing
	print("Dashing!")
	
	#Can we dodge?
	if(dash_ready and move_speed > min_dash_speed and current_power > 0):
		#Put dash on cooldown
		dash_ready = false
		dash_timer.start()
		
		#And make the movement
		#Move according to our vector
		var movement = Vector3(dash_distance * cos(move_angle), 0, dash_distance * sin(move_angle))
		var current_position = get_transform()
		var final_position = current_position.translated(movement)
		set_transform(final_position)
		
		#Drain dash energy
		current_power -= dash_power_drain
		
		#Play the dash sound
		var dash_index = randi()%2 + 1
		var dash_sound = "dash_" + str(dash_index)
		sample_player.play(dash_sound)
		
		#Spawn a few ghosts
		var dash_distance = current_position.origin.distance_to(final_position.origin)
		var ghost_count = 3
		for ghost in range(ghost_count):
			#Where to put the ghost?
			var dash_percentage = float(ghost) / ghost_count
			var ghost_position = current_position.origin.linear_interpolate(final_position.origin, dash_percentage)
			
			#Move the ghost
			var new_ghost = player_dash_scene.instance()
			var final_transform = current_position
			final_transform.origin = ghost_position
			final_transform = final_transform.rotated(Vector3(0, 1, 0), view_angle)
			new_ghost.set_transform(final_transform)
			
			#Set the index and add
			#Set up the ghost's animation and lifetime
			new_ghost.init(ghost, dash_percentage)
			get_parent().add_child(new_ghost)
			

func _handle_player_attack(input_event):
	#Make an attack?
	if input_event.type == InputEvent.KEY and not input_event.is_pressed() or all_done:
		return
	
	#We are attacking
	print("Attacking!")
	_make_attack()
	
func _handle_player_quit(input_event):
	print("Quitting")
	get_tree().quit()

func _handle_player_restart(input_event):
	#this one works
	#get_tree().reload_current_scene()
	
	get_tree().change_scene("res://scenes/test2/Start.tscn")
	
	
	
	