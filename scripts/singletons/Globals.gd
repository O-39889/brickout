class_name Global extends Node;


enum PowerupPoolType {
	Default,
	Simple,
	Custom = -1,
};


# lmao i swear it feels okay this way
const MOUSE_SENSITIVITY = 2.718281828459045;
## Vertical paddle offset from the bottom of the screen, in pixels.
const PADDLE_OFFSET = 50;
const MIN_WINDOW_SIZE := Vector2i(1024, 576);


var window_mode_saved : DisplayServer.WindowMode = DisplayServer.window_get_mode();
var should_fade_level_select : bool = true;


func _ready() -> void:
	get_window().min_size = MIN_WINDOW_SIZE;


# mostly used for power-up effects
# allows for stacking effect times
# for example: set_val is the initial value which gets set as the wait time
# if the timer is not working or added to the wait time but clamped by max_val
# for example, if set_val = 15, max_val = 20, then initially the timer will
# be set to 15; if another effect is triggered when time remaining is 10, then
# the total would be 15 + 10 = 25 but clamped to max_val so it'd be 20
func start_or_extend_timer(t: Timer, set_val: float, max_val: float = set_val):
	if t.is_stopped():
		t.start(set_val);
	else:
		t.start(minf(t.time_left + set_val, max_val));


func display_time(seconds_total: float) -> String:
	var seconds_rounded = int(seconds_total);
	var seconds_show = seconds_rounded % 60;
	@warning_ignore("integer_division") # IT'S GONNA ALWAYS BE DIVISIBLE BY 60 YOU STUPID GOOBER
	var minutes_show = (seconds_rounded - seconds_show) / 60;
	return '%01d:%02d' % [minutes_show, seconds_show];


func _input(event: InputEvent) -> void:
	if event.is_action("fullscreen_toggle") and event.pressed:
		if DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			if window_mode_saved == DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				window_mode_saved = DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED;
			DisplayServer.window_set_mode(window_mode_saved);
		else:
			window_mode_saved = DisplayServer.window_get_mode();
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN);
