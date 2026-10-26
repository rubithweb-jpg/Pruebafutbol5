class_name AIInput
extends InputSource
## Cerebro de un futbolista controlado por la maquina. Produce el mismo InputFrame que una persona (direccion en el
## mundo, sprint, botones con su temporizacion de carga), asi que usa exactamente la fisica y los limites del jugador.
##
## Formacion 1-2-1 (rombo) de fútbol 5: rol 0 = cierre, 1 = ala izquierda, 2 = ala derecha, 3 = pivote.
## Decide cada DECISION_PERIOD s (no cada fotograma); los botones se ejecutan fotograma a fotograma.

const DECISION_PERIOD := 0.12
## Fraccion del largo de la cancha (0 = su arco, 1 = el arco rival) donde se para cada rol.
const ROLE_DEPTH := [0.2, 0.5, 0.5, 0.78]
const ROLE_LATERAL := [0.0, -5.0, 5.0, 0.0]
const ROLE_SHIFT := [0.3, 0.55, 0.55, 0.5]
## Angulo minimo (grados) que debe formar el arco visto desde la pelota para intentar un disparo.
const MIN_SHOT_APERTURE_DEG := 16.0
## Un rival a menos de este radio (m) de la pelota en KICK_SAFE_TIME s impide empezar una patada.
const KICK_SAFE_RADIUS := 0.95
const KICK_SAFE_TIME := 0.25
## Segundos casi parado con la pelota (barullo) a partir de los cuales se patea aunque haya un rival encima.
const DESPERATE_SECONDS := 0.9

var role: int = 0
## 0..1: calidad de decision (rango de tiro, rapidez en soltar el pase).
var skill: float = 0.6
var rng := RandomNumberGenerator.new()

var _tick: int = 0
var _next_decision: float = 0.0
var _clock: float = 0.0
var _dir: Vector3 = Vector3.ZERO
var _mag: float = 0.0
var _sprint: bool = false
var _press: bool = false
# Boton en curso: tipo ("pass"/"shot"), segundos que se mantiene y direccion de apuntado.
var _btn: StringName = &""
var _btn_hold: float = 0.0
var _btn_age: float = 0.0
var _btn_dir: Vector3 = Vector3.ZERO
var _btn_lob: bool = false
var _btn_cooldown: float = 0.0
var _dribble_started: float = 0.0
var _skill_next: bool = false
## Segundos seguidos que el portador lleva casi parado (barullo): si se prolonga rompe el bloqueo pateando.
var _slow_hold: float = 0.0

func _init(r: int = 0, s: float = 0.6) -> void:
	role = r
	skill = s
	rng.randomize()

func poll(f: Footballer) -> InputFrame:
	var out := InputFrame.new()
	_tick += 1
	out.tick = _tick
	out.use_world = true
	var ctx: MatchContext = f.ctx
	if ctx == null or ctx.ball == null or not ctx.input_enabled:
		return out
	var dt: float = 1.0 / float(Engine.physics_ticks_per_second)
	_clock += dt
	_btn_cooldown = maxf(_btn_cooldown - dt, 0.0)
	if _btn != &"":
		return _run_button(out, f, dt)
	if _clock >= _next_decision:
		_next_decision = _clock + DECISION_PERIOD * rng.randf_range(0.8, 1.2)
		_decide(f)
		if _btn != &"":
			return _run_button(out, f, dt)
	out.move_world = _dir * _mag
	out.sprint = _sprint
	out.press_held = _press
	out.skill_pressed = _skill_next
	_skill_next = false
	return out

# --- Botones -------------------------------------------------------------------------------------------

## Orienta el cuerpo hacia donde va a patear antes de pulsar: devuelve true si ya esta alineado (<= 28 grados).
func _aligned(f: Footballer, dir: Vector3) -> bool:
	var ang: float = absf(wrapf(Locomotion.yaw_from_dir(dir.normalized()) - f.locomotion.yaw, -PI, PI))
	if ang <= deg_to_rad(28.0):
		return true
	_dir = dir.normalized()
	_mag = 0.45
	_sprint = false
	return false

func _start_button(kind: StringName, hold: float, dir: Vector3, lob: bool = false) -> void:
	_btn = kind
	_btn_hold = hold
	_btn_age = 0.0
	_btn_dir = dir
	_btn_lob = lob

## true si ningun rival llegara a la pelota durante el balanceo de la patada (~0.25 s): con la pelota suelta entre dos
## jugadores el golpe se pierde. Con rival encima se conduce, se regatea o se protege la pelota en vez de patear.
func _kick_safe(f: Footballer) -> bool:
	var ball: Ball = f.ctx.ball
	var bp := Vector3(ball.global_position.x, 0.0, ball.global_position.z)
	for o in f.ctx.footballers:
		if o.team == f.team:
			continue
		var op := Vector3(o.global_position.x, 0.0, o.global_position.z) + Vector3(o.velocity.x, 0.0, o.velocity.z) * KICK_SAFE_TIME
		if op.distance_to(bp) < KICK_SAFE_RADIUS:
			return false
	return true

## true si, tal como esta la pelota ahora, el golpeo llegaria (con clip: algun pie alcanza; sin clip: alcance de toque).
func _can_kick(f: Footballer, kind: StringName, lob: bool) -> bool:
	var bh: BallHandler = f.ball_handler
	if bh.uses_clip_kicks():
		return not bh.plan_clip_kick(kind, 0.5, lob).is_empty()
	return bh.can_reach(Tuning.player.touch_reach + 0.3)

func _run_button(out: InputFrame, f: Footballer, dt: float) -> InputFrame:
	var first: bool = _btn_age == 0.0
	_btn_age += dt
	var releasing: bool = _btn_age >= _btn_hold
	# Mientras carga frena (la pelota no se aleja); suelta solo cuando el pie llega, con un maximo de espera.
	if releasing and _btn_age < _btn_hold + 0.45 and not _can_kick(f, _btn, _btn_lob):
		releasing = false
	# Un tiro se cancela si, durante la carga, la pelota quedo en un angulo sin arco (se corrio hacia la linea de fondo).
	var closed_angle: bool = false
	if _btn == &"shot" and not f.ball_handler.is_kick_in_progress():
		var gx: float = float(f.ctx.attacking_goal(f.team).position.x)
		var bp: Vector3 = _flat(f.ctx.ball.global_position)
		closed_angle = _goal_aperture_deg(bp, Vector3(gx, 0.0, 0.0), f.ctx.pitch.config.half_goal()) < MIN_SHOT_APERTURE_DEG * 0.6
	# Si la pelota se fue (robo, rebote) o no llega a tiempo, se cancela la carga: no se patea al aire.
	if closed_angle or f.ball_handler.ball_distance() > 1.7 or (releasing == false and _btn_age >= _btn_hold + 0.45) or f.ball_handler.is_kick_in_progress():
		if not f.ball_handler.is_kick_in_progress():
			f.ball_handler.cancel_charge()
			_btn = &""
			_btn_cooldown = 0.5
			_next_decision = _clock
			return out
	# Al cargar casi se detiene (la pelota no se escapa hacia adelante ni hacia la linea de fondo antes del golpeo).
	out.move_world = _btn_dir * (0.18 if not releasing else 0.5)
	out.lob_held = _btn_lob
	var pressed: bool = first
	var held: bool = not releasing
	if _btn == &"pass":
		out.pass_pressed = pressed
		out.pass_held = held
		out.pass_released = releasing
	else:
		out.shoot_pressed = pressed
		out.shoot_held = held
		out.shoot_released = releasing
	if releasing:
		_btn = &""
		_btn_cooldown = 0.9
		_next_decision = _clock + 0.25
	return out

# --- Decision --------------------------------------------------------------------------------------------

func _attack_dir(f: Footballer) -> Vector3:
	return Vector3(1.0 if f.team == 0 else -1.0, 0.0, 0.0)

func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

func _decide(f: Footballer) -> void:
	var ctx: MatchContext = f.ctx
	var ball: Ball = ctx.ball
	var atk: Vector3 = _attack_dir(f)
	var pos: Vector3 = _flat(f.global_position)
	var bpos: Vector3 = _flat(ball.global_position)
	_press = false
	_sprint = false
	if ball.is_held():
		_move_to(f, _anchor(f, false), 0.7)
		return
	var carrier: Footballer = _carrier(ctx)
	# Solo UN companero lleva la pelota (el mas cercano): con dos 'portadores' se pisaban y se robaban el golpe.
	var mine: bool = carrier == f
	var team_has: bool = carrier != null and carrier.team == f.team
	if mine:
		_decide_with_ball(f, ctx, atk)
		return
	var chaser: Footballer = _chaser(f, ctx)
	if chaser == f and not team_has:
		# A por la pelota: la presion calcula el punto de intercepcion y el robo.
		var to_ball: Vector3 = bpos - pos
		_dir = to_ball.normalized() if to_ball.length() > 0.2 else Vector3.ZERO
		_mag = 1.0
		_sprint = to_ball.length() > 4.5
		_press = to_ball.length() < 14.0
		return
	if team_has:
		# Apoyo: desmarcarse hacia el espacio delante del companero con pelota.
		var spot: Vector3 = _support_spot(f, carrier, atk)
		_move_to(f, spot, 0.85)
		_sprint = (spot - pos).length() > 6.0
		return
	_move_to(f, _anchor(f, false), 0.8)
	_sprint = (_anchor(f, false) - pos).length() > 7.0

func _decide_with_ball(f: Footballer, ctx: MatchContext, atk: Vector3) -> void:
	var pos: Vector3 = _flat(f.global_position)
	var goal := Vector3(float(ctx.attacking_goal(f.team).position.x), 0.0, 0.0)
	var to_goal: Vector3 = goal - pos
	var dist_goal: float = to_goal.length()
	var opp_near: float = _nearest_opponent_dist(f, ctx, pos, atk)
	var keeper: Node = ctx.keeper_defending(1 - f.team)
	var kz: float = (keeper as Node3D).global_position.z if keeper != null else 0.0
	_slow_hold = _slow_hold + DECISION_PERIOD if f.locomotion.speed < 0.8 else 0.0
	var desperate: bool = _slow_hold > DESPERATE_SECONDS
	var shoot_range: float = lerpf(8.0, 13.0, skill)
	var lane_clear: bool = _lane_clear(f, ctx, pos, goal, 0.9)
	# Solo se dispara con un angulo util al arco: desde la linea de fondo o un costado cerrado la pelota no entra.
	var aperture: float = _goal_aperture_deg(pos, goal, ctx.pitch.config.half_goal())
	var good_angle: bool = aperture >= MIN_SHOT_APERTURE_DEG
	if _btn_cooldown <= 0.0 and good_angle and (desperate or _kick_safe(f)) and dist_goal < shoot_range and (lane_clear or opp_near < 1.8 or dist_goal < 5.5) and _can_kick(f, &"shot", false):
		var side: float = -signf(kz) if absf(kz) > 0.15 else (1.0 if rng.randf() < 0.5 else -1.0)
		var aim := Vector3(goal.x, 0.0, side * rng.randf_range(0.7, 1.2))
		var d: Vector3 = (aim - pos).normalized()
		var charge: float = clampf(0.45 + dist_goal / shoot_range * 0.4, 0.4, 0.9)
		if not _aligned(f, d):
			return
		_start_button(&"shot", charge * Tuning.ball.shot_charge_time * 0.6, d, dist_goal > 9.0 and rng.randf() < 0.15)
		return
	# Pase si hay presion o un companero mejor ubicado.
	if _btn_cooldown <= 0.0 and (desperate or _kick_safe(f)) and _can_kick(f, &"pass", false) and (desperate or opp_near < 2.4 or (rng.randf() < 0.10 * (0.5 + skill) and dist_goal > 7.0)):
		var tgt: Footballer = _best_pass_target(f, ctx, pos, atk)
		# Sin presion, solo se pasa si el companero esta claramente mas adelantado.
		if tgt != null and opp_near >= 2.4 and (_flat(tgt.global_position) - pos).dot(atk) < 2.0:
			tgt = null
		if tgt == null and desperate:
			# Sin companero libre: despeje largo hacia el campo rival.
			var clear_dir: Vector3 = (atk + Vector3(0.0, 0.0, -signf(pos.z) * 0.35)).normalized()
			if _aligned(f, clear_dir):
				_start_button(&"pass", 0.55, clear_dir, false)
			return
		if tgt != null:
			var tp: Vector3 = _flat(tgt.global_position)
			var d2: Vector3 = (tp - pos)
			var dist: float = d2.length()
			if not _aligned(f, d2):
				return
			_start_button(&"pass", clampf(0.12 + dist * 0.022, 0.15, 0.62), d2.normalized(), dist > 15.0 and rng.randf() < 0.3)
			return
	# Regate: con un rival encima y algo de velocidad, a veces hace la ruleta.
	if opp_near < 1.9 and f.locomotion.speed > 2.0 and rng.randf() < 0.12 * (0.5 + skill):
		_skill_next = true
	# Conduccion hacia el arco esquivando rivales. Sin angulo de tiro se busca el punto frontal del area, no el fondo.
	# Se conduce hasta el borde del area chica, no hasta dentro de la red: desde ahi se dispara.
	var run_to: Vector3 = Vector3(goal.x - atk.x * 1.5, 0.0, goal.z)
	if not good_angle and dist_goal < shoot_range + 4.0:
		run_to = Vector3(goal.x - atk.x * 4.5, 0.0, clampf(pos.z * 0.3, -1.2, 1.2))
	var dir: Vector3 = (run_to - pos).normalized()
	dir = _avoid_opponents(f, ctx, pos, dir, atk)
	dir = _avoid_walls(pos, dir, ctx)
	_dir = dir
	_mag = 1.0
	_sprint = opp_near > 4.0 and dist_goal > 6.0

# --- Utilidades tacticas -------------------------------------------------------------------------------------

## Angulo (grados) bajo el que se ven los dos postes desde `pos`; 0 si la pelota esta en la linea de fondo o detras.
func _goal_aperture_deg(pos: Vector3, goal: Vector3, half_goal: float) -> float:
	var a: Vector3 = Vector3(goal.x, 0.0, half_goal) - pos
	var b: Vector3 = Vector3(goal.x, 0.0, -half_goal) - pos
	var ahead: Vector3 = Vector3(signf(goal.x), 0.0, 0.0)
	if a.dot(ahead) < 0.6:
		return 0.0
	return rad_to_deg(absf(a.angle_to(b)))

func _carrier(ctx: MatchContext) -> Footballer:
	var ball: Ball = ctx.ball
	var best: Footballer = null
	var best_d: float = INF
	for p in ctx.footballers:
		var d: float = Vector2(p.global_position.x - ball.global_position.x, p.global_position.z - ball.global_position.z).length()
		if d < best_d and d <= Tuning.player.possession_radius and ball.global_position.y < 0.6:
			best_d = d
			best = p
	return best

## Companero (no arquero) que llega primero a la pelota.
func _chaser(f: Footballer, ctx: MatchContext) -> Footballer:
	var ball: Ball = ctx.ball
	var target: Vector3 = _flat(ball.global_position + ball.linear_velocity * 0.3)
	var best: Footballer = null
	var best_t: float = INF
	for p in ctx.footballers:
		if p.team != f.team:
			continue
		var t: float = Vector2(p.global_position.x - target.x, p.global_position.z - target.z).length() / maxf(p.locomotion.max_run_speed(), 1.0)
		# El cierre solo sale si la pelota esta en su mitad o muy cerca.
		var role_bias: float = 0.0
		if p.input_source is AIInput:
			role_bias = float((p.input_source as AIInput).role == 3) * 0.4
		t += role_bias
		if t < best_t:
			best_t = t
			best = p
	return best

func _anchor(f: Footballer, attacking: bool) -> Vector3:
	var ctx: MatchContext = f.ctx
	var cfg: PitchConfig = ctx.pitch.config
	var half: float = cfg.half_length()
	var atk: Vector3 = _attack_dir(f)
	var own_goal_x: float = -atk.x * half
	var ball: Vector3 = _flat(ctx.ball.global_position)
	var ball_u: float = clampf((ball.x - own_goal_x) * atk.x / cfg.length, 0.0, 1.0)
	var depth: float = float(ROLE_DEPTH[role]) + (ball_u - 0.5) * float(ROLE_SHIFT[role]) + (0.08 if attacking else 0.0)
	depth = clampf(depth, 0.1, 0.9)
	var x: float = own_goal_x + atk.x * depth * cfg.length
	var z: float = float(ROLE_LATERAL[role]) + clampf(ball.z * 0.3, -3.0, 3.0)
	z = clampf(z, -cfg.width * 0.5 + 1.5, cfg.width * 0.5 - 1.5)
	return Vector3(x, 0.0, z)

func _support_spot(f: Footballer, carrier: Footballer, atk: Vector3) -> Vector3:
	var a: Vector3 = _anchor(f, true)
	var cp: Vector3 = _flat(carrier.global_position)
	# Se ofrece por delante del portador, manteniendo su carril.
	var half: float = f.ctx.pitch.config.half_length() - 2.5
	var x: float = a.x
	if role >= 1:
		x = clampf(maxf(a.x * atk.x, cp.x * atk.x + 4.0) * atk.x, -half, half)
	var spot := Vector3(x, 0.0, a.z)
	# Separacion de companeros.
	for p in f.ctx.footballers:
		if p == f or p.team != f.team:
			continue
		var d: Vector3 = spot - _flat(p.global_position)
		if d.length() < 3.0 and d.length() > 0.01:
			spot += d.normalized() * (3.0 - d.length())
	var half_w: float = f.ctx.pitch.config.width * 0.5 - 1.2
	spot.z = clampf(spot.z, -half_w, half_w)
	return spot

func _move_to(f: Footballer, target: Vector3, magnitude: float) -> void:
	var d: Vector3 = target - _flat(f.global_position)
	if d.length() < 0.6:
		_dir = Vector3.ZERO
		_mag = 0.0
		return
	_dir = d.normalized()
	_mag = clampf(d.length() / 3.0, 0.35, 1.0) * magnitude

func _nearest_opponent_dist(f: Footballer, ctx: MatchContext, pos: Vector3, atk: Vector3) -> float:
	var best: float = INF
	for o in ctx.footballers:
		if o.team == f.team:
			continue
		var d: Vector3 = _flat(o.global_position) - pos
		# Solo cuentan los que estan delante o a los lados (los de atras presionan menos).
		if d.dot(atk) > -1.0:
			best = minf(best, d.length())
	return best

func _lane_clear(f: Footballer, ctx: MatchContext, a: Vector3, b: Vector3, width: float) -> bool:
	var ab: Vector3 = b - a
	var len2: float = ab.length_squared()
	if len2 < 0.01:
		return true
	var blockers: Array = []
	for o in ctx.footballers:
		if o.team != f.team:
			blockers.append(o)
	for k in ctx.keepers:
		if int(k.get("team")) != f.team:
			blockers.append(k)
	for o in blockers:
		var p: Vector3 = _flat((o as Node3D).global_position)
		var u: float = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
		if u > 0.05 and (a + ab * u - p).length() < width:
			return false
	return true

func _best_pass_target(f: Footballer, ctx: MatchContext, pos: Vector3, atk: Vector3) -> Footballer:
	var best: Footballer = null
	var best_s: float = -INF
	for t in ctx.footballers:
		if t == f or t.team != f.team:
			continue
		var tp: Vector3 = _flat(t.global_position)
		var d: float = (tp - pos).length()
		if d < 3.0 or d > 20.0:
			continue
		var open: float = 6.0
		for o in ctx.footballers:
			if o.team != f.team:
				open = minf(open, (_flat(o.global_position) - tp).length())
		if open < 2.0 or not _lane_clear(f, ctx, pos, tp, 0.8):
			continue
		var progress: float = (tp - pos).dot(atk)
		var s: float = progress * 0.7 + open * 1.4 - d * 0.25
		if s > best_s:
			best_s = s
			best = t
	return best

func _avoid_opponents(f: Footballer, ctx: MatchContext, pos: Vector3, dir: Vector3, atk: Vector3) -> Vector3:
	var steer: Vector3 = dir
	for o in ctx.footballers:
		if o.team == f.team:
			continue
		var d: Vector3 = _flat(o.global_position) - pos
		var dist: float = d.length()
		if dist > 4.0 or dist < 0.01:
			continue
		if d.normalized().dot(dir) < 0.2:
			continue
		var side: Vector3 = Vector3(-dir.z, 0.0, dir.x)
		var s: float = -signf(d.dot(side)) if absf(d.dot(side)) > 0.05 else 1.0
		steer += side * s * (4.0 - dist) * 0.35
	for k in ctx.keepers:
		if int(k.get("team")) == f.team:
			continue
		var kd: Vector3 = _flat((k as Node3D).global_position) - pos
		if kd.length() < 3.0 and kd.normalized().dot(dir) > 0.5:
			steer += Vector3(-dir.z, 0.0, dir.x) * signf(-kd.z if absf(kd.z) > 0.05 else 1.0) * 0.8
	return steer.normalized()

func _avoid_walls(pos: Vector3, dir: Vector3, ctx: MatchContext) -> Vector3:
	var half_w: float = ctx.pitch.config.width * 0.5 - 1.0
	var out: Vector3 = dir
	if pos.z > half_w and dir.z > 0.0:
		out.z = -0.3
	elif pos.z < -half_w and dir.z < 0.0:
		out.z = 0.3
	return out.normalized()
