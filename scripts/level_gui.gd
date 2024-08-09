class_name LevelGUI extends CanvasLayer;
# This entire script looks horrible. My goodness gracious!


const COUNTER_UPDATE_FREQUENCY = 0.016; # poka chto
const COUNTER_CHANGE_PER_UPDATE = 10;
const TIMER_THING_PACKED := preload('res://scenes/gui/timer_container.tscn');
 

var level : MainLevel;
var score_counter : float = 0.0;
var score_countdown_active : bool = false;
var clear_gui : LevelClearGUI;
var timers : Dictionary = {
	Powerup.TimedPowerup.StickyPaddle: null,
	Powerup.TimedPowerup.AcidBall: null,
	Powerup.TimedPowerup.GhostPaddle: null,
	Powerup.TimedPowerup.PaddleFreeze: null,
};

@onready var old_lives : int = GameProgression.lives;

@onready var score_label : Label = $Regular/Score;
@onready var lives_label : Label = $Regular/Lives;
@onready var timers_container : VBoxContainer = $Regular/TimersEtc;

@onready var current_display_score : int = GameProgression.score:
	get:
		return current_display_score;
	set(value):
		current_display_score = value;
		set_score_label();
@onready var target_display_score : int = current_display_score;


func _ready():
	EventBus.score_changed.connect(_on_score_changed);
	EventBus.lives_changed.connect(_on_lives_changed);
	EventBus.life_lost.connect(_on_life_lost);
	set_lives_label();
	set_score_label();


func show_level_clear():
	if clear_gui == null:
		clear_gui = load('res://scenes/gui/level_clear.tscn').instantiate();
		add_child(clear_gui);
		clear_gui.time_lbl.text = 'Time: ' + Globals.display_time(level.time_passed);
		clear_gui.score_lbl.text = 'Score: %d' % level.points_earned;
		clear_gui.next_btn.pressed.connect(next_level);
		clear_gui.menu_btn.pressed.connect(main_menu);
		for t in timers:
			remove_timer(t);
		timers.clear();


func next_level():
	pass


func main_menu():
	pass


func add_or_extend_timer(timer: Timer, what: Powerup.TimedPowerup):
	if timers[what] == null:
		timers[what] = TIMER_THING_PACKED.instantiate() as TimerContainer;
		timers[what].assigned_powerup = what;
		timers[what].bound_timer = timer;
		timers[what].tree_exiting.connect(func():
			timers[what] = null;)
		#timers_container.add_child(timers[what]);
		var children = timers_container.get_children();
		if children.is_empty():
			timers_container.add_child(timers[what]);
		else:
			timers_container.add_child(timers[what]);
			# I think this is kinda genius lmao
			timers_container.move_child(timers[what], mini(
				timers_container.get_child_count(), what
			));
	else:
		pass


func remove_timer(what: Powerup.TimedPowerup):
	if timers[what] != null:
		timers[what].queue_free();
		timers[what] = null;


func clear_timers():
	for t in timers:
		remove_timer(t);


func set_score_label():
	score_label.text = 'Score: ' + ('%06d' % current_display_score);


func set_lives_label():
	lives_label.text = 'Lives: ' + str(GameProgression.lives);


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


func _on_score_changed(_amount: int):
	target_display_score = GameProgression.score;
	score_countdown_active = true;


func _on_lives_changed():
	set_lives_label();
	# that means we've gained an extra life! skip points scrolling, if there was any
	if old_lives < GameProgression.lives:
		score_countdown_active = false;
		score_counter = 0.0;
		target_display_score = GameProgression.score;
		current_display_score = GameProgression.score;
	old_lives = GameProgression.lives;


func _on_life_lost():
	clear_timers();
