extends CharacterBody2D
enum Status {
	PREPARING,
	STABLE,
	PRESSING,
	AERIAL,
	PILED,
	CRASHED
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var status = Status.PREPARING :
	set(value):
		status = value
		print("Character change status to %s" % Status.keys()[status])
		if status == Status.CRASHED:
			self.queue_free.call_deferred()
@export var left_side = false

var relative_stick_position = Vector3.ZERO
var plank : Plank = null
var move_speed = 86.0

signal dead()

func _on_pressing_done():
	if self.status == Status.PRESSING:
		self.status = Status.STABLE
		plank.release.connect(self._on_tilt_done,CONNECT_ONE_SHOT)

func _on_tilt_done():
	self.status = Status.AERIAL
	self.velocity.y = -ActionPressManager.get_boost_value()
	ActionPressManager.boost()

func _physics_process(delta):
	# Add the gravity.
	match status:
		Status.PREPARING:
			if Input.is_action_pressed("left"):
				self.velocity.x -= move_speed * delta
			if Input.is_action_pressed("right"):
				self.velocity.x += move_speed * delta
			move_and_slide()
			if abs(position.x) > 64.0:
				ActionPressManager.action_peak_height = abs(self.global_position.y)
				self.status = Status.AERIAL
		Status.AERIAL:
			if Input.is_action_pressed("left"):
				self.velocity.x -= move_speed * delta
			if Input.is_action_pressed("right"):
				self.velocity.x += move_speed * delta
			var accel_grav = gravity * delta
			if velocity.y < 0.0 and velocity.y > -accel_grav:
				# Reach peak
				ActionPressManager.action_peak_height = abs(self.global_position.y)
				print("Character reach peak at %s" % [ActionPressManager.action_peak_height])
			velocity.y += accel_grav
			if move_and_slide():
				for i in range(self.get_slide_collision_count()):
					var c : Node2D = get_slide_collision(i).get_collider()
					var is_falling = velocity.y >= 0.0
					if is_falling:
						if c.is_in_group("Character"):
							if c.status == Status.PILED:
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
							if x > 0:
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
						else:
							status = Status.CRASHED
							self.reparent(c)
							dead.emit()
							break
		Status.STABLE, Status.PRESSING:
			self.global_position = plank.to_global(relative_stick_position)
	
