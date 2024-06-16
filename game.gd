extends Node2D


func intro_done():
	print("Game starting")
	GameManager.status = GameManager.Status.PAUSE
