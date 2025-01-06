class_name PauseMenu extends Control;


@onready var pause_lbl : Label = %PauseLabel;
@onready var level_number_lbl : Label = %LevelNumberLbl;
@onready var level_name_lbl : Label = %LevelNameLbl;
@onready var continue_btn : Button = %ContinueBtn;
@onready var exit_btn : Button = %ExitBtn;

var previous_mouse_captured : bool;
