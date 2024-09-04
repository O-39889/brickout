extends Node;

# TASK: maybe have the campaign switch not between the top-level
# level scenes (the ones with the GUI and everything) but instead only
# the gameplay ones in the subviewport?

const EXTRA_LIFE_MULTIPLIER : int = 25000;

const LEVEL_TEMPLATE_PACKED : PackedScene = preload("res://scenes/levels_new/main_level_template.tscn");


@export_dir var main_campaign_dir : String;
# idk what to do with this lol bruh
# ig just an array of level scene names or something
@export var level_campaign : PackedStringArray;


var current_level : MainLevel;
var current_level_idx : int;

@onready var score : int = 0:
	get:
		return score;
	set(value):
		_set_score(value, false);

@onready var lives : int = 3:
	get:
		return lives;
	set(value):
		lives = maxi(value, 0);
		EventBus.lives_changed.emit();
@onready var time_total : float = 0.0;
@warning_ignore("integer_division")
@onready var extra_lives_earned : int = score / EXTRA_LIFE_MULTIPLIER;


func _ready() -> void:
	EventBus.life_lost.connect(_on_life_lost);
	for i in level_campaign.size():
		level_campaign[i] = main_campaign_dir.path_join(
			level_campaign[i] + '.tscn'
		);
	set_current_level(0);


func set_current_level(idx: int = -1) -> void:
	if idx >= 0:
		current_level_idx = idx;
		current_level = load(level_campaign[current_level_idx]).instantiate();


func new_game(level_idx: int = 0) -> void:
	set_current_level(level_idx);
	load_level();


func load_level() -> void:
	get_tree().change_scene_to_file("res://scenes/levels_new/main_level_template.tscn");
	# tada! ...???


func _on_life_lost() -> void:
	lives -= 1;
	if lives == 0:
		pass # gameover !! haha


func _set_score(value: int, silent: bool = false) -> void:
	var old_val = score;
	score = maxi(value, 0);
	if score >= (extra_lives_earned + 1) * EXTRA_LIFE_MULTIPLIER:
		lives += 1;
		extra_lives_earned += 1;
	if not silent:
		EventBus.score_changed.emit(score - old_val);
