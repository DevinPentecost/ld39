extends Position3D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#Get the animator
var animator = null

#Some variables
var index = 0 #Set by the caller
var animation_percent = 0 #Set by the caller
var base_lifetime = 0.75
var additional_lifetime = 0.25
var lifetime = base_lifetime
var lifetime_timer = Timer.new()

#Where to vibrate from
var vibrate_center = null
var vibrate_range = 0.01

func init(ghost_index, animation_pause_percent):
	index = ghost_index
	animation_percent = animation_pause_percent

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	
	#Do animator business
	animator = get_node("player/AnimationPlayer")
	animator.play("dash(static)")
	animator.stop()
	animator.seek(animation_percent, true)
	
	#How long to live?
	lifetime = base_lifetime + additional_lifetime * index
	lifetime_timer.set_wait_time(lifetime)
	lifetime_timer.connect("timeout", self, "_on_lifetime_timer_timeout")
	lifetime_timer.start()
	add_child(lifetime_timer)
	
	#Where to start the vibration from
	vibrate_center = get_transform().origin
	set_process(true)
	
func _process(delta):
	
	#Move some distance randomly
	var rx = randf() * vibrate_range
	var ry = randf() * vibrate_range
	var rz = randf() * vibrate_range
	
	#Move it
	var vibration = Vector3(rx, ry, rz)
	var transform = get_transform()
	transform.origin = vibrate_center + vibration
	set_transform(transform)
	
func _on_lifetime_timer_timeout():
	#The timer is complete
	queue_free()
	