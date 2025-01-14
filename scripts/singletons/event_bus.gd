extends Node;


signal ball_lost(ball: Ball);
signal ball_target_speed_idx_changed;

signal ball_collision(ball_1: Ball, ball_2: Ball);

# just because of the freaking shapecast
signal brick_hit(brick: Brick, by: Node2D);
signal brick_destroyed(brick: Brick, by: Node2D);

signal projectile_collided(projectile: Projectile, with: CollisionObject2D);

signal barrier_hit;

signal powerup_collected(powerup: Powerup);
# TODO: remove the score amount parameter?
# actually I need that lol
signal score_changed(amount: int);

# not sure whether the former is actually required but whatever ig
signal life_lost;
signal lives_changed;

# TODO: can add a parameter on whether this is a title
# screen level or a regular in-game level
signal level_cleared;
# unused
signal game_overed;
