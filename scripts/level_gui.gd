extends CanvasLayer;
# This entire script looks horrible. My goodness gracious!

const COUNTER_UPDATE_FREQUENCY = 0.016; # poka chto
const COUNTER_CHANGE_PER_UPDATE = 10;
 

var score_counter : float = 0.0;
var score_countdown_active : bool = false;

@onready var score_label : Label = $Score;
@onready var lives_label : Label = $Lives;
@onready var current_display_score : int = GameProgression.score:
	get:
		return current_display_score;
	set(value):
		current_display_score = value;
		score_label.text = 'Score: ' + ('%06d' % current_display_score);
@onready var target_display_score : int = current_display_score;


# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.score_changed.connect(_on_score_changed);
	EventBus.lives_changed.connect(_on_lives_changed);


func _process(delta):
	if score_countdown_active:
		score_counter += delta;
		if score_counter >= COUNTER_UPDATE_FREQUENCY:
			score_counter = 0.0;
			_countdown_tick();


func _countdown_tick():
	if current_display_score < target_display_score:
		current_display_score = mini(target_display_score,
			current_display_score + COUNTER_CHANGE_PER_UPDATE);
	elif current_display_score > target_display_score:
		current_display_score = maxi(target_display_score,
			current_display_score - COUNTER_CHANGE_PER_UPDATE);
	else:
		score_countdown_active = false;


func _on_score_changed():
	target_display_score = GameProgression.score;
	score_countdown_active = true;


func _on_lives_changed():
	lives_label.text = 'Lives: ' + str(GameProgression.lives);
