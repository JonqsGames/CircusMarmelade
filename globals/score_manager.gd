extends Node

var score = 0.0

signal score_up()
signal score_down()

func add_point(value):
	score += value
	score_up.emit()
func remove_point(value):
	score -= value
	score_down.emit()
