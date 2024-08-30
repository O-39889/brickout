class_name TItleScreen extends Node;


#const LEVEL_MENU_PACKED : PackedScene = ...
#const SETTINGS_PACKED : PackedScene = ...
#const HELP_PACKED : PackedScene = ...
#const STATS_PACKED : PackedScene = ...


func _ready() -> void:
	%MeLbl.text += str(Time.get_datetime_dict_from_system()['year']);


func _on_new_game_btn_pressed() -> void:
	pass # Replace with function body.


func _on_continue_btn_pressed() -> void:
	pass # Replace with function body.


func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.


func _on_help_btn_pressed() -> void:
	pass # Replace with function body.


func _on_stats_btn_pressed() -> void:
	pass # Replace with function body.


func _on_quit_btn_pressed() -> void:
	get_tree().quit();
