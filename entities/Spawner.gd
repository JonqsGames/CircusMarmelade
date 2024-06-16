extends Node2D
const CHARACTER = preload("res://entities/character.tscn")

@export var left_side = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if left_side:
		for c in self.get_children():
			c.position.x = -c.position.x
	$Sprite2D.flip_h = !left_side
	self.spawn()

func spawn():
	var c = CHARACTER.instantiate()
	c.left_side = left_side
	$SpawnPoint.add_child(c)
	c.dead.connect(self.spawn,CONNECT_ONE_SHOT)
