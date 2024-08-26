class_name TitleScreenBallComponent extends BallComponent;


func _ready():
	Ball.reset_target_speed();
	EventBus.ball_collision.connect(handle_collision);


func spawn_balls(amount: int):
	for i in amount:
		var new_ball : Ball = BALL_PACKED.instantiate();
		new_ball.position = get_viewport_rect().size / 2;
		level.add_ball(new_ball);
		new_ball.launch(Vector2.RIGHT.rotated(randf() * TAU));
		await get_tree().create_timer(0.333).timeout;
