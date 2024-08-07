extends Node2D;


const ARMOR_TEXTURE := preload("res://assets/brick-edges-placeholder.png");


var brick : RegularBrick;


func _draw():
	if not brick.is_reinforced:
		return
	var sides := [];
	var corners := [];
	if brick.protected_sides & RegularBrick.Direction.Top:
		sides.append(0);
	if brick.protected_sides & RegularBrick.Direction.Right:
		sides.append(1);
	if brick.protected_sides & RegularBrick.Direction.Bottom:
		sides.append(2);
	if brick.protected_sides & RegularBrick.Direction.Left:
		sides.append(3);
	if 0 in sides and 1 in sides:
		corners.append(0);
	if 1 in sides and 2 in sides:
		corners.append(1);
	if 2 in sides and 3 in sides:
		corners.append(2);
	if 3 in sides and 0 in sides:
		corners.append(3);
		
	var draw_rect := Rect2(); # prolly lol
	draw_rect.position.x = brick.global_position.x - brick.width / 2;
	draw_rect.position.y = brick.global_position.y - brick.height / 2;
	draw_rect.size.x = brick.width;
	draw_rect.size.y = brick.height;
	
	for side_idx in sides:
		var src_rect := Rect2();
		src_rect.position.x = 0;
		src_rect.position.y = brick.height * side_idx;
		src_rect.size.x = brick.width;
		src_rect.size.y = brick.height;
		draw_texture_rect_region(ARMOR_TEXTURE, draw_rect, src_rect);
	
	for corner_idx in corners:
		var src_rect := Rect2();
		src_rect.position.x = brick.width;
		src_rect.position.y = brick.height * corner_idx;
		src_rect.size.x = brick.width;
		src_rect.size.y = brick.height;
		draw_texture_rect_region(ARMOR_TEXTURE, draw_rect, src_rect);
