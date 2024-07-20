extends Node;


@onready var score : int = 0:
	get:
		return score;
	set(value):
		score = maxi(value, 0);
		EventBus.score_changed.emit();
