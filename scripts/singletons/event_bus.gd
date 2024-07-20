extends Node;


signal ball_lost(ball: Ball);
signal ball_target_speed_idx_changed;

signal brick_hit(brick: Brick, ball: Ball);
signal brick_destroyed(brick: Brick, ball: Ball);

signal barrier_hit;

signal powerup_collected(powerup: Powerup);

signal score_changed;

signal life_lost;
signal lives_changed;
