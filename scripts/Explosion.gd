class_name Explosion extends ShapeCast2D;


func _on_animated_sprite_2d_frame_changed():
	if $AnimatedSprite2D.frame == 13:
		var tween := create_tween();
		tween.tween_property(self, 'modulate', Color.TRANSPARENT, 0.085);


func _on_animated_sprite_2d_animation_finished():
	queue_free();
