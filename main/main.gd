extends Node2D

const DEF_VEC2 := Vector2(9999, 9999)

const PLAYER_SIZE := 1
const SHOT_ENTITY_SIZE := 30
const E1_ENTITY_SIZE := 20
const E2_ENTITY_SIZE := 10
const E3_ENTITY_SIZE := 5
const E9_ENTITY_SIZE := 60
const HIT_PARTICLE_SIZE := 30
const DEATH_PARTICLE_SIZE := 10

const PLAYER_FORCE := Vector2(40, 10000)
const SHOT_FORCE := Vector2(20, 10000)
const E1_FORCE := Vector2.ZERO
const E2_FORCE := Vector2.ZERO
const E3_FORCE := Vector2(200, 56000)
const E9_FORCE := Vector2.ZERO
const HIT_PARTICLE_FORCE := Vector2(100, 3000)
const DEATH_PARTICLE_FORCE := Vector2(150, 28600)

const SCORE_TEXT := "HI-SCORE:%06d\n[%02d]SCORE:%06d\n"

@export var shot_inst: PackedScene
@export var hit_particle_inst: PackedScene
@export var death_particle_inst: PackedScene
@export var e1_inst: PackedScene
@export var e2_inst: PackedScene
@export var e3_inst: PackedScene
@export var e9_inst: PackedScene

@onready var player: Player = $Player
@onready var grid: Node2D = $Grid
@onready var score_label: Label = $UILayer/ScoreLabel
@onready var enemy_spawner: PathFollow2D = $E1Path/E1Spawner
@onready var cursor: Node2D = $UILayer/Cursor

var SHOT_IDX_ORIGIN := 1
var E1_IDX_ORIGIN := 101
var E2_IDX_ORIGIN := 131
var E3_IDX_ORIGIN := 141
var E9_IDX_ORIGIN := 146
var HIT_PARTICLE_ORIGIN := 346
var DEATH_PARTICLE_ORIGIN := 446

var entities: Array[Entity] = []
var particles: Array[GPUParticles2D] = []
var flags: PackedByteArray = []
var positions: PackedVector2Array = []
var forces: PackedVector2Array = []

var shot_idx := 0
var e1_idx := 0
var e2_idx := 0
var e3_idx := 0
var e9_idx := 0
var hit_idx := 0
var death_idx := 0

var timer := 0.0
var shot_timer := 0.0
var e1_timer := 1.5
var e2_timer := 0.0
var e3_timer := 0.0

var shot_interval := 0.08
var e1_interval := 3.0
var e2_interval := 24.0
var e3_interval := 64.0

var e1_death := 0

var score := 0
var game_over := false

func _ready() -> void:
	Score.get_ranking()
	print(Score.ranking)
	Sound.is_title = false
	set_process(false)
	set_physics_process(false)

	# Add Player
	entities.append(player)
	flags.append(1)
	positions.append(player.position)
	forces.append(PLAYER_FORCE)

	# Add PlayerShot
	SHOT_IDX_ORIGIN = entities.size()
	for i in SHOT_ENTITY_SIZE:
		var _s: Entity = shot_inst.instantiate()
		_s.position = DEF_VEC2
		_s.id = SHOT_IDX_ORIGIN + i
		add_child(_s)
		entities.append(_s)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(SHOT_FORCE if i % 3 == 0 else Vector2.ZERO)

	# Add EnemyB (Trigon)
	E1_IDX_ORIGIN = entities.size()
	__add_enemy(
		E1_IDX_ORIGIN,
		E1_ENTITY_SIZE,
		e1_inst,
		E1_FORCE,
		func(_e: Entity):
		_e.hit.connect(_on_e1_hit)
		_e.dead.connect(_on_e1_death)
	)

	# Add EnemyC (Square)
	E2_IDX_ORIGIN = entities.size()
	__add_enemy(
		E2_IDX_ORIGIN,
		E2_ENTITY_SIZE,
		e2_inst,
		E2_FORCE,
		func(_e: Entity):
		_e.hit.connect(_on_e2_hit)
		_e.dead.connect(_on_e2_death)
		_e.shoot.connect(_on_e2_shot)
		)

	# Add EnemyD (Gobot)
	E3_IDX_ORIGIN = entities.size()
	__add_enemy(
		E3_IDX_ORIGIN,
		E3_ENTITY_SIZE,
		e3_inst,
		E3_FORCE,
		func(_e: Entity):
		_e.hit.connect(_on_e3_hit)
		_e.dead.connect(_on_e3_death)
		_e.shoot.connect(_on_e3_shot)
		)

	# Add EnemyA (RedBullet)
	E9_IDX_ORIGIN = entities.size()
	__add_enemy(
		E9_IDX_ORIGIN,
		E9_ENTITY_SIZE,
		e9_inst,
		E9_FORCE,
		func(_e: Entity):
		_e.hit.connect(_on_e9_hit)
		_e.dead.connect(_on_e9_death)
		)

	# Add Particle (Small)
	HIT_PARTICLE_ORIGIN = entities.size()
	__add_particle(
		HIT_PARTICLE_ORIGIN,
		HIT_PARTICLE_SIZE,
		hit_particle_inst,
		HIT_PARTICLE_FORCE,
		_on_hit_particle_emit_finished

		)

	# Add Particle (Big)
	DEATH_PARTICLE_ORIGIN = entities.size() + HIT_PARTICLE_SIZE
	__add_particle(
		DEATH_PARTICLE_ORIGIN,
		DEATH_PARTICLE_SIZE,
		death_particle_inst,
		DEATH_PARTICLE_FORCE,
		_on_death_particle_emit_finished
		)

	for i in HIT_PARTICLE_SIZE:
		spawn_hit_particle(Vector2(200, 300))
	for i in DEATH_PARTICLE_SIZE:
		spawn_death_particle(Vector2(200, 300))

	await get_tree().create_timer(0.8).timeout
	$UILayer/ColorRect.hide()
	set_physics_process(true)


func _process(delta: float) -> void:
	timer += delta
	var text1 = SCORE_TEXT % [Score.hi_score, Score.get_rank(score), score]
	var text2 = ["GAME OVER\n[R]etry [Q]uit", "\n[R]etry [Q]uit"][int(timer) % 2]
	score_label.text = text1 + text2

	if Input.is_action_just_pressed("retry"):
		get_tree().reload_current_scene()
	if Input.is_action_pressed("quit"):
		get_tree().change_scene_to_file("res://title.tscn")


func _physics_process(delta: float) -> void:
	var start = Time.get_ticks_usec()
	# Update MainTime
	timer += delta

	# Move Player
	if !game_over:
		positions[0] = player.move(delta)
		forces[0] = PLAYER_FORCE if player.is_move else Vector2.ZERO

	# Spawn PlayerShot (指定時間による活性化)
	# (対象がアクティブの時にはこのフレームをスルー)
	shot_timer += delta
	if shot_timer >= shot_interval:
		var _idx = shot_idx + SHOT_IDX_ORIGIN
		if flags[_idx] == 0:
			entities[_idx].spawn(player.position, player.rotation)
			shot_timer = 0.0
			flags[_idx] = 1
		shot_idx = (shot_idx + 1) % SHOT_ENTITY_SIZE

	# Spawn Enemy-B(Trigon) (指定時間による活性化)
	# (対象がアクティブの時にはこのフレームをスルー)
	e1_timer += delta
	if e1_timer >= e1_interval:
		var _idx = e1_idx + E1_IDX_ORIGIN
		if flags[_idx] == 0:
			var pos = get_spawn_position(randf())
			entities[_idx].spawn(pos)
			entities[_idx].accell = randf_range(0.8, min(1.0 + e1_death * 0.03, 2.0))
			e1_timer = 0.0
			flags[_idx] = 1
		e1_idx = (e1_idx + 1) % E1_ENTITY_SIZE

	# Spawn Enemy-C(Square) (指定時間による活性化)
	# (対象がアクティブの時にはこのフレームをスルー)
	e2_timer += delta
	if e2_timer >= e2_interval:
		var _idx = e2_idx + E2_IDX_ORIGIN
		if flags[_idx] == 0:
			var pos = get_spawn_position(randf())
			entities[_idx].spawn(pos)
			e2_timer = 0.0
			flags[_idx] = 1
		e2_idx = (e2_idx + 1) % E2_ENTITY_SIZE

	# Spawn Enemy-D(Gobot) (指定時間による活性化)
	# (対象がアクティブの時にはこのフレームをスルー)
	e3_timer += delta
	if e3_timer >= e3_interval:
		var _idx = e3_idx + E3_IDX_ORIGIN
		if flags[_idx] == 0:
			var pos = get_spawn_position(randf())
			entities[_idx].spawn(pos)
			e3_timer = 0.0
			flags[_idx] = 1
		e3_idx = (e3_idx + 1) % E3_ENTITY_SIZE

	# Move PlayerShots
	for i in range(SHOT_IDX_ORIGIN, SHOT_IDX_ORIGIN + SHOT_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta)
			positions[i] = pos

	# Move Enemy-A(Trigon)
	for i in range(E1_IDX_ORIGIN, E1_IDX_ORIGIN + E1_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta, {"pp": player.position})
			positions[i] = pos

	# Move Enemy-B(Square)
	for i in range(E2_IDX_ORIGIN, E2_IDX_ORIGIN + E2_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta)
			positions[i] = pos

	# Move Enemy-C(Gobot)
	for i in range(E3_IDX_ORIGIN, E3_IDX_ORIGIN + E3_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta)
			positions[i] = pos

	# Move Enemy-D(Bullet)
	for i in range(E9_IDX_ORIGIN, E9_IDX_ORIGIN + E9_ENTITY_SIZE):
		if flags[i] == 1:
			var pos = entities[i].move(delta, {"pp": player.position})
			positions[i] = pos

	# ChangeScale DeathParticle
	for i in range(
		DEATH_PARTICLE_ORIGIN,
		DEATH_PARTICLE_ORIGIN + DEATH_PARTICLE_SIZE
	):
		forces[i].x *= 1.05
		forces[i].y *= 0.9

	# Update ScoreUI
	Score.hi_score = max(Score.hi_score, score)
	score_label.text = SCORE_TEXT % [Score.hi_score, Score.get_rank(score), score]

	# Update Grid
	grid.set_data(flags, positions, forces)
	grid.update(delta)

	# 十字カーソルのON/OFF
	cursor.queue_redraw()
	if Input.is_action_just_pressed("click_left"):
		cursor.visible = !cursor.visible

	var end = Time.get_ticks_usec()
	Debugger.ticks_usec("Main._physics_update()", start, end)
	Debugger.set_flags(
		flags, [0,SHOT_IDX_ORIGIN, E1_IDX_ORIGIN, E2_IDX_ORIGIN, E3_IDX_ORIGIN, E9_IDX_ORIGIN, HIT_PARTICLE_ORIGIN, DEATH_PARTICLE_ORIGIN, flags.size()], ["player", "shot", "e1", "e2", "e3", "e9", "hit", "death"])
	Debugger.update()



## 敵エンティティのスポーンとコレクションへの追加
func __add_enemy(
	origin: int, size: int, scene: PackedScene, force: Vector2, connector: Callable
) -> void:
	for i in size:
		var _e: Entity = scene.instantiate()
		_e.initialize(origin + i)
		connector.call(_e)
		add_child(_e)
		entities.append(_e)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(force)


## パーティクルのスポーンとコレクションへの追加
func __add_particle(origin: int, size: int, scene: PackedScene, force: Vector2, action: Callable) -> void:
	for i in size:
		var _e: GPUParticles2D = scene.instantiate()
		_e.position = DEF_VEC2
		_e.finished.connect(action.bind(origin + i))
		add_child(_e)
		particles.append(_e)
		flags.append(0)
		positions.append(DEF_VEC2)
		forces.append(force)
		

## Enemy-A(Bullet)をアクティブにする
## (任意のタイミング)
func __spawn_e9(pos: Vector2, t: float = 0.0) -> void:
	for i in E9_ENTITY_SIZE:
		var idx = e9_idx + E9_IDX_ORIGIN
		if flags[idx] == 0:
			flags[idx] = 1
			entities[idx].spawn(pos)
			positions[idx] = pos
			if t != 0.0:
				entities[idx].dir = Vector2(cos(timer), sin(sin(timer)))
			e9_idx = (e9_idx + 1) % E9_ENTITY_SIZE
			return
		e9_idx = (e9_idx + 1) % E9_ENTITY_SIZE


## HitParticleをアクティブにする
## (任意のタイミング)
func spawn_hit_particle(pos: Vector2) -> void:
	for i in HIT_PARTICLE_SIZE:
		var idx = hit_idx + HIT_PARTICLE_ORIGIN
		if flags[idx] == 0:
			flags[idx] = 1
			particles[hit_idx].position = pos
			particles[hit_idx].emitting = true
			positions[idx] = pos
			hit_idx = (hit_idx + 1) % HIT_PARTICLE_SIZE
			# Sound.shot()
			return
		hit_idx = (hit_idx + 1) % HIT_PARTICLE_SIZE


## DeathParticleをアクティブにする
## (任意のタイミング)
func spawn_death_particle(pos: Vector2) -> void:
	for i in DEATH_PARTICLE_SIZE:
		var idx = death_idx + DEATH_PARTICLE_ORIGIN
		if flags[idx] == 0:
			flags[idx] = 1
			particles[death_idx + HIT_PARTICLE_SIZE].position = pos
			particles[death_idx + HIT_PARTICLE_SIZE].emitting = true
			positions[idx] = pos
			forces[idx] = DEATH_PARTICLE_FORCE
			death_idx = (death_idx + 1) % DEATH_PARTICLE_SIZE
			return
		death_idx = (death_idx + 1) % DEATH_PARTICLE_SIZE


## 敵のスポーン位置の取得
func get_spawn_position(_t: float) -> Vector2:
	enemy_spawner.progress_ratio = _t
	return $E1Path/E1Spawner.position


## 壁との衝突(PlayerShot, EnemyShot(Bullet))
func _on_wall_area_entered(entity: Entity) -> void:
	var id = entity.id
	var pos = entity.position
	entity.death()
	spawn_hit_particle(pos)
	flags[id] = 0
	entities[id].position = DEF_VEC2
	entities[id].dir = Vector2.INF
	if entity is Bullet:
		Sound.shot()


## Particle終了時アクションのヘルパー
func __particle_finish(id: int) -> void:
	flags[id] = 0
	positions[id] = DEF_VEC2


## HitParticleエミット終了時のアクション
func _on_hit_particle_emit_finished(id: int) -> void:
	__particle_finish(id)


# DeathParticleエミット終了時のアクション
func _on_death_particle_emit_finished(id: int) -> void:
	__particle_finish(id)


## Enemy-B(Trigon) とPlayerShotの衝突時アクション
func _on_e1_hit(shot: Entity) -> void:
	__hit(shot, 1.0)


## Enemy-C(Square) とPlayerShotの衝突時アクション
func _on_e2_hit(shot: Entity) -> void:
	__hit(shot, 0.75)


## Enemy-D(Gobot) とPlayerShotの衝突時アクション
func _on_e3_hit(shot: Entity) -> void:
	__hit(shot, 0.5)


## Enemy-A(Bullet) とPlayerShotの衝突時アクション
func _on_e9_hit(shot: Entity) -> void:
	__hit(shot, 1.2)


## Enemy<->PlayerShotの衝突処理ヘルパー
func __hit(shot: Entity, pitch: float) -> void:
	spawn_hit_particle(shot.position)
	shot.death()
	flags[shot.id] = 0
	positions[shot.id] = DEF_VEC2
	Sound.hit(pitch)


## Enemy-B(Trigon)が倒された際のアクション
func _on_e1_death(id: int) -> void:
	spawn_death_particle(entities[id].position)
	e1_interval -= 0.02
	e1_death += 1
	__death(id, 100)
	Sound.bomb(1.0)


## Enemy-C(Square)が倒された際のアクション
func _on_e2_death(id: int) -> void:
	spawn_death_particle(entities[id].position)
	e2_interval -= 0.10
	Sound.bomb(0.75)
	__death(id, 1000)


## Enemy-D(Gobot)が倒された際のアクション
func _on_e3_death(id: int) -> void:
	spawn_death_particle(entities[id].position)
	Sound.bomb(0.5)
	__death(id, 10000)


## death処理ヘルパー
func __death(id: int, _score: int) -> void:
	flags[id] = 0
	positions[id] = DEF_VEC2
	score += _score


## Enemy-A(Bullet)が倒された際のアクション
func _on_e9_death(id: int) -> void:
	__death(id, 10)


## Enemy-B(Square)の弾発射アクション
func _on_e2_shot(id: int) -> void:
	__spawn_e9(positions[id])


## Enemy-C(Gobot)の弾発射アクション
func _on_e3_shot(id: int) -> void:
	__spawn_e9(positions[id], 1.0 + entities[id].rotation)


## プレイヤー破壊時のアクション
func _on_player_dead(_id: int) -> void:
	if !game_over:
		game_over = true
		player.hide()
		entities[_id].hide()
		Sound.game_over()

		for i in range(SHOT_IDX_ORIGIN, SHOT_IDX_ORIGIN + SHOT_ENTITY_SIZE):
			flags[i] = 0
			entities[i].hide()
			entities[i].set_deferred("monitoring", false)
			entities[i].set_deferred("monitorable", false)

		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_method(
			func(v): forces[0] = v,
			Vector2(170, -300000),
			Vector2(1300, 100), 1.0)

		GodotplayerScore.submit_score("main", score)

		await get_tree().create_timer(3.0).timeout
		set_physics_process(false)
		set_process(true)
