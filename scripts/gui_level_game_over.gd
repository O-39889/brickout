class_name LevelGameOverGUI extends Control


@onready var score_label : Label = $VBoxContainer/ScoreTotal;
@onready var restart_btn : Button = $VBoxContainer/Restart;
@onready var main_menu_btn : Button = $VBoxContainer/MainMenu;


func _ready():
	if randf() < 0.003333333:
		if randf() < 0.42069 * 0.42069:
			$VBoxContainer/Label.text = 'Game Joever';
		else:
			restart_btn.text = 'Restaurant';
