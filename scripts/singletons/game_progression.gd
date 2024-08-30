extends Node;

# TASK: maybe have the campaign switch not between the top-level
# level scenes (the ones with the GUI and everything) but instead only
# the gameplay ones in the subviewport?

const EXTRA_LIFE_MULTIPLIER : int = 25000;

# idk what to do with this lol bruh
# ig just an array of level scene names or something
var level_campaign : Array[String] = [];
var current_level : MainLevel;
var current_level_idx : int = 0;


@onready var score : int = 0:
	get:
		return score;
	set(value):
		var old_val = score;
		score = maxi(value, 0);
		if score >= (extra_lives_earned + 1) * EXTRA_LIFE_MULTIPLIER:
			lives += 1;
			extra_lives_earned += 1;
		EventBus.score_changed.emit(score - old_val);

@onready var lives : int = 3:
	get:
		return lives;
	set(value):
		lives = maxi(value, 0);
		EventBus.lives_changed.emit();
@warning_ignore("integer_division")
@onready var extra_lives_earned : int = score / EXTRA_LIFE_MULTIPLIER;


func _ready():
	EventBus.life_lost.connect(_on_life_lost);


func _on_life_lost():
	lives -= 1;
	if lives == 0:
		pass # gameover !! haha
