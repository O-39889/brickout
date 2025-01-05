extends Node;

# TASK: maybe have the campaign switch not between the top-level
# level scenes (the ones with the GUI and everything) but instead only
# the gameplay ones in the subviewport?
# ANSWER: no, it's probably gonna be a painful mess with disconnecting
# and reconnecting everything so I'll just do the current method
# of reloading the template scene each time

const EXTRA_LIFE_MULTIPLIER : int = 25000;
const INITIAL_LIVES : int = 3;

const LEVEL_TEMPLATE_PACKED : PackedScene = preload("res://scenes/levels_new/main_level_template.tscn");


@export_dir var main_campaign_dir : String;
# idk what to do with this lol bruh
# ig just an array of level scene names or something
@export var level_campaign : PackedStringArray;


var current_level : MainLevel;
var current_level_idx : int;
# just to choose whether to have the continue button enabled or not
# and also whether to s	how the prompt when starting a new game
var has_progress : bool = false;

# I hate how you do that onready stuff for no reason altogether
# like, just set these to default values
# and then just set those to 
var score : int = 0;
var lives : int = INITIAL_LIVES;
var time_total : float = 0.0;
# For keeping track of how many lives the player has already earned during
# the current playthrough.
@warning_ignore("integer_division")
var extra_lives_earned : int = score / EXTRA_LIFE_MULTIPLIER;

## Variables for keeping track of what score the player had when starting
## a level (to reset to that value when exiting to main menu in the middle
## of a game).
var last_level_score : int = score;
var last_level_lives : int = lives;
var last_level_time_total : float = time_total;
var last_level_extra_lives_earned : int = extra_lives_earned;


# this stuff should be never reset to 0 in fact, I think
# I mean, until we actually start working with save files
# but for now nopesies
var max_level_reached : int = 0;


func _ready() -> void:
	EventBus.life_lost.connect(_on_life_lost);
	for i in level_campaign.size():
		level_campaign[i] = main_campaign_dir.path_join(
			level_campaign[i] + '.tscn'
		);
	set_current_level(0); # TODO: load from autosave lmao
	score = 0; # TODO: load from autosave
	last_level_score = score;
	lives = INITIAL_LIVES; # TODO: load from autosave
	last_level_lives = lives;
	time_total = 0.0; # TODO: load from ottosave
	last_level_time_total = time_total;
	extra_lives_earned = score / EXTRA_LIFE_MULTIPLIER; # TODO: nah this is perfect
	last_level_extra_lives_earned = extra_lives_earned;

## If idx = -1, then it just takes in the current index
func set_current_level(idx: int = -1) -> void:
	if idx >= 0:
		current_level_idx = idx;
	current_level = load(level_campaign[current_level_idx]).instantiate();
	max_level_reached = maxi(current_level_idx, max_level_reached);

#region Switching between levels and everything
# first, I'm just gonna make those work
# and after that I'll refactor it and move duplicating code
# into separate functions if needed

## Gets called after starting a new game by pressing a button in the
## level select menu.
## Also gets called on pressing the resta(u)r(an)t button on the
## game over screen (but in this case, it would have the level index
## as the current one)
func new_game(level_idx: int = 0) -> void:
	score = 0;
	lives = INITIAL_LIVES;
	extra_lives_earned = 0;
	time_total = 0.0;
	
	last_level_score = score;
	last_level_lives = lives;
	last_level_time_total = time_total;
	last_level_extra_lives_earned = extra_lives_earned;
	
	time_total = 0.0;
	current_level_idx = level_idx;
	time_total = 0.0;
	current_level = load(level_campaign[current_level_idx]).instantiate();
	get_tree().change_scene_to_file("res://scenes/levels_new/main_level_template.tscn");
	has_progress = true;

## Gets called after pressing a continue button on the level clear screen
## (not immediately, after a fade out transition but still)
func next_level() -> void:
	# update the last level stats to match the current ones
	# (because the current level just becomes the last one duh)
	last_level_score = score;
	last_level_lives = lives;
	last_level_time_total = time_total;
	last_level_extra_lives_earned = extra_lives_earned;
	# and of course it's the next level
	current_level_idx += 1;
	# of course update the max level reached
	max_level_reached = maxi(max_level_reached, current_level_idx);
	# and load the next levle
	current_level = load(level_campaign[current_level_idx]).instantiate();
	get_tree().change_scene_to_file("res://scenes/levels_new/main_level_template.tscn");

## Called when exiting to main menu after clearing a level.
func exit_after_clear() -> void:
	last_level_score = score;
	last_level_lives = lives;
	last_level_time_total = time_total;
	last_level_extra_lives_earned = extra_lives_earned;
	
	current_level_idx += 1;
	max_level_reached = maxi(current_level_idx, max_level_reached);
	current_level = load(level_campaign[current_level_idx]).instantiate();

## Called when exiting to main menu in the middle of a level.
## TODO: MAKE THIS ACTUALLY WORK, JUST SCREW IT WE'RE DOING THIS MY WAY
# 1) keep a separate time and score and lives tracker for right before starting a levle
# 2) when leaving the level, display a prompt saying that all progress on the current level will be lost
# 3) just set the progress to that thing
func exit_to_menu() -> void:
	score = last_level_score;
	lives = last_level_lives;
	time_total = last_level_time_total;
	extra_lives_earned = last_level_extra_lives_earned;
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn");

## Called when clicking the Continue button after clearing the level
## and exiting to main menu.
func continue_after_clear() -> void:
	pass

## Called when clicking the Continue button after exiting to the main menu
## in the middle of a level, erasing all progress beforehand.
func continue_after_exit() -> void:
	score = last_level_score;
	lives = last_level_lives;
	extra_lives_earned = last_level_extra_lives_earned;
	time_total = last_level_time_total;
	# TODO: load the level etc

## Called when pressing a main menu button on the game over screen.
# TODO: actually make some kind of local leaderboard where the player
# could just put their score and it would also have stuff like
# the time when the session was started (TODO: add!) and ended? and stats
# and username (add funny username easter eggs!)
func exit_after_game_over() -> void:
	has_progress = false;
	
	score = 0;
	lives = INITIAL_LIVES;
	time_total = 0.0;
	extra_lives_earned = 0;
	
	last_level_score = score;
	last_level_lives = lives;
	last_level_time_total = time_total;
	last_level_extra_lives_earned = extra_lives_earned;
	
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn");

#endregion


# FIXED: now the extra_lives_earned variable is properly
# incremented (in increment_lives() though)
func set_score(value: int) -> void:
	var old_val := score;
	score = value;
	if score >= (extra_lives_earned + 1) * EXTRA_LIFE_MULTIPLIER:
		increment_lives();
	EventBus.score_changed.emit(value - old_val);


func add_score(value: int) -> void:
	set_score(score + value);


func set_lives(value: int) -> void:
	lives = maxi(0, value);
	# oh wait a sec so it already emits that
	# whether we lose or gain a life
	EventBus.lives_changed.emit();


func increment_lives() -> void:
	set_lives(lives + 1);
	extra_lives_earned += 1; # !!!


func decrement_lives() -> void:
	set_lives(lives - 1);


func _on_life_lost() -> void:
	decrement_lives();
