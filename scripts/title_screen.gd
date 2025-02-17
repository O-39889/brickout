class_name TitleScreen extends Node;


# bs !! this one doesn't work!!!
const TITLE_PACKED : PackedScene = preload("res://scenes/title_screen.tscn");
const LEVEL_SELECT_PACKED : PackedScene = preload("res://scenes/gui/level_select_menu.tscn");
#const SETTINGS_PACKED : PackedScene = ...	
#const HELP_PACKED : PackedScene = ...
#const STATS_PACKED : PackedScene = ...


func _ready() -> void:
	%MeLbl.text += str(Time.get_datetime_dict_from_system()['year']);
	%MeLbl.text = '%s\n%s' % [VersionManager.VERSION, %MeLbl.text];
	%LevelEditorBtn.get_parent().remove_child(%LevelEditorBtn);
	%ContinueBtn.disabled = !GameProgression.has_progress;
	%MeLbl.text = 'Version %s' % %MeLbl.text;


func _on_new_game_btn_pressed() -> void:
	get_tree().change_scene_to_packed(LEVEL_SELECT_PACKED);


func _on_continue_btn_pressed() -> void:
	GameProgression.just_continue();


func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.


func _on_help_btn_pressed() -> void:
	pass # Replace with function body.


func _on_stats_btn_pressed() -> void:
	pass # Replace with function body.


func _on_quit_btn_pressed() -> void:
	get_tree().quit();
