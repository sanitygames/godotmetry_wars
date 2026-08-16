extends Node2D

const PLAYER_SIZE := 1
const SHOT_INTERVAL := 0.06
const SHOT_ENTITY_SIZE := 100
const HIT_PARTICLE_ENTITY_SIZE := 200
const DEATH_PARTICLE_ENTITY_SIZE := 20
const E1_ENTITY_SIZE := 20
const E2_ENTITY_SIZE := 20
const E3_ENTITY_SIZE := 5
const E9_ENTITY_SIZE := 200
const DEF_VEC2 := Vector2(9999, 9999)

const PLAYER_FORCE := Vector2(60, 100)
const SHOT_FORCE := Vector2(40, 200)
const HIT_PARTICLE_FORCE := Vector2(100, 30)
# const E1_FORCE := Vector2(100, 1500)
# const E2_FORCE := Vector2(100, 1500)
const E1_FORCE := Vector2.ZERO
const E2_FORCE := Vector2.ZERO
const E3_FORCE := Vector2(300, 600)
const E9_FORCE := Vector2.ZERO
const DEATH_PARTICLE_FORCE := Vector2(200, 300)

@export var shot_inst: PackedScene
@export var hit_particle_inst: PackedScene
@export var death_particle_inst: PackedScene
@export var e1_inst: PackedScene
@export var e2_inst: PackedScene
@export var e3_inst: PackedScene
@export var e9_inst: PackedScene

@onready var player: Entity = $Player
@onready var grid: Node2D = $Grid
@onready var score_label: Label = $UILayer/ScoreLabel

var SHOT_ENTITY_IDX_ORIGIN := 1
var HIT_PARTICLE_ENTITY_IDX_ORIGIN := 0
var DEATH_PARTICLE_ENTITY_IDX_ORIGIN := 0
var E1_IDX_ORIGIN := 1
var E2_IDX_ORIGIN := 1
var E3_IDX_ORIGIN := 1
var E9_IDX_ORIGIN := 1

var entities: Array = []
var flags: PackedByteArray = []
var positions: PackedVector2Array = []
var forces: PackedVector2Array = []

var shot_idx := 0
var shot_timer := 0.0
var hit_idx := 0
var death_idx := 0

var timer := 0.0
var e1_interval := 3.0
var e1_idx := 0
var e1_timer := 1.5
var e1_death := 0
var e2_interval := 23.3
var e2_idx := 0
var e2_timer := 0.0
var e3_interval := 64.0
var e3_idx := 0
var e3_timer := 0.0
var e9_idx := 0

var score := 0
var game_over := false


func _ready() -> void:
	for i in range(-100, 100):
		print(exp(i * 0.0001))
	Sound.is_title = false
	set_process(false)
	entities.append(player)
	flags.append(1)
	positions.append(player.position)
	forces.append(PLAYER_FORCE)

	SHOT_ENTITY_IDX_ORIGIN = entities.size()
	for i in SHOT_ENTITY_SIZE:
		var _s: Entity = shot_inst.instantiate()
		_s.position = DEF_VEC2
		_s.id = SHOT_ENTITY_IDX_ORIGIN + i
		add_child(_s)
		entities.append(_s)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(SHOT_FORCE if i % 3 == 0 else Vector2.ZERO)

	HIT_PARTICLE_ENTITY_IDX_ORIGIN = entities.size()
	for i in HIT_PARTICLE_ENTITY_SIZE:
		var _p: GPUParticles2D = hit_particle_inst.instantiate()
		_p.position = DEF_VEC2
		_p.id = HIT_PARTICLE_ENTITY_IDX_ORIGIN + i
		_p.emit_finished.connect(_on_hit_particle_emit_finished)
		add_child(_p)
		entities.append(_p)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(HIT_PARTICLE_FORCE)

	DEATH_PARTICLE_ENTITY_IDX_ORIGIN = entities.size()
	for i in DEATH_PARTICLE_ENTITY_SIZE:
		var _dp: GPUParticles2D = death_particle_inst.instantiate()
		_dp.position = DEF_VEC2
		_dp.id = DEATH_PARTICLE_ENTITY_IDX_ORIGIN + i
		_dp.emit_finished.connect(_on_death_particle_emit_finished)
		add_child(_dp)
		entities.append(_dp)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(DEATH_PARTICLE_FORCE)

	E1_IDX_ORIGIN = entities.size()
	for i in E1_ENTITY_SIZE:
		var _e1: Entity = e1_inst.instantiate()
		_e1.position = DEF_VEC2
		_e1.id = E1_IDX_ORIGIN + i
		_e1.visible = false
		_e1.e1_hit_shot.connect(_on_e1_hit_shot)
		_e1.e1_death.connect(_on_e1_death)
		add_child(_e1)
		entities.append(_e1)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(E1_FORCE)

	E2_IDX_ORIGIN = entities.size()
	for i in E2_ENTITY_SIZE:
		var _e2: Entity = e2_inst.instantiate()
		_e2.position = DEF_VEC2
		_e2.id = E2_IDX_ORIGIN + i
		_e2.visible = false
		_e2.e2_hit_shot.connect(_on_e2_hit_shot)
		_e2.e2_death.connect(_on_e2_death)
		_e2.e2_shot.connect(_on_e2_shot)
		add_child(_e2)
		entities.append(_e2)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(E2_FORCE)

	E3_IDX_ORIGIN = entities.size()
	for i in E3_ENTITY_SIZE:
		var _e3: Entity = e3_inst.instantiate()
		_e3.position = DEF_VEC2
		_e3.id = E3_IDX_ORIGIN + i
		_e3.visible = false
		_e3.e3_hit_shot.connect(_on_e3_hit_shot)
		_e3.e3_death.connect(_on_e3_death)
		_e3.e3_shot.connect(_on_e3_shot)
		add_child(_e3)
		entities.append(_e3)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(E3_FORCE)

	E9_IDX_ORIGIN = entities.size()
	for i in E9_ENTITY_SIZE:
		var _e9: Entity = e9_inst.instantiate()
		_e9.position = DEF_VEC2
		_e9.id = E9_IDX_ORIGIN + i
		_e9.visible = false
		_e9.e9_hit_shot.connect(_on_e9_hit_shot)
		_e9.e9_death.connect(_on_e9_death)
		add_child(_e9)
		entities.append(_e9)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(E9_FORCE)


func _process(delta: float) -> void:
	timer += delta
	var go = ["\nGAME OVER\n[R]etry [Q]uit", "\n\n[R]etry [Q]uit"][int(timer) % 2]
	score_label.text = "HI-SCORE:%06d\nSCORE:%06d%s" % [Score.hi_score, score, go]

	if Input.is_action_just_pressed("retry"):
		get_tree().reload_current_scene()
	if Input.is_action_pressed("quit"):
		get_tree().change_scene_to_file("res://title.tscn")


func _physics_process(delta: float) -> void:
	timer += delta
	var player_position = DEF_VEC2

	if !game_over:
		player_position = player.move(delta)
		positions[0] = player_position
		if player.is_move:
			forces[0] = PLAYER_FORCE
		else:
			forces[0] = Vector2.ZERO

	shot_timer += delta
	if shot_timer >= SHOT_INTERVAL:
		var _idx = shot_idx + SHOT_ENTITY_IDX_ORIGIN
		if flags[_idx] == 0:
			shot_timer = 0.0
			flags[_idx] = 1
			entities[_idx].rotation = player.rotation
			entities[_idx].position = player_position
		shot_idx = (shot_idx + 1) % SHOT_ENTITY_SIZE

	for i in range(SHOT_ENTITY_IDX_ORIGIN, SHOT_ENTITY_IDX_ORIGIN + SHOT_ENTITY_SIZE):
		var pos = entities[i].move(delta)
		positions[i] = pos

	e1_timer += delta
	if e1_timer >= e1_interval:
		var _idx = e1_idx + E1_IDX_ORIGIN
		if flags[_idx] == 0:
			e1_timer = 0.0
			flags[_idx] = 1
			entities[_idx].position = get_e1_position(timer)
			entities[_idx].visible = true
			entities[_idx].accell = randf_range(0.8, min(1.0 + e1_death * 0.03, 2.0))
			positions[_idx] = entities[_idx].position
		e1_idx = (e1_idx + 1) % E1_ENTITY_SIZE

	e2_timer += delta
	if e2_timer >= e2_interval:
		var _idx = e2_idx + E2_IDX_ORIGIN
		if flags[_idx] == 0:
			e2_timer = 0.0
			flags[_idx] = 1
			entities[_idx].position = get_e1_position(timer)
			entities[_idx].visible = true
			positions[_idx] = entities[_idx].position
		e2_idx = (e2_idx + 1) % E2_ENTITY_SIZE

	e3_timer += delta
	if e3_timer >= e3_interval:
		var _idx = e3_idx + E3_IDX_ORIGIN
		if flags[_idx] == 0:
			e3_timer = 0.0
			flags[_idx] = 1
			entities[_idx].position = get_e1_position(timer)
			entities[_idx].visible = true
			positions[_idx] = entities[_idx].position
		e3_idx = (e3_idx + 1) % E3_ENTITY_SIZE

	for i in range(E1_IDX_ORIGIN, E1_IDX_ORIGIN + E1_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta, {"pp": player_position})
			positions[i] = pos

	for i in range(E2_IDX_ORIGIN, E2_IDX_ORIGIN + E2_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta)
			positions[i] = pos

	for i in range(E3_IDX_ORIGIN, E3_IDX_ORIGIN + E3_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta)
			positions[i] = pos

	for i in range(E9_IDX_ORIGIN, E9_IDX_ORIGIN + E9_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta, {"pp": player_position})
			positions[i] = pos

	for i in range(
		DEATH_PARTICLE_ENTITY_IDX_ORIGIN,
		DEATH_PARTICLE_ENTITY_IDX_ORIGIN + DEATH_PARTICLE_ENTITY_SIZE
	):
		forces[i].x *= 1.05
		forces[i].y *= 0.9

	Score.hi_score = max(Score.hi_score, score)
	var rank = Score.ranking.size() - Score.ranking.bsearch(score) + 1
	score_label.text = "HI-SCORE:%06d\n[%02d]SCORE:%06d" % [Score.hi_score, rank, score]

	grid.set_data(flags, positions, forces)
	grid.update(delta)


func spawn_hit_particle(pos: Vector2) -> void:
	for i in 10:
		var idx = hit_idx + HIT_PARTICLE_ENTITY_IDX_ORIGIN
		if flags[idx] == 0:
			flags[idx] = 1
			entities[idx].position = pos
			positions[idx] = pos
			entities[idx].emitting = true
			hit_idx = (hit_idx + 1) % HIT_PARTICLE_ENTITY_SIZE
			Sound.shot()
			break
		hit_idx = (hit_idx + 1) % HIT_PARTICLE_ENTITY_SIZE


func spawn_death_particle(pos: Vector2) -> void:
	for i in DEATH_PARTICLE_ENTITY_SIZE:
		var idx = death_idx + DEATH_PARTICLE_ENTITY_IDX_ORIGIN
		if flags[idx] == 0:
			flags[idx] = 1
			entities[idx].position = pos
			positions[idx] = pos
			entities[idx].emitting = true
			forces[idx] = DEATH_PARTICLE_FORCE
			death_idx = (death_idx + 1) % DEATH_PARTICLE_ENTITY_SIZE
			break
		death_idx = (death_idx + 1) % DEATH_PARTICLE_ENTITY_SIZE


func spawn_e9(pos: Vector2, t: int = 0) -> void:
	for i in E9_ENTITY_SIZE:
		var idx = e9_idx + E9_IDX_ORIGIN
		if flags[idx] == 0:
			flags[idx] = 1
			entities[idx].position = pos
			entities[idx].visible = true
			if t != 0:
				entities[idx].dir = Vector2(cos(timer), sin(sin(timer)))
			positions[idx] = pos
			e9_idx = (e9_idx + 1) % E9_ENTITY_SIZE
			break
		e9_idx = (e9_idx + 1) % E9_ENTITY_SIZE


func get_e1_position(t: float) -> Vector2:
	$E1Path/E1Spawner.progress_ratio = randf()
	return $E1Path/E1Spawner.position


func _on_wall_area_entered(area: Area2D) -> void:
	var id = area.id
	var pos = area.position
	spawn_hit_particle(pos)
	flags[id] = 0
	entities[id].position = DEF_VEC2
	entities[id].dir = Vector2.INF


func _on_hit_particle_emit_finished(id: int) -> void:
	flags[id] = 0
	positions[id] = DEF_VEC2


func _on_death_particle_emit_finished(id: int) -> void:
	flags[id] = 0
	positions[id] = DEF_VEC2


func _on_e1_hit_shot(area: Entity) -> void:
	spawn_hit_particle(area.position)
	var id = area.id
	entities[id].position = DEF_VEC2
	flags[id] = 0
	Sound.hit(1.0)


func _on_e1_death(id: int) -> void:
	spawn_death_particle(entities[id].position)
	e1_interval -= 0.02
	e1_death += 1
	flags[id] = 0
	entities[id].visible = false
	entities[id].position = DEF_VEC2
	score += 100
	Sound.bomb(1.0)


func _on_e2_hit_shot(area: Entity) -> void:
	spawn_hit_particle(area.position)
	var id = area.id
	entities[id].position = DEF_VEC2
	flags[id] = 0
	Sound.hit(0.75)


func _on_e2_death(id: int) -> void:
	spawn_death_particle(entities[id].position)
	e2_interval -= 0.10
	flags[id] = 0
	entities[id].visible = false
	entities[id].position = DEF_VEC2
	score += 1000
	Sound.bomb(0.75)


func _on_e2_shot(id: int) -> void:
	spawn_e9(positions[id])


func _on_e3_hit_shot(area: Entity) -> void:
	spawn_hit_particle(area.position)
	var id = area.id
	entities[id].position = DEF_VEC2
	flags[id] = 0
	Sound.hit(0.5)


func _on_e3_death(id: int) -> void:
	spawn_death_particle(entities[id].position)
	flags[id] = 0
	entities[id].visible = false
	entities[id].position = DEF_VEC2
	score += 10000
	Sound.bomb(0.5)


func _on_e3_shot(id: int) -> void:
	spawn_e9(positions[id], 1.0 + entities[id].rotation)


func _on_e9_hit_shot(area: Entity) -> void:
	spawn_hit_particle(area.position)
	var id = area.id
	entities[id].position = DEF_VEC2
	flags[id] = 0
	Sound.hit(1.2)


func _on_e9_death(id: int) -> void:
	flags[id] = 0
	entities[id].visible = false
	entities[id].position = DEF_VEC2
	score += 10


func _on_player_area_entered(_area: Area2D) -> void:
	if !game_over:
		game_over = true
		player.visible = false
		Sound.game_over()
		forces[0] = Vector2(400, 1000)
		GodotplayerScore.submit_score("main", score)
		await get_tree().create_timer(0.05).timeout
		forces[0] = Vector2.ZERO
		for i in range(SHOT_ENTITY_IDX_ORIGIN, SHOT_ENTITY_IDX_ORIGIN + SHOT_ENTITY_SIZE):
			flags[i] = 0
			entities[i].hide()
			entities[i].monitoring = false
			entities[i].monitorable = false
		await get_tree().create_timer(2.0).timeout
		set_physics_process(false)
		set_process(true)
