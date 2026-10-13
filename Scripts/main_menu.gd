extends Control

func _on_start_game_pressed() -> void:
	# The story intro plays first and then loads Main.tscn itself
	get_tree().change_scene_to_file("res://Scenes/Menus/StoryIntro.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
