#https://github.com/LeonardMeagher2/Godot-Assets/blob/master/Plugins/Trails/3DTrail.gd

extends Spatial

export(Material) var material
var instance = ImmediateGeometry.new()

export var tube = false
export var segments = 4
export var cap_pointyness = 0.0

export(bool) var emit = true
var emittingDone = false;

export var lifeTime = 1.0
var lifeTimeRatio = 1.0

export(Color) var startColor = Color(255,255,255)
export(Color) var endColor = Color(255,255,255)

export var startWidth = 1.0
export var endWidth = 0.0

export var maxAngle = 2.0
export var minVertexDistance = 0.1
export var maxVertexDistance = 1.0
#these help make less geometry
export var optimizeAngleInterval = 0.1
export var optimizeDistanceInterval = 0.05
export var optimizeCount = 30
var optCount = 30

export var wireframe = false

var points = []
var pointCount = 0 #just to make the lookup easier

class Point:
	var timeAlive = 0
	var fadeAlpha = 0
	var transform = Transform()
	
	var ratio = 0
	var width = 0
	
	func set(trans = Transform()):
		transform = trans
	func getRatio(lifeTime):
		ratio = 0
		if(lifeTime > 0):
			ratio = timeAlive / lifeTime
		return ratio
	func getWidth(sw,ew):
		width = lerp(sw,ew,ratio)
		return width
		
func Angle(mat1,mat2):
	var v1 = mat1.get_euler()
	var v2 = mat2.get_euler()
	
	var dot = v1.dot(v2)
	var l = (v1.length() * v2.length())
	if(l == 0):
		return 0
	dot = dot/(v1.length() * v2.length())
	var ac = acos(dot)
	
	return ac #radians

func _ready():
	set_process(true)
	add_child(instance)
	instance.set_name("TrailMeshInstance")
	instance.set_material_override(material)
	optCount = optimizeCount
	

func _process(delta):
	update(delta)
	
	
func addPoint():
	points.append(Point.new())
	points[pointCount].set(get_global_transform())
	pointCount+=1
	
func insertPoint():
	points.insert(0,Point.new());
	points[0].set(get_global_transform())
	pointCount+=1

func segPos(s,width):
	var x = cos(2 * PI * s / segments) * width/2
	var y = sin(2 * PI * s / segments) * width/2
	return Vector3(x,y,0)

func update(delta):
	
	instance.set_global_transform(Transform())
	#emit
	if(!emit):
		emittingDone = true
	
	if(emittingDone):
		emit = false
	
	#check for dead points
	for i in range(pointCount-1,0,-1):
		var p = points[i]
		if(p == null || p.timeAlive > lifeTime):
			points.remove(i)
			pointCount-=1
		else:
			p.timeAlive += delta
	
	#optomize
	if(pointCount > optCount):
		maxAngle += optimizeAngleInterval
		maxVertexDistance += optimizeDistanceInterval
		optCount += 1
	elif(pointCount < optimizeCount && optCount > optimizeCount):
		maxAngle -= optimizeAngleInterval
		maxVertexDistance -= optimizeDistanceInterval
		optCount -= 1
	
	#add new points
	if(emit):
		if(pointCount == 0):
			addPoint()
			addPoint()
		if(pointCount == 1):
			insertPoint()
		
		var add = false
		var sqrDistance = (points[1].transform.origin - get_global_transform().origin).length_squared()
		
		if(sqrDistance > minVertexDistance * minVertexDistance):
			if(sqrDistance > maxVertexDistance * maxVertexDistance):
				add = true
			elif( rad2deg(Angle(get_global_transform().basis,points[1].transform.basis)) > maxAngle):
				add = true
		
		if(add == true):
			insertPoint()
		else:
			var t = get_global_transform()
			points[0].set(t)
	
	if(pointCount < 2):
		return
	
	#rebuild
	var alivedif = (points[pointCount-1].timeAlive - points[0].timeAlive)
	var uvMultiplier = 0
	if(alivedif != 0):
		uvMultiplier = 1/alivedif
	
	instance.clear()
	if(wireframe):
		instance.begin(VS.PRIMITIVE_LINE_STRIP,null)
	else:
		instance.begin(VS.PRIMITIVE_TRIANGLE_STRIP,null)
	
	for i in range(pointCount):
		var p = points[i]
		var ratio = p.getRatio(lifeTime)
		var width = p.getWidth(startWidth,endWidth)
		
		var uvRatio = (p.timeAlive - points[0].timeAlive)*uvMultiplier
		var c = Color(startColor.to_html()).linear_interpolate(endColor,uvRatio)
		
		if(segments <= 2 || tube == false):
			var _v = Vector3(0,width/2,0)
			var t = p.transform
			var v1 = t.xform( _v)
			var v2 = t.xform(-_v)
			var n = Vector3(0,0,1)
			
			instance.set_color(c)
			instance.set_normal(n)
			instance.set_uv(Vector2(uvRatio,0))
			instance.add_vertex(v1)
			
			instance.set_color(c)
			instance.set_normal(n)
			instance.set_uv(Vector2(uvRatio,1))
			instance.add_vertex(v2)
				
		else:
			if(i > 0):
				var p2 = points[i-1]
				var t2 = p2.transform.looking_at(p.transform.origin,Vector3(0,1,0))
				var t = p.transform;
				
				if(i < pointCount-1):
					var next = points[i+1]
					t = t.looking_at(next.transform.origin,Vector3(0,1,0))
				else:
					var last = points[i-1]
					t = last.transform.looking_at(t.origin,Vector3(0,1,0))
				
				var ratio2 = p2.getRatio(lifeTime)
				var width2 = p2.getWidth(startWidth,endWidth)
				
				var uvRatio2 = (p2.timeAlive - points[0].timeAlive)*uvMultiplier
				var c2 = Color(startColor.to_html()).linear_interpolate(endColor,uvRatio2)
				
				for s in range(segments,0,-1):
					
					var _v = segPos(s,width)
					var v1 = t.xform(_v)
					var n = t.basis.xform(_v.normalized())
					
					var _v2 = segPos(s,width2)
					var v2 = t2.xform(_v2)
					var n2 = t2.basis.xform(_v2.normalized())
					
					instance.set_normal(n2)
					instance.set_color(c2)
					instance.set_uv(Vector2(uvRatio,uvRatio2))
					instance.add_vertex(v2)
					
					instance.set_normal(n)
					instance.set_color(c)
					instance.set_uv(Vector2(uvRatio2,uvRatio))
					instance.add_vertex(v1)
				
				var _v = segPos(0,width2)
				
				instance.set_normal(t2.basis.xform(_v.normalized()))
				instance.set_color(c)
				instance.set_uv(Vector2(uvRatio2,uvRatio))
				instance.add_vertex(t2.xform(_v))
				
				var _v = segPos(0,width)
				
				instance.set_normal(t.basis.xform(_v.normalized()))
				instance.set_color(c)
				instance.set_uv(Vector2(uvRatio2,uvRatio))
				instance.add_vertex(t.xform(_v))
			else: #begining cap
				var p2 = points[i+1]
				var t = p.transform.looking_at(p2.transform.origin,Vector3(0,1,0))
				var fn = t.basis.xform(Vector3(0,0,1))
				
				for s in range(segments,0,-1):
					
					var _v = segPos(s,width)
					var v1 = t.xform(_v)
					var n = t.basis.xform(((_v+fn)/2).normalized())
					
					instance.set_normal(fn)
					instance.set_color(c)
					instance.set_uv(Vector2(0,0))
					instance.add_vertex(t.origin+(fn*cap_pointyness*(1-ratio)))
					
					instance.set_normal(n)
					instance.set_color(c)
					instance.set_uv(Vector2(0,uvRatio))
					instance.add_vertex(v1)
				
				
				var _v = segPos(0,width)
				var v1 = t.xform(_v)
				var n = t.basis.xform(((_v+fn)/2).normalized())
				
				instance.set_normal(fn)
				instance.set_color(c)
				instance.set_uv(Vector2(0,0))
				instance.add_vertex(t.origin+(fn*cap_pointyness*(1-ratio)))
				
				instance.set_normal(n)
				instance.set_color(c)
				instance.set_uv(Vector2(0,uvRatio))
				instance.add_vertex(v1)
					
			#end cap
			if(i == pointCount-1):
				var p2 = points[pointCount-2]
				var t = p2.transform.looking_at(p.transform.origin,Vector3(0,1,0))
				var fn = t.basis.xform_inv(Vector3(0,0,1))
			
				for s in range(segments):
				
					var _v = segPos(s,width)
					var v1 = t.xform(_v)
					var n = t.basis.xform(((_v+fn)/2).normalized())
					
					instance.set_normal(fn)
					instance.set_color(c)
					instance.set_uv(Vector2(0,0))
					instance.add_vertex(t.origin+(fn*cap_pointyness*(1-ratio)))
					
					instance.set_normal(n)
					instance.set_color(c)
					instance.set_uv(Vector2(0,uvRatio))
					instance.add_vertex(v1)
				
				var _v = segPos(0,width)
				var v1 = t.xform(_v)
				var n = t.basis.xform(((_v+fn)/2).normalized())
				
				instance.set_normal(fn)
				instance.set_color(c)
				instance.set_uv(Vector2(0,0))
				instance.add_vertex(t.origin+(fn*cap_pointyness*(1-ratio)))
				
				instance.set_normal(n)
				instance.set_color(c)
				instance.set_uv(Vector2(0,uvRatio))
				instance.add_vertex(v1)
	instance.end()


