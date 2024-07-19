class_name Global extends Node


enum PowerupPoolType {
	Default,
	Simple,
	Custom = -1,
};


# lmao i swear it feels okay this way
const MOUSE_SENSITIVITY = 2.718281828459045;
## Vertical paddle offset from the bottom of the screen, in pixels.
const PADDLE_OFFSET = 50;


# mostly used for power-up effects
# allows for stacking effect times
# for example: set_val is the initial value which gets set as the wait time
# if the timer is not working or added to the wait time but clamped by max_val
# for example, if set_val = 15, max_val = 20, then initially the timer will
# be set to 15; if another effect is triggered when time remaining is 10, then
# the total would be 15 + 10 = 25 but clamped to max_val so it'd be 20
static func start_or_extend_timer(t: Timer, set_val: float, max_val: float = set_val):
	if t.is_stopped():
		t.start(set_val);
	else:
		t.start(minf(t.time_left + set_val, max_val));
