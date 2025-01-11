class_name PauseMenu extends Control;


@onready var pause_lbl : Label = %PauseLabel;
@onready var level_number_lbl : Label = %LevelNumberLbl;
# lmao misnomer now it's actually only for score earned
# in this particular level
@onready var level_name_lbl : Label = %LevelNameLbl;
@onready var continue_btn : Button = %ContinueBtn;
@onready var exit_btn : Button = %ExitBtn;
# a confirmation dialog
@onready var confirmation_dialog : ConfirmationDialog = %ConfirmationDialog as ConfirmationDialog;

var previous_mouse_captured : bool;
var dialog_pos_setter : Callable; # 🗿


func _on_exit_btn_pressed() -> void:
	if dialog_pos_setter != null:
		dialog_pos_setter.call(confirmation_dialog);
	confirmation_dialog.popup();


func _on_confirmation_dialog_canceled() -> void:
	pass # Replace with function body.


func _on_confirmation_dialog_confirmed() -> void:
	get_tree().set_pause(false);
	GameProgression.exit_to_menu();
