class_name LevelClearScreen extends Control;


@onready var score_lbl : Label = %ScoreLbl;
@onready var time_lbl : Label = %TimeLbl;
@onready var continue_btn : Button = %ContinueBtn;
@onready var exit_btn : Button = %ExitBtn;


# NOTE: in the level clear screen, time should be the score in the current level,
# not the total score
func set_score(score: int) -> void:
	score_lbl.text = 'Score: %d' % score;


# NOTE: in the level clear screen, time should be the time in the current level,
# not the total time
func set_time(time: float) -> void:
	time_lbl.text = 'Time: %s' % Globals.display_time(time);
