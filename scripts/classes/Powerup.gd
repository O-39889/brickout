class_name Powerup extends RefCounted;


enum TimedPowerup {
	StickyPaddle,
	AcidBall,
	GhostPaddle,
	PaddleFreeze,
};


const TIMED_POWERUPS := [
	&'sticky_paddle',
	&'acid_ball',
	&'ghost_paddle',
	&'paddle_freeze',
];

const POWERUP_POOL = {
	&'good': [
		&'double_balls',
		&'paddle_enlarge',
		&'add_ball',
		&'triple_ball',
		&'sticky_paddle',
		&'barrier',
		&'fire_ball',
		&'acid_ball',
		&'add_points_100',
		&'add_points_200',
		&'add_points_500',
		&'gun',
		&'finish_level',
	],
	&'neutral': [
		&'ball_speed_up',
		&'ball_slow_down',
	],
	&'bad': [
		&'paddle_shrink',
		&'pop_ball',
		&'pop_all_balls',
		&'ghost_paddle',
		&'paddle_freeze',
	],
};

## Pool of power-ups that would randomly appear in case the game is deemed
## "stuck" (for example, relatively few bricks left and the ball hasn't
## broken a brick in a long time), and it could try to summon one
## of these power-ups in order to help the player
const SALVAGE_POOL := {
	&'add_ball': 1.0,
	&'gun': 1.0,
	&'triple_ball': 0.333333,
	&'finish_level': 0.09999999999,
	&'fire_ball': 0.075,
	&'acid_ball': 0.075,
};

const POWERUP_LIST = {
	&'double_balls': {
		&'name': 'Double Balls',
		&'description': 'Duplicates every ball on-screen.\nNote: there\'s still a limit of how many balls can be on-screen at the same time.',
		&'points': 200,
	},
	&'paddle_enlarge': {
		&'name': 'Enlarge Paddle',
		&'description': 'Increases the width of the paddle, making it easier to deflect the ball.',
		&'points': 150,
	},
	&'add_ball': {
		&'name': 'Add Ball',
		&'description': 'Adds another ball to play. The ball starts attached to a paddle and must be released by clicking.',
		&'points': 150,
	},
	&'triple_ball': {
		&'name': 'Triple Ball',
		&'description': 'Turns one ball into three!',
		&'points': 150,
	},
	&'sticky_paddle': {
		&'name': 'Sticky Paddle',
		&'description': 'Makes the paddle sticky, making the balls attach to it when caught. Click to release a ball from a paddle.',
		&'points': 250,
	},
	&'barrier': {
		&'name': 'Barrier',
		&'description': 'Creates a barrier at the bottom of the screen that can reflect one ball.',
		&'points': 300,
	},
	&'fire_ball': {
		&'name': 'Fire Ball',
		&'description': 'Turns balls into fire balls that explode on contact with bricks, destroying multiple at once.',
		&'points': 400,
	},
	&'acid_ball': {
		&'name': 'Acid Ball',
		&'description': 'Turns balls into acid balls that penetrate bricks freely. Some types of bricks still cannot be destroyed.',
		&'points': 500,
	},
	&'add_points_100': {
		&'name': '100 Points',
		&'description': 'Adds 100 points to the counter. Earn 25 000 poins for an extra life!',
		&'points': 100,
	},
	&'add_points_200': {
		&'name': '200 Points',
		&'description': 'Adds 200 points to the counter. Earn 25 000 poins for an extra life!',
		&'points': 200,
	},
	&'add_points_500': {
		&'name': '500 Points',
		&'description': 'Adds 500 points to the counter. Earn 25 000 poins for an extra life!',
		&'points': 500,
	},
	&'gun': {
		&'name': 'Gun',
		&'description': 'Mounts a gun on the paddle. Press the right mouse button to shoot! Remember, ammo is limited.',
		&'points': 250,
	},
	&'finish_level': {
		&'name': 'Level Finish',
		&'description': 'Finishes the level immediately. This power-up can drop when there are very few bricks left on-screen.', 
		&'points': 100,
	},
	&'ball_speed_up': {
		&'name': 'Speed Up Balls',
		&'description': 'Increases the speed of the balls.',
		&'points': 150,
	},
	&'ball_slow_down': {
		&'name': 'Slow Down Balls',
		&'description': 'Decreases the speed of the balls.',
		&'points': 150,
	},
	&'paddle_shrink': {
		&'name': 'Shrink Paddle',
		&'description': 'Decreases the size of the paddle, making it more difficult to catch and reflect balls.',
		&'points': 50,
	},
	&'pop_ball': {
		&'name': 'Pop Ball',
		&'description': 'Destroys one of the balls on the field. Cannot destroy your last ball.',
		&'points': 50,
	},
	&'pop_all_balls': {
		&'name': 'Pop All Balls',
		&'description': 'Destroys all balls on the field but one. How unfortunate!',
		&'points': 50,
	},
	&'ghost_paddle': {
		&'name': 'Ghost Paddle',
		&'description': 'Turns the paddle into a ghost state briefly. In this state, the paddle can still move but balls and powerups go right through it.',
		&'points': 50,
	},
	&'paddle_freeze': {
		&'name': 'Freeze Paddle',
		&'description': 'Freezes the paddle for a brief time. A frozen paddle cannot move, although it still can reflect balls hitting it.',
		&'points': 50,
	},
}


var id : StringName;
var type: StringName;
var name: String;
# not gonna use it and instead put just the powerup objects in a dictionary with le weight
#var weight: float = 1.0;


func _init(_id: StringName, _type: StringName, _weight: float = 1.0):
	self.id = _id;
	self.type = _type;
	#self.weight = _weight;


static func get_default_weight_pool() -> Array[Powerup]:
	var arr : Array[Powerup] = [];
	var good_weight := 1.0;
	var neutral_weight := 1.25;
	var bad_weight := float(POWERUP_POOL['good'].size()) / float(POWERUP_POOL['bad'].size()) * 0.5;
	for gp_id in POWERUP_POOL['good']:
		var gp : Powerup = Powerup.new(gp_id, 'good', good_weight);
		arr.append(gp);
	for np_id in POWERUP_POOL['neutral']:
		var np : Powerup = Powerup.new(np_id, 'neutral', neutral_weight);
		arr.append(np);
	for bp_id in POWERUP_POOL['bad']:
		var bp : Powerup = Powerup.new(bp_id, 'bad', bad_weight);
		arr.append(bp);
	return arr;
