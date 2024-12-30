extends Node;


signal ball_lost(ball: Ball);
signal ball_target_speed_idx_changed;

signal ball_collision(ball_1: Ball, ball_2: Ball);

signal brick_hit(brick: Brick, by: Node2D);
# just because of the freaking shapecast
signal brick_destroyed(brick: Brick, by: Node2D);

signal projectile_collided(projectile: Projectile, with: CollisionObject2D);

signal barrier_hit;

signal powerup_collected(powerup: Powerup);
# TODO: remove the score amount parameter?
signal score_changed(amount: int);

signal life_lost;

# wait a sec this isn't even emitted anywhere lmao
signal lives_changed;

signal level_cleared;
signal game_overed;

# some might probably be unused
signal fade_start_started;
signal fade_start_finished;
signal fade_end_started;
signal fade_end_finished;
