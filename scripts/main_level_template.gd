# no idea how to name it lol
class_name MainLevelTemplate extends Node;


# so it's apparently 10 per 1/60s frame which is 600 per second
# which is 1.(6) seconds for 1000 points for a ball
const SCORE_CHANGE_SPEED := 10; # framerate dependent i don't care lmao

const TIMER_CONTAINER_PACKED := preload("res://scenes/gui/timer_container.tscn");
const LEVEL_CLEAR_PACKED := preload("res://scenes/gui/level_clear_screen.tscn");
const GAME_OVER_PACKED := preload("res://scenes/gui/game_over_screen.tscn");


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

var timers : Dictionary = {
	Powerup.TimedPowerup.StickyPaddle: null,
	Powerup.TimedPowerup.AcidBall: null,
	Powerup.TimedPowerup.GhostPaddle: null,
	Powerup.TimedPowerup.PaddleFreeze: null,
};

@onready var score_lbl : Label = %ScoreLbl;
@onready var lives_lbl : Label = %LivesLbl;
@onready var timer_lbl : Label = %LevelTime;
@onready var barrier_indicator : Label = %BarrierIndicator;

@onready var main_container : MarginContainer = %UglyWorkaround;
@onready var timers_container : Container = %PowerupTimersContainer;

@onready var fader : Fader = %Fader;

@onready var game_viewport : SubViewport = %GameVPort;
# GETS SET BEFORE READY
# so you gotta first change the current level in the game progression
# then load this and it will do everything itself
@onready var lvl : MainLevel = GameProgression.current_level;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(is_instance_valid(lvl), "Level gameplay scene not provided by the GameProgression singleton");
	lvl.template = self;
	game_viewport.add_child(lvl);
	
	EventBus.score_changed.connect(func(_amount: int) -> void:
		score_match = false);
	# ???
	EventBus.lives_changed.connect(update_lives_counter);
	EventBus.powerup_collected.connect(_on_powerup_collected);
	EventBus.barrier_hit.connect(barrier_indicator.hide);

	fader.fade_in();
	update_score_counter();
	update_lives_counter();


func update_score_counter() -> void:
	score_lbl.text = "Score: " + "%06d" % display_score;


func update_lives_counter() -> void:
	lives_lbl.text = "Lives: " + str(GameProgression.lives);


func show_game_over() -> void:
	clear_timers();
	var gover_node := GAME_OVER_PACKED.instantiate() as GameOverScreen;
	main_container.add_child(gover_node);
	gover_node.restart_btn.pressed.connect(
		GameProgression.new_game.bind(
			GameProgression.current_level_idx));
	gover_node.exit_btn.pressed.connect(
		GameProgression.exit_after_game_over);
	gover_node.set_score(GameProgression.score);
	


func show_level_clear() -> void:
	clear_timers();
	var clear_node := LEVEL_CLEAR_PACKED.instantiate() as LevelClearScreen;
	# also bind signals ofc
	main_container.add_child(clear_node);
	clear_node.continue_btn.pressed.connect(
		GameProgression.next_level);
	clear_node.exit_btn.pressed.connect(get_tree().quit);
	# TODO: score and time only for the current level
	clear_node.set_score(lvl.points_earned);
	clear_node.set_time(lvl.time_passed);



func add_or_extend_timer(timer: Timer, what: Powerup.TimedPowerup) -> void:
	if timers[what] == null:
		timers[what] = TIMER_CONTAINER_PACKED.instantiate() as TimerContainer;
		timers[what].assigned_powerup = what;
		timers[what].bound_timer = timer;
		timers[what].tree_exiting.connect(remove_timer.bind(what));
		var children := timers_container.get_children();
		if children.is_empty():
			timers_container.add_child(timers[what]);
		else:
			timers_container.add_child(timers[what]);
			timers_container.move_child(timers[what], mini(
				timers_container.get_child_count(), what
			));


func remove_timer(what: Powerup.TimedPowerup) -> void:
	if is_instance_valid(timers[what]):
		timers[what].queue_free();
	timers[what] = null;


func clear_timers() -> void:
	for id in Powerup.TimedPowerup:
		remove_timer(Powerup.TimedPowerup[id]);


func _on_powerup_collected(powerup: Powerup) -> void:
	match powerup.id:
		&'sticky_paddle':
			add_or_extend_timer(lvl.paddle.sticky_timer,
				Powerup.TimedPowerup.StickyPaddle);
		&'acid_ball':
			add_or_extend_timer(lvl.ball_component.acid_timer,
				Powerup.TimedPowerup.AcidBall);
		&'paddle_freeze':
			add_or_extend_timer(lvl.paddle.frozen_timer,
				Powerup.TimedPowerup.PaddleFreeze);
		&'barrier':
			barrier_indicator.show();


func _process(delta: float) -> void:
	if not score_match:
		display_score = int(move_toward(display_score, GameProgression.score, SCORE_CHANGE_SPEED));
	timer_lbl.text = "Time: " + Globals.display_time(lvl.time_passed);
