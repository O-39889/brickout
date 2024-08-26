# no idea how to name it lol
class_name MainLevelTemplate extends Node;


const SCORE_CHANGE_SPEED := 10; # framerate dependent i don't care lmao


var display_score : int = GameProgression.score:
	get:
		return display_score;
	set(value):
		display_score = value;
		score_match = display_score == GameProgression.score;
		update_score_counter();

## Set to true when the display score reaches the actual score,
## set to false when they don't match and it's necessary
## to update the display score.
var score_match : bool = true;

@onready var score_lbl : Label = %ScoreLbl;
@onready var lives_lbl : Label = %LivesLbl;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().min_size = Vector2i(1024, 576);
	EventBus.score_changed.connect(func(_amount: int) -> void:
		score_match = false);
	EventBus.lives_changed.connect(func() -> void:
		update_lives_counter());
	update_score_counter();
	update_lives_counter();


func update_score_counter() -> void:
	score_lbl.text = "Score: " + "%06d" % display_score;


func update_lives_counter() -> void:
	lives_lbl.text = "Lives: " + str(GameProgression.lives);


func _process(delta: float) -> void:
	if not score_match:
		display_score = int(move_toward(display_score, GameProgression.score, SCORE_CHANGE_SPEED));
