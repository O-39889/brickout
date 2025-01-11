extends VBoxContainer;


const LEVEL_BUTTON_PACKED : PackedScene = preload("res://scenes/gui/level_choose_button.tscn");
@onready var confirm_dialog : ConfirmationDialog = %ConfirmationDialog;
var selected_level_idx : int;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.should_fade_level_select or true:
		Globals.should_fade_level_select = false;
		var level_list : Container = %LevelList;
		for i in GameProgression.level_campaign.size():
			var btn : LevelChooseButton = LEVEL_BUTTON_PACKED.instantiate();
			btn.num = i + 1;
			btn.pressed.connect(amogus.bind(
				mini(i, GameProgression.level_campaign.size() - 1)
			));
			btn.disabled = i > GameProgression.max_level_reached;
			level_list.add_child(btn);
			
	%ExitBtn.position.y = (%ChooseLevelLbl.size.y - %ExitBtn.size.y) / 2.0;


# idk I ran out of names a long hwile ago
func amogus(i: int) -> void:
	if GameProgression.has_progress:
		# ummm what exactly am I supposed to do
		# I'm thinking of probably some kind of smart ahh
		# way to do this with awaiting signals or idk lool
		# or maybe just
		selected_level_idx = i; # tada (I guess)
		# TODO: probably also make it centered in the
		# menu too ig
		confirm_dialog.popup();
	else:
		GameProgression.new_game(i);


func _on_exit_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_confirmation_dialog_canceled() -> void:
	pass # Replace with function body.


func _on_confirmation_dialog_confirmed() -> void:
	GameProgression.new_game(selected_level_idx);
