extends CharacterBody2D
class_name Character
enum Status {
	PREPARING,
	STABLE,
	PRESSING,
	AERIAL,
	PILED,
	CRASHED,
	BASE,
	HOLDING,
	FALLING
}
var textures = [
	preload("res://img/clown.png"),
	preload("res://img/clownb.png"), 
	preload("res://img/clownc.png")
]
var sounds = [
	preload("res://audio/he.wav"),
	preload("res://audio/he2.wav"),
	preload("res://audio/he3.wav")
]
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var spin_progress : TextureProgressBar = $SpinProgress
var r_value_score = 0.0 :
	set(value):
		r_value_score = value
		if abs(r_value_score) >= 1.0:
			print("Score Boost !")
			ActionPressManager.time_scale_stop_time = 0.25
			$AnimationTree.set("parameters/Figure/blend_position", Vector2(randf() - 0.5,randf() - 0.5) * 2.0)
			$AnimationTree["parameters/playback"].travel("Figure")
			score += 100.0
			r_value_score -= sign(r_value_score)
		#else:
			#print(r_value_score)

@export var status = Status.PREPARING :
	set(value):
		r_value_score = 0.0
		if status == Status.AERIAL:
			$/root/Game/Camera2D.shake(0.0002 * ActionPressManager.action_peak_height,0.03 * ActionPressManager.action_peak_height,0.02 * ActionPressManager.action_peak_height)
		
		if value == Status.CRASHED:
			self.rotation = 0.0
		elif value == Status.PILED:
			if status != Status.HOLDING:
				$AudioStreamPlayer2D.stream = sounds.pick_random()
				$AudioStreamPlayer2D.play()
			self.position = Vector2(0.0,-40.0)
		elif value == Status.FALLING:
			if status == Status.PILED:
				ScoreManager.remove_point(score)
			self.set_collision_mask_value(2,false)
			self.reparent($/root/Game)
			for c in self.get_children():
				if c is Character:
					c.status = Status.FALLING
		status = value
		#print("Character change status to %s" % Status.keys()[status])
			

@export var left_side = false
var relative_stick_position = Vector3.ZERO
@onready var plank : Plank = $"/root/Game/Balance/Plank"

var move_speed = 256.0
var rotate_speed = 7.0

var tilt_speed = 0.0

var score = 500.0

signal dead()

func get_aerial_speed():
	return self.velocity.length()

func get_relative_d():
	var x = relative_stick_position.x
	if left_side:
		x = -x
	return x

func _on_pressing_done():
	if self.status == Status.PRESSING:
		self.status = Status.STABLE
		plank.release.connect(self._on_tilt_done,CONNECT_ONE_SHOT)

func _on_tilt_done():
	self.status = Status.AERIAL
	self.velocity.y = -ActionPressManager.get_boost_value() * get_relative_d()/plank.get_half_size()
	ActionPressManager.boost()
func _ready():
	$Sprite2D.texture = textures.pick_random()
	if left_side:
		$Sprite2D.flip_h = true
func _process(delta):
	# DEBUG
	spin_progress.global_position = self.global_position + Vector2(-8.0,30.0)
	$DebugR.text = "R %.2f" % [self.rotation]
	if status != Status.AERIAL:
		spin_progress.value = 0.0
	else:
		spin_progress.scale.x = 0.5 if r_value_score > 0.0 else -0.5
		spin_progress.value = r_value_score

func _physics_process(delta):
	# Add the gravity.
	$AnimationTree.set("parameters/BlendWalk/blend_position", float(abs(velocity.x) > 0.0))
	var v = move_speed * delta
	var r = rotate_speed * delta
	match status:
		Status.PREPARING:
			if GameManager.status == GameManager.Status.GAME:
				if Input.is_action_pressed("left"):
					self.velocity.x -= v
				if Input.is_action_pressed("right"):
					self.velocity.x += v
				move_and_slide()
				if abs(position.x) > 64.0:
					self.velocity.x = -sign(self.global_position.x) * 200.0
					ActionPressManager.action_peak_height = abs(self.global_position.y) * get_relative_d()/plank.get_half_size()
					self.status = Status.AERIAL
		Status.FALLING:
			self.rotate(tilt_speed * delta)
			var accel_grav = gravity * delta
			velocity.y += accel_grav
			if move_and_slide():
				status = Status.CRASHED
				dead.emit()
		Status.AERIAL:
			if Input.is_action_pressed("left"):
				self.velocity.x -= v
			if Input.is_action_pressed("right"):
				self.velocity.x += v
			var pr = $RotationCenter.global_position
			if Input.is_action_pressed("rotate_positive"):
				$AnimationTree.set("parameters/flying_rot/blend_position", 1.0)
				#self.global_transform = self.global_transform * Transform2D().translated(-$RotationCenter.position).rotated(r)
				self.rotate(r)
				self.r_value_score += r / (PI*2.0)
				#self.position.x -= sin(r) * $RotationCenter.position.y
				#self.position.y -= cos(r) * $RotationCenter.position.y
			elif Input.is_action_pressed("rotate_negative"):
				$AnimationTree.set("parameters/flying_rot/blend_position", 1.0)
				#self.global_transform = self.global_transform * Transform2D().translated(-$RotationCenter.position).rotated(-r)
				self.rotate(-r)
				self.r_value_score -= r / (PI*2.0)
				#self.position.x += sin(r) * $RotationCenter.position.y
				#self.position.y += cos(r) * $RotationCenter.position.y
			else:
				$AnimationTree.set("parameters/flying_rot/blend_position", 0.0)
				# Lerp to stable
				self.rotation = lerp_angle(self.rotation,0.0,delta * 0.6)
			pr = $RotationCenter.global_position - pr
			self.global_position += -pr
			var accel_grav = gravity * delta
			if velocity.y < 0.0 and velocity.y > -accel_grav:
				# Reach peak
				ActionPressManager.action_peak_height = abs(self.global_position.y)
				#print("Character reach peak at %s" % [ActionPressManager.action_peak_height])
			velocity.y += accel_grav
			if move_and_slide():
				for i in range(self.get_slide_collision_count()):
					var col : KinematicCollision2D = get_slide_collision(i)
					var c : Node2D = col.get_collider()
					var is_falling = velocity.y >= 0.0
					if is_falling:
						if c.is_in_group("Character"):
							if (c.status == Status.PILED or c.status == Status.BASE) and col.get_local_shape().name == "FeetShape":
								self.reparent(c)
								self.rotation = 0.0
								self.status = Status.PILED
								ScoreManager.add_point(score)
								c.status = Status.HOLDING
								dead.emit()
								break
							else:
								var tilt = -sign(self.global_position.x - c.global_position.x) * 0.5
								c.tilt_speed = tilt
								self.status = Status.CRASHED
								self.reparent(c)
								dead.emit()
								break
						elif c is Plank:
							# check relative x position
							#plank = c
							relative_stick_position = plank.to_local(self.global_position)
							var x = get_relative_d()
							if x > 0 and col.get_local_shape().name == "FeetShape":
								self.status = Status.PRESSING
								self.velocity = Vector2.ZERO
								#print("[Character] Landing : %.2f" % [global_position.y])
								ActionPressManager.set_landing_time()
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
							self.rotation = 0.0
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
		Status.PILED, Status.HOLDING:
			if self.get_parent() is Character:
				if abs(self.rotation) > PI * 0.04:
					tilt_speed -= sign(self.rotation) * delta * 0.8
				else:
					tilt_speed += (randf() - 0.5) * delta * 0.4
					tilt_speed *= 0.999
				self.rotate(tilt_speed * delta)
				self.rotation = lerp_angle(self.rotation,0.0,delta * 1.0)
				if abs(self.rotation) > PI * 0.05:
					if self.get_parent().get_parent() is Character:
						self.get_parent().status = Status.PILED
					else:
						self.get_parent().status = Status.BASE
					self.status = Status.FALLING
	
func die():
	self.queue_free()
