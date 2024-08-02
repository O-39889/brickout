extends Node;


# TODO: update score counter to the real value immediately when reaching
# new life
const EXTRA_LIFE_MULTIPLIER : int = 25000;


@onready var score : int = 0:
	get:
		return score;
	set(value):
		score = maxi(value, 0);
		if score >= (extra_lives_earned + 1) * EXTRA_LIFE_MULTIPLIER:
			lives += 1;
			extra_lives_earned += 1;
		EventBus.score_changed.emit();

@onready var lives : int = 3:
	get:
		return lives;
	set(value):
		lives = maxi(value, 0);
		EventBus.lives_changed.emit();

@onready var extra_lives_earned : int = score / EXTRA_LIFE_MULTIPLIER;


func _ready():
	EventBus.life_lost.connect(_on_life_lost);


func _physics_process(delta):
	get_window().title = str(score);


func _on_life_lost():
	lives -= 1;
