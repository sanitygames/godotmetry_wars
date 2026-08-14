extends Node2D

const PLAYER_SPEED_DELTA := 4.0
const VEC2_DEFAULT := Vector2(9999, 9999)
const ENTITY_SIZE = {
	"player": 1,
	"bomb": 3,
	"bullet": 100,
	"enemy": 100,
	"death_explosion": 100,
	"bullet_explosion": 100,
}

const SHOT_INTERVAL := 0.10

@export var bullet: PackedScene
@export var hit_particle: PackedScene

var nodes: Array[Node] = []
var flags: PackedByteArray = []
var positions: PackedVector2Array = []
var forces: PackedVector2Array = []

var shot_timer := 0.0

var sh_idx := 0
var hp_idx := 0

@onready var grid = $Grid
@onready var player = $Player


func _ready() -> void:
	for key in ENTITY_SIZE:
		for __i in ENTITY_SIZE[key]:
			nodes.append(null)
			flags.append(0)
			positions.append(VEC2_DEFAULT)
			forces.append(Vector2.ZERO)

	nodes[0] = $Player  # PLAYER
	flags[0] = 1
	positions[0] = Vector2(400, 300)
	forces[0] = Vector2(180, -7000)

	for i in range(4, 24):  # BULLET
		var _b = bullet.instantiate()
		add_child(_b)
		nodes[i] = _b
		_b.id = i
		_b.hit.connect(_on_bullet_hit)
		flags[i] = 0
		positions[i] = VEC2_DEFAULT
		forces[i] = Vector2(60, 4000)

	for i in range(104, 204):  # ENEMY
		nodes[i] = null
		flags[i] = 0
		positions[i] = VEC2_DEFAULT
		forces[i] = Vector2.ZERO
	for i in range(204, 304):  # DEATH_EXPLOSION
		nodes[i] = null
		flags[i] = 0
		positions[i] = VEC2_DEFAULT
		forces[i] = Vector2.ZERO
	for i in range(304, 324):  # BULLET_EXPLOSION
		var _hp = hit_particle.instantiate()
		_hp.hit_finished.connect(_on_hit_particle_finished)
		_hp.id = i
		add_child(_hp)
		nodes[i] = _hp
		flags[i] = 0
		positions[i] = VEC2_DEFAULT
		forces[i] = Vector2(100, -5000)


func _physics_process(_delta: float) -> void:
	# PLAYER
	var dp = Vector2.ZERO
	if Input.is_action_pressed("left"):
		dp.x -= PLAYER_SPEED_DELTA
	if Input.is_action_pressed("right"):
		dp.x += PLAYER_SPEED_DELTA
	if Input.is_action_pressed("up"):
		dp.y -= PLAYER_SPEED_DELTA
	if Input.is_action_pressed("down"):
		dp.y += PLAYER_SPEED_DELTA
	positions[0] += dp
	positions[0].x = clamp(positions[0].x, 0, 800)
	positions[0].y = clamp(positions[0].y, 0, 600)

	nodes[0].look_at(get_global_mouse_position())

	nodes[0].position = positions[0]

	# BULLETS
	shot_timer += _delta
	if shot_timer > SHOT_INTERVAL:
		shot_timer = 0.0
		sh_idx += 1
		var idx = (sh_idx % 20) + 4
		flags[idx] = 1
		nodes[idx].position = player.position
		nodes[idx].rotation = player.rotation
		positions[idx] = player.position

	for i in range(4, 24):
		if flags[i] == 1:
			var np = nodes[i].update(_delta)
			positions[i] = np

	grid.set_data(flags, positions, forces)
	grid.update(_delta)


func _on_bullet_hit(id: int, pos: Vector2, body: Node2D) -> void:
	flags[id] = 0
	nodes[id].position = VEC2_DEFAULT
	positions[id] = VEC2_DEFAULT

	for i in 20:
		hp_idx += 1
		var idx = (hp_idx % 20) + 304
		if flags[idx] == 0:
			flags[idx] = 1
			positions[idx] = pos
			nodes[idx].position = positions[idx]
			nodes[idx].emitting = true
			break


func _on_hit_particle_finished(id: int) -> void:
	flags[id] = 0
	positions[id] = VEC2_DEFAULT

# var bullets := []
# var bidx := 0

# var timer := 0.0

# var forces := []

# var players := PackedVector2Array()

# func _ready() -> void:
# 	for i in 50:
# 		var _b = bullet.instantiate()
# 		_b.position = Vector2(9999, 9999)
# 		_b.hitted.connect(_on_bullet_hitted)
# 		add_child(_b)
# 		bullets.append(_b)

# 	players.append($Player.position)

# func _physics_process(_delta: float) -> void:
# 	forces.clear()
# 	var dp = Vector2.ZERO

# 	if Input.is_action_pressed("left"):
# 		dp.x -= PLAYER_SPEED_DELTA
# 	if Input.is_action_pressed("right"):
# 		dp.x += PLAYER_SPEED_DELTA
# 	if Input.is_action_pressed("up"):
# 		dp.y -= PLAYER_SPEED_DELTA
# 	if Input.is_action_pressed("down"):
# 		dp.y += PLAYER_SPEED_DELTA

# 	forces.append([$Player.position + Vector2(80, 80), 150, dp.length() * 490])
# 	# $Grid.set_force($Player.position + Vector2(80, 80) + dp * 10, 150, dp.length() * 3)

# 	$Player.position.x = clamp($Player.position.x + dp.x, 0, 800)
# 	$Player.position.y = clamp($Player.position.y + dp.y, 0, 600)

# 	$Player.look_at(get_global_mouse_position())

# 	timer += _delta
# 	if timer > 0.08:
# 		timer = 0.0
# 		bullets[bidx % 50].position = $Player.position
# 		bullets[bidx % 50].rotation = $Player.rotation
# 		bidx += 1

# 	for i in 50:
# 		forces.append([bullets[i].position + Vector2(80, 80), 60, 2000])

# 	if Input.is_action_just_pressed("click_right"):
# 		forces.append([$Player.position + Vector2(80, 80), 200, -255000])

# 	$Grid.set_forces(forces)

# 	prints($Player.position, players[0])

# func _on_bullet_hitted(pos: Vector2) -> void:
# 	var _p = hit_particle.instantiate()
# 	_p.position = pos
# 	_p.finished.connect(_on_particle_finished.bind(_p))
# 	add_child(_p)
# 	_p.emitting = true

# func _on_particle_finished(p: Node) -> void:
# 	p.queue_free()
