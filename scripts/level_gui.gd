extends CanvasLayer;
# This entire script looks horrible. My goodness gracious!

const COUNTER_UPDATE_FREQUENCY = 0.025; # poka chto
const COUNTER_CHANGE_PER_UPDATE = 10;


@onready var score_label : Label = $Score;
@onready var score_timer : Timer = $ScoreTimer;
@onready var current_display_score : int = GameProgression.score:
	get:
		return current_display_score;
	set(value):
		current_display_score = value;
		score_label.text = 'Score: ' + ('%06d' % current_display_score);
@onready var target_display_score : int = current_display_score;


# Called when the node enters the scene tree for the first time.
func _ready():
	score_timer.wait_time = COUNTER_UPDATE_FREQUENCY;
	EventBus.score_changed.connect(_on_score_changed);


func _on_score_changed():
	target_display_score = GameProgression.score;
	if score_timer.is_stopped():
		score_timer.start();


func _on_score_timer_timeout():
	if current_display_score < target_display_score:
		current_display_score = mini(target_display_score,
			current_display_score + COUNTER_CHANGE_PER_UPDATE);
	elif current_display_score > target_display_score:
		current_display_score = maxi(target_display_score,
			current_display_score - COUNTER_CHANGE_PER_UPDATE);
	else:
		score_timer.stop();
