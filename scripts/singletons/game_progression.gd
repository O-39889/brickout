extends Node;

var debug_test_lbl : Label;
var debug_test_thing := {};

# TASK: maybe have the campaign switch not between the top-level
# level scenes (the ones with the GUI and everything) but instead only
# the gameplay ones in the subviewport?
# ANSWER: no, it's probably gonna be a painful mess with disconnecting
# and reconnecting everything so I'll just do the current method
# of reloading the template scene each time

const EXTRA_LIFE_MULTIPLIER : int = 25000;
const INITIAL_LIVES : int = 3;

const LEVEL_TEMPLATE_PACKED : PackedScene = preload("res://scenes/levels_new/main_level_template.tscn");
const TITLE_PACKED : PackedScene = preload("res://scenes/title_screen.tscn");

# why if I could just have another JSON file lmao
# but whatever
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
# NOTE: nevermind the previous comment? I don't know lol
# but it's the last level that's been reached in the current
# savefile session: it doesn't have to change when
# the new level is opened
# so, for example, when you beat level # 8, it might
# increase this to 9 either immediately when you clear
# the level # 8 or both: when exiting to main menu
# and before loading a new one
# I think the former would be more reliable
var max_level_reached : int = 0;

## The index of a level where the game session started.
var session_started_idx : int = 0;


func reset_current_data(lvl_idx : int = 0) -> void:
	set_current_level(lvl_idx);
	score = 0;
	last_level_score = score;
	
	lives = INITIAL_LIVES;
	last_level_lives = lives;
	
	time_total = 0.0;
	last_level_time_total = time_total;
	
	extra_lives_earned = 0;
	last_level_extra_lives_earned = extra_lives_earned;
	
	session_started_idx = 0;


func _ready() -> void:
	EventBus.life_lost.connect(_on_life_lost);
	for i in level_campaign.size():
		level_campaign[i] = main_campaign_dir.path_join(
			level_campaign[i] + '.tscn'
		);
	max_level_reached = 0;
	reset_current_data();
	# super useful little debug label thing innit bruv
	if OS.is_debug_build():
		debug_test_lbl = Label.new();
		debug_test_lbl.position = Vector2(15, 15);
		debug_test_lbl.top_level = true;
		debug_test_lbl.z_index = 1997;
		set_debug_test_lbl_thingy_amogus_228_olepa_bing_chilling_yes();
		get_tree().process_frame.connect(set_debug_test_lbl_thingy_amogus_228_olepa_bing_chilling_yes)
		await get_tree().process_frame;
		add_child(debug_test_lbl);


## If idx = -1, then it just uses the current index
func set_current_level(idx: int = -1) -> void:
	if idx >= 0:
		current_level_idx = idx;
	current_level = load(level_campaign[current_level_idx]).instantiate();
	max_level_reached = maxi(current_level_idx, max_level_reached);


func set_next_current_level() -> void:
	set_current_level(GameProgression.current_level_idx + 1);


## Updates last level stats to match the current ones.
func update_last_level_stats() -> void:
	last_level_score = score;
	last_level_lives = lives;
	last_level_time_total = time_total;
	last_level_extra_lives_earned = extra_lives_earned;


## Restores the current stats to match the last level stats.
func restore_to_last_level_stats() -> void:
	score = last_level_score;
	lives = last_level_lives;
	time_total = last_level_time_total;
	extra_lives_earned = last_level_extra_lives_earned;


#region Switching between levels and everything

## Gets called after starting a new game by pressing a button in the
## level select menu.
## Also gets called on pressing the resta(u)r(an)t button on the
## game over screen (but in this case, it would have the level index
## as the current one)
func new_game(level_idx: int = 0) -> void:
	session_started_idx = level_idx;
	reset_current_data(level_idx);
	current_level = load(level_campaign[current_level_idx]).instantiate();
	get_tree().change_scene_to_packed(LEVEL_TEMPLATE_PACKED);
	has_progress = true;

## Gets called after pressing a continue button on the level clear screen
## (not immediately, after a fade out transition but still)
func next_level() -> void:
	# NOTE: the next level idx
	# is updated in the main level script!!!!!!!!!
	# update the last level stats to match the current ones
	# (because the current level just becomes the last one duh)
	update_last_level_stats();
	# and of course it's the next level
	#set_next_current_level();
	# of course update the max level reached
	# NOTE: maybe have it update somewhere else
	# e. g. after clearing the level immediately
	#max_level_reached = maxi(max_level_reached, current_level_idx);
	# and load the next levle
	current_level = load(level_campaign[current_level_idx]).instantiate();
	get_tree().change_scene_to_packed(LEVEL_TEMPLATE_PACKED);

## Called when exiting to main menu after clearing a level.
func exit_after_clear() -> void:
	# update last 
	update_last_level_stats();
	# again, don't need to do any of that bc
	# the main level script already did that when
	# the level is cleared
	#current_level_idx += 1;
	#max_level_reached = maxi(current_level_idx, max_level_reached);
	# don't exactly need this either?
	#current_level = load(level_campaign[current_level_idx]).instantiate();
	get_tree().change_scene_to_packed(TITLE_PACKED);

## Called when exiting to main menu in the middle of a level.
## It just discards all mofidications to the save data
## on the current level and restores them back to the stats
## from the last level.
func exit_to_menu() -> void:
	# NOTE: maybe instead ignore everything and just
	# have it do this when presing the continue button?
	#score = last_level_score;
	#lives = last_level_lives;
	#time_total = last_level_time_total;
	#extra_lives_earned = last_level_extra_lives_earned;
	get_tree().change_scene_to_packed(TITLE_PACKED);


## Just continuing the game with the Continue button,
## whether after clearing the level or not.
## Making this because I first gotta figure out
## how to even tell apart those two.
## Now, two other continue methods were unused and were
## thus removed.
func just_continue() -> void:
	# maybe I don't have to? Like, when you quit
	# in the middle of lvl 5, then it's gonna be the same
	# as if you just cleared lvl 4 and exited after that
	# just start at the current level okda
	# in the current level idx
	# and restore the last level stats
	if not has_progress:
		printerr('No progress saved, this cannot continue');
		return;
	restore_to_last_level_stats();
	# just let's remember again:
	# when we clear the level, it sets the current level
	# to the next one and doesn't change that until
	# we clear the next one so even if we leave then it's
	# still kinda fine
	current_level = load(level_campaign[current_level_idx]).instantiate();
	get_tree().change_scene_to_packed(LEVEL_TEMPLATE_PACKED);


## Called when pressing a main menu button on the game over screen.
# TODO: actually make some kind of local leaderboard where the player
# could just put their score and it would also have stuff like
# the time when the session was started (TODO: add!) and ended? and stats
# and username (add funny username easter eggs!)
func exit_after_game_over() -> void:
	has_progress = false;
	# I don't think the specific index is really important in here
	reset_current_data(0);
	
	get_tree().change_scene_to_packed(TITLE_PACKED);

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


func set_debug_test_lbl_thingy_amogus_228_olepa_bing_chilling_yes() -> void:
	var dict := {
		'score' : score,
		'lives' : lives,
		'time' : String.num(time_total, 1),
		'current_level': current_level.level_name\
			if is_instance_valid(current_level) else 'Nope',
		'current_level_idx' : current_level_idx,
		'has progress':['Nope','Yep'][int(has_progress)],
		'extra lives': extra_lives_earned,
		'last level score' : last_level_score,
		'last level lives' : last_level_lives,
		'last level time' : String.num(last_level_time_total, 1),
		'last level extra lives' : last_level_extra_lives_earned,
		'max level reached' : max_level_reached,
	};
	var lal := '';
	for k in dict.keys():
		lal += '%s : %s\n' % [k, dict[k]];
	debug_test_lbl.text = lal;
