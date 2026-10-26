extends TestCase
## Sensacion de juego medida con el jugador real (futbolista con clips, pelota fisica, entrada programada como un humano):
## conducir y girar sin perder la pelota, pasar a la carrera y controlar un pase recibido. Cada cifra sale de simulaciones
## con semillas fijas; los umbrales dejan margen sobre lo medido (ver CHANGELOG, «Pase de calidad de jugabilidad»).

func _skip_if_missing() -> bool:
	PackLibrary.reload()
	if not PackLibrary.available():
		skip("falta assets/animations/pack_clips.res")
		return true
	return false

func _runner(start: Vector3) -> Dictionary:
	var ctx: MatchContext = await make_match(Vector3(0.0, 0.11, 0.0))
	var src := ScriptedInput.new()
	var f: Footballer = add_player(ctx, 0, start, 55, src, true)
	await physics_frames(6)
	return {"ctx": ctx, "src": src, "f": f}

## Conduce en +X, gira `angle_deg` y devuelve true si la pelota se escapo (> 1.6 m del jugador durante > 0.25 s).
func _turn_loses_ball(magnitude: float, sprint: bool, angle_deg: float, trial: int) -> bool:
	var w: Dictionary = await _runner(Vector3(-18.0, 0.0, 0.0))
	var ctx: MatchContext = w["ctx"]
	var src: ScriptedInput = w["src"]
	var f: Footballer = w["f"]
	f.ball_handler.rng.seed = 1000 + trial * 31
	ctx.ball.reset_at(Vector3(-17.4, 0.11, 0.0))
	await physics_frames(10)
	src.sprint = sprint
	src.move = Vector2(1.0, 0.0) * magnitude
	await wait_seconds(1.4 + 0.1 * trial)
	var a: float = deg_to_rad(angle_deg)
	src.move = Vector2(cos(a), sin(a)) * magnitude
	var lost_t: float = 0.0
	for i in 80:
		await tree.physics_frame
		if absf(f.global_position.z) > 3.8 or absf(f.global_position.x) > 18.5:
			break
		var d: float = Vector2(f.global_position.x - ctx.ball.global_position.x, f.global_position.z - ctx.ball.global_position.z).length()
		if d > 1.6:
			lost_t += 1.0 / 60.0
	cleanup()
	return lost_t > 0.25

func test_turning_with_the_ball_keeps_it_close() -> void:
	if _skip_if_missing():
		return
	var report: Array = []
	var limits := {"trote": 0.03, "carrera": 0.10, "sprint": 0.25}
	var modes := [["trote", 0.55, false], ["carrera", 1.0, false], ["sprint", 1.0, true]]
	for mode in modes:
		var lost: int = 0
		var total: int = 0
		for ang in [60.0, 90.0, 135.0, -90.0]:
			for trial in 5:
				total += 1
				if await _turn_loses_ball(mode[1], mode[2], ang, trial):
					lost += 1
		report.append("%s %d/%d" % [mode[0], lost, total])
		check(float(lost) <= float(total) * float(limits[mode[0]]), "al girar a ritmo '%s' no se pierde la pelota con frecuencia (%d de %d intentos)" % [mode[0], lost, total])
	note("giros con pelota (60/90/135/-90 grados), intentos que pierden la pelota: %s" % ", ".join(report))

func _pass_while_moving(magnitude: float, sprint: bool, trial: int) -> StringName:
	var ctx: MatchContext = await make_match(Vector3(0.0, 0.11, 0.0))
	var psrc := ScriptedInput.new()
	var passer: Footballer = add_player(ctx, 0, Vector3(-18.0, 0.0, 0.0), 55, psrc, true)
	add_player(ctx, 0, Vector3(15.0, 0.0, 4.0), 55, ScriptedInput.new(), true)
	passer.ball_handler.rng.seed = 700 + trial
	await physics_frames(8)
	ctx.ball.reset_at(Vector3(-17.4, 0.11, 0.0))
	await physics_frames(10)
	psrc.move = Vector2(1.0, 0.0) * magnitude
	psrc.sprint = sprint
	await wait_seconds(1.0 + 0.05 * trial)
	var got := {"r": &"none"}
	ctx.event_emitted.connect(func(e: GameEvent) -> void:
		if e.actor_id == passer.actor_id:
			if e.type_name() == "PASS":
				got["r"] = &"ok"
			elif e.type_name() == "KICK_WHIFF":
				got["r"] = StringName(str(e.data.get("reason"))))
	psrc.hold_pass()
	await physics_frames(14)
	psrc.release_pass()
	await wait_seconds(0.9)
	cleanup()
	return got["r"]

func test_pass_button_while_dribbling_executes_the_pass() -> void:
	if _skip_if_missing():
		return
	var report: Array = []
	for mode in [["parado", 0.0, false, 1.0], ["trote", 0.55, false, 1.0], ["carrera", 1.0, false, 1.0], ["sprint", 1.0, true, 0.75]]:
		var ok: int = 0
		var n: int = 12
		for trial in n:
			if await _pass_while_moving(mode[1], mode[2], trial) == &"ok":
				ok += 1
		report.append("%s %d/%d" % [mode[0], ok, n])
		check(float(ok) / n >= float(mode[3]) - 0.001, "el pase pulsado a ritmo '%s' se ejecuta (%d de %d)" % [mode[0], ok, n])
	note("pases ejecutados al pulsar el boton: %s" % ", ".join(report))

func test_first_touch_controls_a_ground_pass_to_a_standing_receiver() -> void:
	if _skip_if_missing():
		return
	var ok: int = 0
	var n: int = 6
	for trial in n:
		var ctx: MatchContext = await make_match(Vector3(0.0, 0.11, 0.0))
		var psrc := ScriptedInput.new()
		var passer: Footballer = add_player(ctx, 0, Vector3(-5.0, 0.0, 0.0), 55, psrc, true)
		var recv: Footballer = add_player(ctx, 0, Vector3(5.0, 0.0, 0.0), 55, ScriptedInput.new(), true)
		passer.ball_handler.rng.seed = 300 + trial
		recv.ball_handler.rng.seed = 400 + trial
		await physics_frames(8)
		passer.locomotion.yaw = Locomotion.yaw_from_dir(Vector3(1, 0, 0))
		recv.locomotion.yaw = Locomotion.yaw_from_dir(Vector3(-1, 0, 0))
		ctx.ball.reset_at(Vector3(-4.4, 0.11, 0.0))
		await physics_frames(20)
		psrc.move = Vector2(1, 0)
		psrc.hold_pass()
		await physics_frames(30)
		psrc.release_pass()
		psrc.move = Vector2.ZERO
		await wait_seconds(3.0)
		var d: float = Vector2(recv.global_position.x - ctx.ball.global_position.x, recv.global_position.z - ctx.ball.global_position.z).length()
		if d < 1.3 and ctx.ball.linear_velocity.length() < 3.5:
			ok += 1
		cleanup()
	note("pase raso de 10 m a un receptor parado: lo controla %d de %d" % [ok, n])
	check(ok >= n - 1, "un receptor parado controla un pase raso (%d de %d)" % [ok, n])
