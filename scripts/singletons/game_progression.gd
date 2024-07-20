extends Node;


@onready var score : int = 0:
	get:
		return score;
	set(value):
		score = maxi(value, 0);
		EventBus.score_changed.emit();

@onready var lives : int = 3:
	get:
		return lives;
	set(value):
		lives = maxi(value, 0);
		EventBus.lives_changed.emit();


func _ready():
	EventBus.life_lost.connect(_on_life_lost);


func _on_life_lost():
	lives -= 1;
