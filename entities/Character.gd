extends CharacterBody2D
enum Status {
	PREPARING,
	STABLE,
	PRESSING,
	AERIAL,
	PILED,
	CRASHED,
	BASE
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var status = Status.PREPARING :
	set(value):
		status = value
		print("Character change status to %s" % Status.keys()[status])
		if status == Status.CRASHED:
			self.rotation = 0.0
@export var left_side = false

var relative_stick_position = Vector3.ZERO
var plank : Plank = null
var move_speed = 256.0
var rotate_speed = 7.0

signal dead()

func _on_pressing_done():
	if self.status == Status.PRESSING:
		self.status = Status.STABLE
		plank.release.connect(self._on_tilt_done,CONNECT_ONE_SHOT)

func _on_tilt_done():
	self.status = Status.AERIAL
	self.velocity.y = -ActionPressManager.get_boost_value()
	ActionPressManager.boost()
func _ready():
	if left_side:
		$Sprite2D.flip_h = true
func _process(delta):
	# DEBUG
	$DebugR.text = "R %.2f" % [self.rotation]

func _physics_process(delta):
	# Add the gravity.
	var v = move_speed * delta
	var r = rotate_speed * delta
	match status:
		Status.PREPARING:
			if Input.is_action_pressed("left"):
				self.velocity.x -= v
			if Input.is_action_pressed("right"):
				self.velocity.x += v
			move_and_slide()
			if abs(position.x) > 64.0:
				self.velocity.x = -sign(self.global_position.x) * 200.0
				ActionPressManager.action_peak_height = abs(self.global_position.y)
				self.status = Status.AERIAL
		Status.AERIAL:
			if Input.is_action_pressed("left"):
				self.velocity.x -= v
			if Input.is_action_pressed("right"):
				self.velocity.x += v
			var pr = $RotationCenter.global_position
			if Input.is_action_pressed("rotate_positive"):
				#self.global_transform = self.global_transform * Transform2D().translated(-$RotationCenter.position).rotated(r)
				self.rotate(r)
				#self.position.x -= sin(r) * $RotationCenter.position.y
				#self.position.y -= cos(r) * $RotationCenter.position.y
			elif Input.is_action_pressed("rotate_negative"):
				#self.global_transform = self.global_transform * Transform2D().translated(-$RotationCenter.position).rotated(-r)
				self.rotate(-r)
				#self.position.x += sin(r) * $RotationCenter.position.y
				#self.position.y += cos(r) * $RotationCenter.position.y
			else:
				# Lerp to stable
				self.rotation = lerp_angle(self.rotation,0.0,delta * 0.6)
			pr = $RotationCenter.global_position - pr
			self.global_position += -pr
			var accel_grav = gravity * delta
			if velocity.y < 0.0 and velocity.y > -accel_grav:
				# Reach peak
				ActionPressManager.action_peak_height = abs(self.global_position.y)
				print("Character reach peak at %s" % [ActionPressManager.action_peak_height])
			velocity.y += accel_grav
			if move_and_slide():
				for i in range(self.get_slide_collision_count()):
					var col : KinematicCollision2D = get_slide_collision(i)
					var c : Node2D = col.get_collider()
					var is_falling = velocity.y >= 0.0
					if is_falling:
						if c.is_in_group("Character"):
							if (c.status == Status.PILED or c.status == Status.BASE) and col.get_local_shape().name == "FeetShape":
								self.status = Status.PILED
								self.reparent(c)
								dead.emit()
								break
							else:
								self.status = Status.CRASHED
								self.reparent(c)
								dead.emit()
								break
						elif c.name == "Plank":
							# check relative x position
							plank = c
							relative_stick_position = plank.to_local(self.global_position)
							var x = relative_stick_position.x
							if left_side:
								x = -x
							if x > 0 and col.get_local_shape().name == "FeetShape":
								self.status = Status.PRESSING
								self.velocity = Vector2.ZERO
								plank.release.connect(self._on_pressing_done,CONNECT_ONE_SHOT | CONNECT_DEFERRED)
								#Rotate
								c.tilt(left_side)
								break
							else:
								status = Status.CRASHED
								self.reparent(c)
								dead.emit()
								break
						elif c.name == "Board" and col.get_local_shape().name == "FeetShape":
							self.status = Status.PREPARING
							self.velocity = Vector2.ZERO
							break
						else:
							status = Status.CRASHED
							self.reparent(c)
							dead.emit()
							break
		Status.STABLE, Status.PRESSING:
			self.rotation = lerp_angle(self.rotation,0.0,delta * 1.5)
			self.global_position = plank.to_global(relative_stick_position)
		Status.PILED:
			self.position = lerp(self.position,Vector2(0.0,-40.0),delta * 2.0)
			self.rotate((randf() - 0.5) * delta * 0.7)
			self.rotation = lerp_angle(self.rotation,0.0,delta * 1.0)
	
func die():
	self.queue_free()
