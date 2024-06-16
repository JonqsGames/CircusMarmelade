extends CenterContainer

@onready var score = $HBoxContainer/Score

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	score.text = "%6.0f" % [ScoreManager.score]
