extends Node

enum Status {
	INTRO,
	PAUSE,
	GAME,
}

var status = Status.INTRO:
	set(value):
		status = value
		match status:
			Status.GAME:
				$/root/Game/GameUI.visible = true
				$/root/Game/MenuLayer.visible = false
			Status.PAUSE:
				$/root/Game/GameUI.visible = false
				$/root/Game/MenuLayer.visible = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if status == Status.PAUSE:
		if Input.is_action_just_pressed("action"):
			status = Status.GAME
	elif status == Status.GAME:
		if Input.is_action_just_pressed("pause"):
			status = Status.PAUSE
