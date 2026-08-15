@abstract
class_name Enemy
extends Node2D

signal hit_bullet(area)
signal death(id, area)

var id = 0

@abstract
func update(_dict: Dictionary) -> Vector2

