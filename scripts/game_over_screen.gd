class_name GameOverScreen extends Control;


@onready var score_lbl : Label = %ScoreLbl;
@onready var restart_btn : Button = %RestartBtn;
@onready var exit_btn : Button = %ExitBtn;


func _ready() -> void:
	if randf() < 0.00333333:
		if randf() < 0.42069 * 0.42069:
			$"Label".text = "Game Joever";
		else:
			restart_btn.text = "Restaurant"
