class_name MatchScene
extends Node3D
## Raiz de composicion del partido: cancha, pelota, camara, equipos, reglas y HUD.
## Esta pensada para crecer (5 jugadores por equipo, IA, sustituciones) sin cambiar el resto.

signal quit_requested

@export var duration_seconds: float = 300.0
## Cantidad de futbolistas de campo por equipo en esta etapa (1 = etapa inicial).
@export var home_field_players: int = 4
@export var away_field_players: int = 4
## Cambia solo al jugador del humano mas cercano a la pelota cuando el actual queda lejos.
@export var auto_switch: bool = true
## Calidad de decision de la IA (0..1).
@export var ai_skill: float = 0.6
## Presentacion antes del primer saque (s): calentamiento de los jugadores y arbitro contando. 0 = sin presentacion.
@export var intro_seconds: float = 4.5
@export var with_referee: bool = true
var referee: Referee = null

var ctx: MatchContext
var pitch: Pitch
var ball: Ball
var camera: MatchCamera
var manager: MatchManager
var hud: Hud
var controlled: Footballer = null
var home: Array[Footballer] = []
var away: Array[Footballer] = []
var keepers: Array[Goalkeeper] = []
## Con false no se crean arqueros (algunas pruebas y la practica los omiten).
@export var with_keepers: bool = true

const BALL_SCENE := preload("res://scenes/ball/ball.tscn")
const FOOTBALLER_SCENE := preload("res://scenes/player/footballer.tscn")

func _ready() -> void:
	ctx = MatchContext.new()
	pitch = Pitch.new()
	pitch.name = "Pitch"
	add_child(pitch)
	pitch.build(Tuning.pitch)
	ball = BALL_SCENE.instantiate()
	ball.name = "Ball"
	add_child(ball)
	ball.position = Vector3(0.0, 0.2, 0.0)
	ctx.ball = ball
	ctx.pitch = pitch
	pitch.set_ball(ball)
	camera = MatchCamera.new()
	camera.name = "MatchCamera"
	add_child(camera)
	ctx.camera = camera
	_spawn_teams()
	if with_referee:
		referee = Referee.new()
		referee.name = "Referee"
		add_child(referee)
		referee.setup(ctx, Vector3(-2.0, 0.0, Tuning.pitch.width * 0.5 - 0.9))
	manager = MatchManager.new()
	manager.name = "MatchManager"
	manager.duration_seconds = duration_seconds
	manager.intro_seconds = intro_seconds
	add_child(manager)
	manager.setup(ctx)
	manager.kickoff_requested.connect(_on_kickoff_requested)
	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.bind(manager)
	hud.charge_provider = _charge_state
	hud.restart_play_requested.connect(func() -> void: manager.restart_play())
	hud.restart_match_requested.connect(func() -> void: manager.restart_match())
	hud.quit_requested.connect(_on_quit_requested)
	hud.practice_requested.connect(_on_practice_requested)
	camera.setup(ball, controlled, Tuning.pitch)
	GraphicsSettings.apply()
	manager.start_match()

## Rol tactico (0 cierre, 1 ala izquierda, 2 ala derecha, 3 pivote) segun el puesto en la formacion de saque.
const ROLES_BY_SLOT := [3, 1, 2, 0]

func _spawn_teams() -> void:
	var next_id: int = 1
	for i in home_field_players:
		var role: int = ROLES_BY_SLOT[mini(i, ROLES_BY_SLOT.size() - 1)]
		var f: Footballer = _make_footballer(0, next_id, HumanInput.new() if i == 0 else AIInput.new(role, ai_skill))
		f.set_meta("ai_role", role)
		_seed_ai(f, next_id)
		home.append(f)
		next_id += 1
	for i in away_field_players:
		var role2: int = ROLES_BY_SLOT[mini(i, ROLES_BY_SLOT.size() - 1)]
		var f2: Footballer = _make_footballer(1, next_id, AIInput.new(role2, ai_skill))
		f2.set_meta("ai_role", role2)
		_seed_ai(f2, next_id)
		away.append(f2)
		next_id += 1
	if home.size() > 0:
		controlled = home[0]
		controlled.is_human_controlled = true
	if with_keepers:
		for team_index in 2:
			var k := Goalkeeper.new()
			k.name = "Goalkeeper_%d" % team_index
			add_child(k)
			var kattrs := PlayerAttributes.new()
			kattrs.reset_to(60)
			k.setup(ctx, team_index, next_id, kattrs)
			next_id += 1
			keepers.append(k)

func _seed_ai(f: Footballer, id: int) -> void:
	if f.input_source is AIInput:
		(f.input_source as AIInput).rng.seed = 9100 + id * 131

func _make_footballer(team: int, id: int, source: InputSource) -> Footballer:
	var f: Footballer = FOOTBALLER_SCENE.instantiate()
	f.name = "Footballer_%d" % id
	add_child(f)
	var attrs := PlayerAttributes.new()
	attrs.reset_to(55)
	f.setup(ctx, team, id, attrs, source)
	return f

## Con el partido como escena actual, «Salir» cierra el juego; si lo aloja otro nodo (pruebas) solo avisa.
func _on_quit_requested() -> void:
	quit_requested.emit()
	if get_tree().current_scene == self:
		get_tree().quit()

## Abre la sala de practica (galeria de animaciones y malabares) y vuelve aqui con «Volver».
func _on_practice_requested() -> void:
	if get_tree().current_scene == self:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/practice/practice.tscn")

## Formacion de saque. Hoy: un jugador por equipo; preparado para 4 + arquero por equipo.
func kickoff_positions(team: int) -> Array[Vector3]:
	var sign_x: float = -1.0 if team == 0 else 1.0
	var out: Array[Vector3] = []
	out.append(Vector3(sign_x * 1.4, 0.0, 0.0))
	out.append(Vector3(sign_x * 6.0, 0.0, -4.5))
	out.append(Vector3(sign_x * 6.0, 0.0, 4.5))
	out.append(Vector3(sign_x * 11.0, 0.0, 0.0))
	return out

func _on_kickoff_requested(_kicking_team: int) -> void:
	ball.reset_at(Vector3(0.0, 0.11, 0.0))
	for team_list in [home, away]:
		var team_index: int = 0 if team_list == home else 1
		var positions: Array[Vector3] = kickoff_positions(team_index)
		var yaw: float = Locomotion.yaw_from_dir(Vector3(1.0 if team_index == 0 else -1.0, 0.0, 0.0))
		for i in team_list.size():
			(team_list[i] as Footballer).place_at(positions[mini(i, positions.size() - 1)], yaw)
	if camera != null:
		camera.snap_to_target()

func _charge_state() -> Dictionary:
	if controlled == null:
		return {}
	return {"pass": controlled.ball_handler.pass_charge, "shoot": controlled.ball_handler.shot_charge}

var _switch_cooldown: float = 0.0

func _physics_process(delta: float) -> void:
	if hud != null and controlled != null:
		hud.touch.show_switch = home.size() > 1
	_switch_cooldown = maxf(_switch_cooldown - delta, 0.0)
	if controlled == null or home.size() < 2 or not ctx.input_enabled:
		return
	if controlled.last_frame.switch_pressed:
		switch_to_nearest_to_ball()
	elif auto_switch and _switch_cooldown <= 0.0:
		_auto_switch()

## Pasa el control humano al companero mas cercano a la pelota (distinto del actual).
func switch_to_nearest_to_ball() -> void:
	var best: Footballer = null
	var best_d: float = INF
	for f in home:
		if f == controlled:
			continue
		var d: float = Vector2(f.global_position.x - ball.global_position.x, f.global_position.z - ball.global_position.z).length()
		if d < best_d:
			best_d = d
			best = f
	if best != null:
		_give_control(best)

func _auto_switch() -> void:
	var cd: float = Vector2(controlled.global_position.x - ball.global_position.x, controlled.global_position.z - ball.global_position.z).length()
	if cd < 7.0 or controlled.ball_handler.is_kick_in_progress() or controlled.has_ball():
		return
	var best: Footballer = null
	var best_d: float = cd - 3.0
	for f in home:
		if f == controlled:
			continue
		var d: float = Vector2(f.global_position.x - ball.global_position.x, f.global_position.z - ball.global_position.z).length()
		if d < best_d:
			best_d = d
			best = f
	if best != null:
		_give_control(best)

func _give_control(target: Footballer) -> void:
	if target == controlled:
		return
	var human: InputSource = controlled.input_source
	controlled.input_source = AIInput.new(int(controlled.get_meta("ai_role", 0)), ai_skill)
	controlled.is_human_controlled = false
	target.input_source = human
	target.is_human_controlled = true
	controlled = target
	_switch_cooldown = 1.0
	if camera != null:
		camera.set_focus_actor(controlled)
