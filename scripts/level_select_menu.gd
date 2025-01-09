extends VBoxContainer;


const LEVEL_BUTTON_PACKED : PackedScene = preload("res://scenes/gui/level_choose_button.tscn");


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.should_fade_level_select or true:
		Globals.should_fade_level_select = false;
		var level_list : Container = %LevelList;
		for i in GameProgression.level_campaign.size():
			var btn : LevelChooseButton = LEVEL_BUTTON_PACKED.instantiate();
			btn.num = i + 1;
			btn.pressed.connect(GameProgression.new_game.bind(
				mini(i, GameProgression.level_campaign.size() - 1)
			));
			btn.disabled = i > GameProgression.max_level_reached;
			level_list.add_child(btn);
			
	%ExitBtn.position.y = (%ChooseLevelLbl.size.y - %ExitBtn.size.y) / 2.0;


func _on_exit_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
