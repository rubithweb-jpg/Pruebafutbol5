# PLAYER — Futbolista de campo

## Identificación

- **Responsabilidad exacta:** el futbolista de campo, controlado únicamente a través de `InputFrame`: movimiento con aceleración progresiva y giro dependiente de la velocidad (`Locomotion`), conducción por toques físicos, control de primer toque, posesión, robo (`BallHandler`), y la patada de pase/tiro cuyo impulso se aplica en el instante de contacto de la animación. La presión defensiva y las asistencias de pase/tiro viven en [ASSISTANCE](ASSISTANCE.md); el modelo y las animaciones en [ANIMATIONS](ANIMATIONS.md).
- **Estado:** implementado para **un** jugador humano por equipo. No hay IA ni cambio de jugador.
- **Última verificación:** <!-- AUTO:verified -->
2026-10-26
<!-- /AUTO -->

## Archivos responsables

| Ruta | Función | Símbolos / nodos relevantes | Dependencias directas |
|---|---|---|---|
| `scripts/player/footballer.gd` | Clase `Footballer` (`CharacterBody3D`): orquesta entrada → presión → locomoción → `move_and_slide` → manejo de pelota → visual. Crea la cápsula de colisión (`CollisionShape3D`) y el hijo `Visual` | `Footballer.setup`, `Footballer._physics_process`, `Footballer.place_at`, `Footballer.capture_state` | `MatchContext`, `Locomotion`, `BallHandler`, `PressController`, `FootballerVisual` |
| `scripts/player/locomotion.gd` | Clase `Locomotion` (`RefCounted`, pura): velocidad, giro, agarre lateral, frenada, sprint y resistencia | `Locomotion.step`, `Locomotion.speed_for_magnitude`, `Locomotion.max_run_speed`, `Locomotion.max_sprint_speed` | `PlayerTuning`, `PlayerAttributes` |
| `scripts/player/ball_handler.gd` | Clase `BallHandler` (`RefCounted`): toques, primer toque, posesión, robo, botones con carga, patada con contacto sincronizado | `BallHandler.update`, `BallHandler._try_dribble_touch`, `BallHandler._try_first_touch`, `BallHandler.request_kick`, `BallHandler.attempt_tackle` | `Ball`, `PassAssist`, `ShotAssist`, `KickModel` |
| `scripts/player/player_tuning.gd` | Recurso `PlayerTuning`: todos los parámetros de locomoción y conducción | ver «Mapa de parámetros» | — |
| `scenes/player/footballer.tscn` | Nodo raíz `Footballer` (`CharacterBody3D`) con el script; el resto se crea en `_ready` | nodo `Footballer` | `scripts/player/footballer.gd` |
| `scripts/player/human_input.gd` | `InputSource` que lee `InputMap` (ver [INPUTS](INPUTS.md)) | `HumanInput.poll` | — |

**No modificar para cambiar la sensación de movimiento:** `ball_handler.gd` (la pelota no depende de cómo se acelera) ni `scripts/ui/touch_controls.gd`. **No modificar para cambiar la conducción:** `locomotion.gd`.

## Mapa de parámetros

<!-- AUTO:params:PlayerTuning -->
| Parámetro | Defecto | Rango / tipo | Definido en | Dónde se usa (accesos reales) | Descripción |
|---|---|---|---|---|---|
| `walk_speed` | `1.8` | float | `scripts/player/player_tuning.gd:7` | `scripts/player/ball_handler.gd:571`, `scripts/player/locomotion.gd:120`, `scripts/player/locomotion.gd:185` |  (Velocidades (m/s)) |
| `jog_speed` | `3.6` | float | `scripts/player/player_tuning.gd:8` | `scripts/player/ball_handler.gd:105`, `scripts/player/locomotion.gd:186`, `scripts/player/locomotion.gd:195` |  (Velocidades (m/s)) |
| `run_speed` | `5.2` | float | `scripts/player/player_tuning.gd:9` | `scripts/player/locomotion.gd:57`, `scripts/player/locomotion.gd:172` |  (Velocidades (m/s)) |
| `sprint_speed` | `6.8` | float | `scripts/player/player_tuning.gd:10` | `scripts/player/ball_handler.gd:105`, `scripts/player/locomotion.gd:60` |  (Velocidades (m/s)) |
| `backpedal_factor` | `0.72` | float | `scripts/player/player_tuning.gd:11` | **sin uso** |  (Velocidades (m/s)) |
| `accel` | `6.2` | float | `scripts/player/player_tuning.gd:15` | `scripts/player/ball_handler.gd:572`, `scripts/player/locomotion.gd:139`, `scripts/player/locomotion.gd:176` | Aceleracion al empujar el joystick (m/s^2). (Aceleracion) |
| `decel` | `9.5` | float | `scripts/player/player_tuning.gd:17` | `scripts/player/locomotion.gd:131`, `scripts/player/locomotion.gd:134`, `scripts/player/locomotion.gd:136`, `scripts/player/locomotion.gd:176` | Desaceleracion al soltar el joystick. (Aceleracion) |
| `brake` | `14.0` | float | `scripts/player/player_tuning.gd:19` | `scripts/player/locomotion.gd:133`, `scripts/player/locomotion.gd:144` | Desaceleracion cuando el joystick apunta contra el movimiento (frenada). (Aceleracion) |
| `lateral_grip` | `9.0` | float | `scripts/player/player_tuning.gd:21` | `scripts/player/locomotion.gd:148` | Agarre lateral: cuanto rapido se elimina la velocidad lateral respecto al cuerpo (1/s). (Aceleracion) |
| `turn_rate_standing` | `620.0` | float | `scripts/player/player_tuning.gd:25` | `scripts/player/ball_handler.gd:252`, `scripts/player/locomotion.gd:106`, `scripts/player/locomotion.gd:167` | Velocidad de giro parado (grados/s). (Giro) |
| `turn_rate_sprint` | `165.0` | float | `scripts/player/player_tuning.gd:27` | `scripts/player/ball_handler.gd:252`, `scripts/player/locomotion.gd:106` | Velocidad de giro a sprint maximo (grados/s). (Giro) |
| `sharp_turn_angle_deg` | `115.0` | float | `scripts/player/player_tuning.gd:29` | `scripts/player/locomotion.gd:112` | Si el angulo al objetivo supera esto a mas de 70 % de la velocidad maxima, hay que frenar antes de girar. (Giro) |
| `stamina_drain_sprint` | `0.16` | float | `scripts/player/player_tuning.gd:32` | `scripts/player/locomotion.gd:81` |  (Resistencia) |
| `stamina_regen` | `0.07` | float | `scripts/player/player_tuning.gd:33` | `scripts/player/locomotion.gd:85`, `scripts/player/locomotion.gd:164` |  (Resistencia) |
| `stamina_regen_standing` | `0.14` | float | `scripts/player/player_tuning.gd:34` | `scripts/player/locomotion.gd:85`, `scripts/player/locomotion.gd:164` |  (Resistencia) |
| `exhausted_speed_factor` | `0.82` | float | `scripts/player/player_tuning.gd:36` | `scripts/player/locomotion.gd:62` | Fraccion de velocidad de sprint que aun se mantiene con la resistencia agotada. (Resistencia) |
| `touch_reach` | `0.95` | float | `scripts/player/player_tuning.gd:40` | `scripts/ai/ai_input.gd:113`, `scripts/player/ball_handler.gd:101`, `scripts/player/ball_handler.gd:187`, `scripts/player/ball_handler.gd:455` | Distancia maxima (m) a la que puede dar un toque. (Conduccion) |
| `touch_interval_jog` | `0.28` | float | `scripts/player/player_tuning.gd:42` | `scripts/player/ball_handler.gd:511` | Segundos entre toques (trote). (Conduccion) |
| `touch_interval_sprint` | `0.38` | float | `scripts/player/player_tuning.gd:44` | `scripts/player/ball_handler.gd:511` | Segundos entre toques (sprint, toques mas largos y espaciados). (Conduccion) |
| `touch_lead_jog` | `0.62` | float | `scripts/player/player_tuning.gd:46` | `scripts/player/ball_handler.gd:583` | Distancia objetivo (m) a la que se coloca la pelota delante del jugador al trotar / sprintar. (Conduccion) |
| `touch_lead_sprint` | `1.05` | float | `scripts/player/player_tuning.gd:47` | `scripts/player/ball_handler.gd:583` |  (Conduccion) |
| `touch_overshoot_sprint` | `1.0` | float | `scripts/player/player_tuning.gd:49` | `scripts/player/ball_handler.gd:585` | Desviacion tipica (m) de los toques largos a sprint con control 0 (disminuye con la habilidad). (Conduccion) |
| `touch_escape_factor` | `1.05` | float | `scripts/player/player_tuning.gd:51` | `scripts/player/ball_handler.gd:543` | Toque de recuperacion: se adelanta cuando la pelota va a quedar a mas de este multiplo del alcance en 0.14 s. (Conduccion) |
| `touch_error_deg` | `4.0` | float | `scripts/player/player_tuning.gd:53` | `scripts/player/ball_handler.gd:611` | Error angular base de un toque (grados) con control de balon 50. (Conduccion) |
| `touch_error_max_deg` | `8.0` | float | `scripts/player/player_tuning.gd:55` | `scripts/player/ball_handler.gd:616` | Tope (grados) del error angular de un toque aunque se sumen sprint y giro. (Conduccion) |
| `touch_error_sprint` | `2.0` | float | `scripts/player/player_tuning.gd:57` | `scripts/player/ball_handler.gd:612` | Error extra por sprint (multiplicador) y por giro brusco. (Conduccion) |
| `touch_error_turn` | `1.9` | float | `scripts/player/player_tuning.gd:58` | `scripts/player/ball_handler.gd:613` |  (Conduccion) |
| `kick_lockout` | `0.35` | float | `scripts/player/player_tuning.gd:60` | `scripts/player/ball_handler.gd:499` | Segundos de bloqueo despues de un pase/tiro antes de poder volver a tocar la pelota. (Conduccion) |
| `possession_radius` | `1.1` | float | `scripts/player/player_tuning.gd:61` | `scripts/ai/ai_input.gd:275`, `scripts/assistance/press_controller.gd:42`, `scripts/assistance/press_controller.gd:47`, `scripts/assistance/press_controller.gd:49` (+2) |  (Conduccion) |
| `kick_contact_radius` | `0.30` | float | `scripts/player/player_tuning.gd:65` | `scripts/player/ball_handler.gd:432` | Radio (m) entre el pie (posicion de contacto medida del clip) y el centro de la pelota para que el golpeo cuente. (Patada con animacion del pack) |
| `kick_foot_max_height` | `0.25` | float | `scripts/player/player_tuning.gd:68` | `scripts/player/ball_handler.gd:298` | Altura maxima (m) de la punta del pie y velocidad minima de avance (m/s) para que un punto de la trayectoria del clip cuente como golpeo: el pie debe ir bajo y lanzado, no subiendo ni frenando. (Patada con animacion del pack) |
| `kick_foot_min_speed` | `3.0` | float | `scripts/player/player_tuning.gd:69` | `scripts/player/ball_handler.gd:298` |  (Patada con animacion del pack) |
| `kick_adjust_max` | `0.30` | float | `scripts/player/player_tuning.gd:72` | `scripts/player/ball_handler.gd:318`, `scripts/player/ball_handler.gd:368` | Ajuste de zancada: desplazamiento maximo (m) del cuerpo hacia la pelota durante la latencia para que el pie llegue. Crece con la velocidad (a sprint la zancada es larga): kick_adjust_max + kick_adjust_sprint * ratio de sprint. (Patada con animacion del pack) |
| `kick_adjust_sprint` | `0.20` | float | `scripts/player/player_tuning.gd:73` | `scripts/player/ball_handler.gd:318`, `scripts/player/ball_handler.gd:368` |  (Patada con animacion del pack) |
| `kick_start_residual` | `0.18` | float | `scripts/player/player_tuning.gd:75` | `scripts/player/ball_handler.gd:355`, `scripts/player/ball_handler.gd:383` | Error maximo (m) que se acepta al INICIAR el balanceo, medido tras el ajuste con la pelota y el jugador predichos al contacto. (Patada con animacion del pack) |
| `kick_latency` | `0.20` | float | `scripts/player/player_tuning.gd:77` | `scripts/player/ball_handler.gd:235` | Latencia objetivo (s) entre soltar el boton y el golpeo; el clip se acelera/recorta para llegar a ella. (Patada con animacion del pack) |
| `kick_clip_speed_max` | `1.6` | float | `scripts/player/player_tuning.gd:79` | `scripts/player/ball_handler.gd:236` | Aceleracion maxima del clip de patada (1 = velocidad original del clip). (Patada con animacion del pack) |
| `kick_turn_scale` | `0.35` | float | `scripts/player/player_tuning.gd:81` | `scripts/player/ball_handler.gd:249`, `scripts/player/ball_handler.gd:253`, `scripts/player/ball_handler.gd:398` | Fraccion de la velocidad de giro que se conserva mientras el pie se prepara (el pie de apoyo fija la direccion). (Patada con animacion del pack) |
| `kick_follow_through` | `0.30` | float | `scripts/player/player_tuning.gd:83` | `scripts/player/ball_handler.gd:403` | Segundos de continuacion del clip tras el golpeo antes de devolver el cuerpo a la marcha. (Patada con animacion del pack) |
| `first_touch_absorb` | `0.65` | float | `scripts/player/player_tuning.gd:87` | `scripts/player/ball_handler.gd:657` | Fraccion de energia que absorbe el control orientado (0 = rebote total). (Contacto con balon) |
| `body_mass` | `75.0` | float | `scripts/player/player_tuning.gd:88` | **sin uso** |  (Contacto con balon) |
| `capsule_radius` | `0.3` | float | `scripts/player/player_tuning.gd:89` | `scripts/player/footballer.gd:65` |  (Contacto con balon) |
| `capsule_height` | `1.75` | float | `scripts/player/player_tuning.gd:90` | `scripts/player/footballer.gd:66`, `scripts/player/footballer.gd:68` |  (Contacto con balon) |
<!-- /AUTO -->

### Riesgos al modificar (con las pruebas que los vigilan)

| Parámetro(s) | Efecto real y riesgo |
|---|---|
| `walk_speed`, `jog_speed`, `run_speed`, `sprint_speed` | `Locomotion.speed_for_magnitude` / `max_sprint_speed`. La animación acompaña hasta `FootballerVisual.MAX_TIME_SCALE (2.9) × NATURAL_SPEED["run"] (2.5) = 7.25 m/s`: **por encima de ~7.2 m/s los pies patinan** (la cadencia se satura). El `BlendSpace` de locomoción llega hasta 7.5. Los atributos escalan la velocidad con `PlayerAttributes.factor("speed", 0.12)`. |
| `accel`, `decel`, `brake` | `test_acceleration_is_progressive` (v(0.2 s) < 50 % de la velocidad de carrera; 90 % entre 0.9 y 2.2 s; medido 1.05 s) y `test_stops_without_sliding_like_ice` (frena en < 0.9 s y < 2 m; medido 0.55 s / 1.38 m). |
| `turn_rate_standing`, `turn_rate_sprint`, `sharp_turn_angle_deg` | `test_turning_rate_depends_on_speed` (giro de 90° parado entre 0.08 y 0.30 s; a sprint ≥ 0.25 s y > 1.5× el parado; medidos 0.15 s / 0.30 s) y `test_reversal_at_sprint_brakes_first_and_never_slides_sideways`. |
| `lateral_grip` | Es el «anti-hielo»: elimina la velocidad lateral respecto al cuerpo. Valores bajos = deslizamiento; la prueba exige desplazamiento lateral < 2.0 m al invertir a sprint (medido 0.67 m). |
| `touch_reach`, `touch_interval_*`, `touch_lead_*`, `touch_overshoot_sprint`, `touch_error_*` | Conducción: `test_dribble_at_jog_keeps_ball_close_with_physical_touches` (pelota < 2 m el 85 % del tiempo y 8–40 toques en 6 s; medido 100 % y 21 toques), `test_sprint_dribble_is_less_precise_than_jog`, `test_better_ball_carrying_means_tighter_control`, `test_turning_with_ball_changes_ball_direction_physically`. Subir `touch_lead_*` o `touch_overshoot_sprint` alarga los toques y pierde la pelota más seguido. |
| `possession_radius` | Define «tiene la pelota»: lo usan `BallHandler.has_possession`, el primer toque y `PressController._find_carrier`. Cambiarlo altera cuándo se activa la presión y el robo. |
| `kick_lockout` | Bloqueo de toques tras un pase/tiro (`BallHandler._after_kick`). Muy bajo: el jugador vuelve a empujar la pelota recién pateada. |
| `first_touch_absorb` | Fracción de energía absorbida en el control (`BallHandler._try_first_touch`, escalada por `ball_control`). |
| `capsule_radius`, `capsule_height` | Tamaño de la cápsula física (`Footballer._ready`). **No** escalan el modelo (que usa `FootballerVisual.MODEL_HEIGHT_SCALE = 1.75`): si se cambia uno, cambiar el otro a mano. |
| `stamina_*`, `exhausted_speed_factor` | Resistencia en `Locomotion.step` (el sprint la consume; agotado, la velocidad máxima cae). `test_sprint_is_faster_and_drains_stamina`. |
| `backpedal_factor`, `body_mass` | **Sin uso**: definidos pero ningún código los lee. |

### Valores fijos en el código de este sistema

Ver la tabla «Valores fijos» de [ARCHITECTURE.md](../ARCHITECTURE.md) (carga del pase 0.8 s, retardo de contacto, buffer 0.3 s, márgenes de alcance, bloqueo +0.4 s, pérdida 0.9 al patear, tope conduciendo 0.86–0.97).

## Mapa de funciones

<!-- AUTO:funcs:scripts/player/footballer.gd -->
| Función | Línea | Qué hace |
|---|---|---|
| `Footballer._ready()` | 53 |  |
| `Footballer.setup(context: MatchContext, team_index: int, id: int, attrs: PlayerAttributes, source: InputSource)` | 84 | Configura el jugador dentro de un partido. |
| `Footballer.set_attributes(attrs: PlayerAttributes)` | 101 |  |
| `Footballer._exit_tree()` | 106 |  |
| `Footballer.set_ball_ghost(on: bool)` | 114 | Durante un golpeo en el aire (cabezazo, volea) la pelota atraviesa el cuerpo hasta el contacto del clip: si no, rebota contra la capsula ant |
| `Footballer.has_ball()` | 117 |  |
| `Footballer.reset_motion()` | 120 |  |
| `Footballer.place_at(pos: Vector3, yaw: float)` | 128 |  |
| `Footballer._physics_process(delta: float)` | 141 |  |
| `Footballer._cancel_reaction()` | 218 |  |
| `Footballer._on_match_event(e: GameEvent)` | 228 | Reacciones de presentacion a eventos del partido: - Gol: el goleador, el asistente, el resto del equipo y el rival reaccionan distinto (un a |
| `Footballer.rng_delay()` | 257 |  |
| `Footballer._set_reaction(situation: StringName, wait: float, cut: float)` | 260 |  |
| `Footballer._update_reaction(delta: float)` | 267 | La reaccion a un gol arranca cuando el jugador casi se ha detenido (o tras REACTION_MAX_WAIT) para no animar un clip en el sitio sobre un cu |
| `Footballer._check_player_collisions()` | 281 | Un choque a velocidad con otro jugador provoca un tropiezo (presentacion) o, si es fuerte, un golpe de hombro y caida. |
| `Footballer.capture_state()` | 303 | Datos replicables del jugador (para snapshots de red / pruebas). |
<!-- /AUTO -->

<!-- AUTO:funcs:scripts/player/locomotion.gd -->
| Función | Línea | Qué hace |
|---|---|---|
| `Locomotion._init(t: PlayerTuning = null, a: PlayerAttributes = null)` | 38 |  |
| `Locomotion.dir_from_yaw(y: float)` | 43 | Vector de direccion (unitario) para un yaw. yaw = 0 mira hacia -Z. |
| `Locomotion.yaw_from_dir(d: Vector3)` | 46 |  |
| `Locomotion.forward()` | 49 |  |
| `Locomotion.right()` | 52 |  |
| `Locomotion.max_run_speed()` | 56 |  |
| `Locomotion.max_sprint_speed()` | 59 |  |
| `Locomotion.step(desired_dir: Vector3, magnitude: float, want_sprint: bool, delta: float, speed_cap: float = -1.0)` | 68 | Avanza un paso de simulacion. desired_dir: direccion deseada en el mundo (unitaria o cero). magnitude: 0..1 (intensidad del joystick). speed |
| `Locomotion._step_jockey(desired_dir: Vector3, magnitude: float, delta: float, speed_cap: float)` | 157 |  |
| `Locomotion.speed_for_magnitude(m: float)` | 184 | Velocidad objetivo (m/s) para una intensidad de joystick 0..1 (sin sprint). |
| `Locomotion.turn_rate_blocks_speed(angle_diff: float)` | 194 |  |
| `Locomotion.face_towards(dir: Vector3, delta: float, rate_deg: float = 540.0)` | 198 | Orienta el cuerpo sin moverlo (por ejemplo, al encarar la pelota estando parado). |
| `Locomotion.stop()` | 205 |  |
<!-- /AUTO -->

<!-- AUTO:funcs:scripts/player/ball_handler.gd -->
| Función | Línea | Qué hace |
|---|---|---|
| `BallHandler._init(o: Footballer)` | 68 |  |
| `BallHandler.ball()` | 72 |  |
| `BallHandler.ball_offset()` | 75 |  |
| `BallHandler.ball_distance()` | 79 |  |
| `BallHandler.has_possession()` | 82 |  |
| `BallHandler.controls_ball()` | 90 | El equipo del jugador controla la pelota: esta cerca Y fue tocada por ultima vez por su equipo. Una pelota suelta o ultimo tocada por el riv |
| `BallHandler.can_reach(reach: float)` | 94 |  |
| `BallHandler.touch_reach()` | 99 | Alcance efectivo de un toque: el jugador estira mas la pierna a mayor velocidad. |
| `BallHandler._sprint_ratio()` | 103 |  |
| `BallHandler.assist_pass_level()` | 107 |  |
| `BallHandler.assist_shot_level()` | 110 |  |
| `BallHandler.update(frame: InputFrame, stick_world: Vector3, stick_mag: float, desired_dir: Vector3, dt: float)` | 114 | Paso de simulacion. stick_world: direccion del joystick en el mundo; desired_dir: direccion deseada final. |
| `BallHandler._update_buttons(frame: InputFrame, stick_world: Vector3, dt: float)` | 144 |  |
| `BallHandler._queue(action: StringName, charge: float, lob: bool, stick_world: Vector3)` | 169 |  |
| `BallHandler._try_execute_pending()` | 176 |  |
| `BallHandler.contact_delay(action: StringName, charge: float)` | 195 | Segundos entre el inicio de la patada y el golpeo (la animacion y el impulso comparten este instante). |
| `BallHandler.request_kick(action: StringName, stick_world: Vector3, charge: float, lob: bool)` | 199 | Comienza una patada: arranca la animacion y programa el impulso para el instante de contacto. |
| `BallHandler.is_kick_in_progress()` | 214 |  |
| `BallHandler.uses_clip_kicks()` | 220 | true si este futbolista patea con los clips del pack (visual con libreria y clips de patada en el sitio). |
| `BallHandler.foot_contact_world(contact: Dictionary, pos: Vector3, yaw: float)` | 226 | Posicion MUNDIAL de la punta del pie en el golpeo de un clip, para un jugador en pos con orientacion yaw. contact.pos es (adelante, arriba,  |
| `BallHandler.clip_timing(contact_time: float, action: StringName, charge: float)` | 233 | Velocidad de reproduccion, punto de inicio y latencia real para que el clip llegue a su contacto en kick_latency. |
| `BallHandler._predicted_yaw(latency: float)` | 245 | Vector (pelota - pie) en el plano, en metros, al instante de contacto del clip, PREDICHO desde el estado actual (jugador y pelota siguen su  |
| `BallHandler.force_dribble_touch(dir: Vector3)` | 257 | Un toque de conduccion en la direccion dada (lo usa una accion con raiz, que no pasa por update()). |
| `BallHandler.abort_kick()` | 261 | Aborta una patada en curso y la accion pendiente (caida, barrida): no se aplica ningun impulso. |
| `BallHandler.cancel_charge()` | 272 | Cancela la carga de pase/tiro en curso sin ejecutar nada (la IA lo usa cuando la pelota se le fue). |
| `BallHandler.predicted_foot_to_ball(contact: Dictionary, latency: float)` | 278 |  |
| `BallHandler.contact_samples(contact: Dictionary)` | 289 | Puntos validos de golpeo de un clip: muestras de la trayectoria del pie (adelante, arriba, derecha) con la punta baja y lanzada hacia adelan |
| `BallHandler.plan_aerial_kick(action: StringName, charge: float)` | 312 | Planifica un golpeo con la pelota en el aire: busca, entre los clips de cabezazo y volea, el instante en que la cabeza o la punta del pie (c |
| `BallHandler.plan_clip_kick(action: StringName, charge: float, lob: bool)` | 361 | Elige el mejor clip, pierna E INSTANTE DE CONTACTO para la accion. El instante sale de la trayectoria real del pie del clip (contact_samples |
| `BallHandler._start_clip_kick(action: StringName, plan: Dictionary, stick_world: Vector3, charge: float, lob: bool)` | 385 |  |
| `BallHandler._log_kick(action: StringName, result: StringName, extra: Dictionary = {})` | 406 |  |
| `BallHandler._finish_clip_kick()` | 415 | Resuelve el golpeo de una patada con clip: valido solo si la pelota esta a kick_contact_radius del pie REAL (posicion de contacto del clip,  |
| `BallHandler._finish_kick()` | 448 |  |
| `BallHandler.perform_pass(stick_world: Vector3, charge: float, lob: bool)` | 466 | Ejecuta un pase ahora mismo (la pelota debe estar a alcance). Devuelve el resultado. |
| `BallHandler.perform_shot(stick_world: Vector3, charge: float, lob: bool)` | 482 |  |
| `BallHandler._after_kick(action: StringName, res: KickModel.KickResult)` | 497 |  |
| `BallHandler._touch_interval(ratio: float)` | 509 | Segundos entre toques. Con el pack, la cadencia sigue a la de los pasos de la animacion (uno por apoyo a trote, uno cada dos apoyos a carrer |
| `BallHandler._try_dribble_touch(desired_dir: Vector3, stick_mag: float)` | 520 |  |
| `BallHandler._try_first_touch(desired_dir: Vector3)` | 632 |  |
| `BallHandler.attempt_tackle(carrier: Footballer)` | 685 | Intenta quitar la pelota. No esta garantizado: depende de distancia, orientacion, equilibrio, velocidad relativa y atributos de ambos jugado |
<!-- /AUTO -->

<!-- AUTO:signals:scripts/player/ball_handler.gd -->
| Señal | Línea | Descripción |
|---|---|---|
| `BallHandler.kicked(action: StringName, result: KickModel.KickResult)` | 11 | Interaccion del futbolista con la pelota. Todo ocurre mediante IMPULSOS en el instante del contacto: nunca se fija la posicion de la pelota ni se anula su velocidad. - Conduccion: toques periodicos cuya fuerza depende de la velocidad, el giro y los atributos. - Control de primer toque: absorbe parte de la energia de un balon que llega (con error). - Pase y tiro: se calculan con PassAssist / ShotAssist; se ejecutan al soltar el boton y se guardan en buffer 0.3 s si la pelota aun no esta a alcance. - Disputa: robo probabilistico dependiente de orientacion, atributos y velocidad relativa. |
| `BallHandler.touched_ball(kind: StringName)` | 12 |  |
<!-- /AUTO -->

<!-- AUTO:signals:scripts/player/footballer.gd -->
| Señal | Línea | Descripción |
|---|---|---|
| `Footballer.kicked(action: StringName, result: KickModel.KickResult)` | 8 | Futbolista de campo. Orquesta: entrada (InputFrame) -> intencion -> locomocion -> contacto con la pelota. No importa si lo controla una persona, la IA o la red: todos pasan por InputFrame.  Estado replicable separado de la presentacion: la presentacion es FootballerVisual (hijo "Visual"). |
| `Footballer.tackled(won: bool)` | 9 |  |
<!-- /AUTO -->

## Recorrido de ejecución

**Cada paso de física** (`Footballer._physics_process`):
1. `InputSource.poll` → `InputFrame` (si `MatchContext.input_enabled` es falso, un `InputFrame` vacío).
2. `MatchContext.screen_to_world(frame.move)` → dirección deseada en el mundo (relativa a la cámara).
3. Si `press_held` y el equipo no controla el balón: `PressController.update` sustituye la dirección/intensidad (la presión intenta robar con `BallHandler.attempt_tackle`).
4. Con la pelota cerca (`BallHandler.has_possession`) se limita la velocidad (`0.86–0.97 × max_sprint_speed` según `ball_carrying`).
5. `Locomotion.step`: velocidad objetivo por intensidad del joystick (`walk/jog/run`) o `sprint`; giro limitado por velocidad; si el giro es muy cerrado a alta velocidad el objetivo baja a `walk_speed` (frenar antes de girar); aceleración con `accel/decel/brake`; el agarre elimina la componente lateral.
6. `move_and_slide` (la colisión con paredes/jugadores corrige la velocidad real) → `rotation.y = locomotion.yaw`.
7. `BallHandler.update` en este orden: botones con carga (`_update_buttons`) → si hay patada en curso, avanzar su temporizador y, al llegar el contacto, `_finish_kick` → ejecutar acción pendiente en buffer (`_try_execute_pending` → `request_kick`) → si hay `lockout`, nada más → `_try_first_touch` → `_try_dribble_touch`.
8. `FootballerVisual.update_motion` (animación y lean).

**Conducción** (`BallHandler._try_dribble_touch`; corregida en la integración del pack, ver [ANIMATION_PACK](ANIMATION_PACK.md) «ANTES y DESPUÉS»: error del toque sobre la velocidad relativa al jugador, hueco planificado acotado al alcance del siguiente toque, umbral de re-toque según ese hueco y, con el pack, cadencia = apoyos de la animación): cuando el temporizador de toque expira y la pelota está al alcance (`touch_reach`·0.85, o más en giros/lateral), se calcula una posición objetivo delante del jugador (`touch_lead_jog`/`touch_lead_sprint`), la velocidad necesaria para colocarla allí y se aplica con `Ball.kick` (error angular y de módulo según sprint, giro y atributos). Nunca se fija la posición de la pelota.

**Patada** (pase/tiro). Dos caminos; elige `BallHandler.uses_clip_kicks()`:

- **Con el pack** (visual con `PackLibrary` y clips de patada en el sitio): al soltar el botón (o por buffer de 0.3 s) `_try_execute_pending` llama a `plan_clip_kick`, que para cada clip candidato (`AnimationCatalog.kick_candidates`: pase → `Soccer_Pass` / `strike_foward_jog_inplace`, ambos pies; tiro y pase alto → `strike_foward_jog_inplace`) recorre los puntos válidos de la **trayectoria medida de la punta del pie** (`contact_samples`: punta a ≤ `kick_foot_max_height`, avanzando ≥ `kick_foot_min_speed`), predice jugador y pelota hasta ese instante (`predicted_foot_to_ball`: velocidades y giro reducido por `kick_turn_scale`) y calcula cuánto debería moverse el cuerpo (ajuste de zancada ≤ `kick_adjust_max` + `kick_adjust_sprint`·ratio de sprint). Solo si el residuo queda ≤ `kick_start_residual` empieza la patada (`_start_clip_kick`): reproduce el clip acelerado (≤ ×`kick_clip_speed_max`) y desde el punto necesario para llegar al contacto en `kick_latency` s; mueve el cuerpo con `Footballer.nudge_velocity` (no entra en `Locomotion`) y baja el giro (`Locomotion.turn_scale`). **Si ningún pie llega, no hay patada**: tras el buffer se cuenta `kick_stats["out_of_reach"]` y se emite `KICK_WHIFF` con `reason = "out_of_reach"`. En el contacto `_finish_clip_kick` mide la distancia entre la pelota y el pie **real** (posición de contacto del clip con el jugador donde está ahora): ≤ `kick_contact_radius` → `perform_pass`/`perform_shot` (impulso con las asistencias, `PASS`/`SHOT` con `clip`, `foot_distance`, `latency`, `adjust_m`); si no, `KICK_WHIFF` con `reason = "missed"`, sin impulso ni teletransporte. Cada intento queda en `kick_log` y `kick_stats`.
- **Sin el pack** (o sin visual): el camino antiguo. `request_kick` fija `contact_delay` y arranca `ProceduralPose` con ese tiempo; en el contacto `_finish_kick`, si la pelota sigue a `touch_reach + 0.5`, `perform_pass`/`perform_shot`; si no, `KICK_WHIFF`.

## Pruebas

- **Ejecutar:** `tools/run_tests.sh pack_kick` (contacto pie–pelota con clips; se omite sin la librería local), `tools/run_tests.sh pack_dribble` (métricas de conducción y ejecución de pase/tiro por régimen, ~15 s), `tools/run_tests.sh locomotion`, `tools/run_tests.sh dribbling`, `tools/run_tests.sh kick_timing`, `tools/run_tests.sh touch_controls` (extremo a extremo con joystick táctil). Todo: `tools/run_tests.sh`.
- **Última ejecución completa (2026-10-26):** headless con la librería local: 85 pruebas, 0 fallidas, 2 omitidas (necesitan render), 529 comprobaciones; con render (Xvfb): 85 pruebas, 0 fallidas, 553 comprobaciones; sin la librería local: 85 pruebas, 0 fallidas, 26 omitidas, 221 comprobaciones. `test_kick_timing` cubre solo el camino procedural (fuerza `prefer_pack = false`).

<!-- AUTO:tests:tests/test_locomotion.gd -->
| Prueba | Línea |
|---|---|
| `test_acceleration_is_progressive` | 15 |
| `test_sprint_is_faster_and_drains_stamina` | 35 |
| `test_stops_without_sliding_like_ice` | 46 |
| `test_turning_rate_depends_on_speed` | 61 |
| `test_reversal_at_sprint_brakes_first_and_never_slides_sideways` | 83 |
| `test_attributes_scale_speed_within_limits` | 107 |
<!-- /AUTO -->

<!-- AUTO:tests:tests/test_dribbling.gd -->
| Prueba | Línea |
|---|---|
| `test_dribble_at_jog_keeps_ball_close_with_physical_touches` | 34 |
| `test_sprint_dribble_is_less_precise_than_jog` | 42 |
| `test_better_ball_carrying_means_tighter_control` | 50 |
| `test_no_touch_when_standing_still` | 56 |
| `test_turning_with_ball_changes_ball_direction_physically` | 64 |
| `test_player_collides_with_walls` | 80 |
<!-- /AUTO -->

<!-- AUTO:tests:tests/test_kick_timing.gd -->
| Prueba | Línea |
|---|---|
| `test_ball_impulse_happens_at_contact_not_at_button_release` | 9 |
| `test_kick_whiffs_if_the_ball_moves_away_during_the_swing` | 46 |
| `test_pose_curves_are_continuous_and_peak_at_contact` | 71 |
<!-- /AUTO -->

<!-- AUTO:tests:tests/test_pack_kick.gd -->
| Prueba | Línea |
|---|---|
| `test_only_in_place_clips_are_connected_to_kicks` | 29 |
| `test_pass_contact_is_synchronised_with_the_foot_arrival` | 42 |
| `test_each_candidate_foot_hits_when_the_ball_is_on_it` | 85 |
| `test_ball_out_of_reach_gives_no_kick_and_no_teleport` | 109 |
| `test_ball_leaving_during_the_swing_is_a_real_whiff` | 128 |
| `test_reach_is_limited_by_the_leg_not_a_fixed_radius` | 151 |
| `test_stride_adjustment_reaches_a_ball_slightly_off_the_foot` | 172 |
| `test_contact_instant_comes_from_the_foot_trajectory` | 201 |
<!-- /AUTO -->

<!-- AUTO:tests:tests/test_pack_dribble_metrics.gd -->
| Prueba | Línea |
|---|---|
| `test_dribble_distribution_at_jog_run_and_sprint` | 130 |
| `test_pass_and_shot_execution_rate_per_speed` | 152 |
<!-- /AUTO -->

<!-- AUTO:tests:tests/test_pack_reactions.gd -->
| Prueba | Línea |
|---|---|
| `test_goal_makes_the_scoring_team_celebrate_and_the_other_one_mourn` | 22 |
| `test_own_goal_scorer_is_on_the_conceding_team` | 46 |
| `test_reaction_waits_for_a_running_player_to_slow_down` | 55 |
| `test_slow_first_touch_plays_receive_and_fast_one_does_not` | 75 |
| `test_kick_cancels_a_reaction_and_actions_never_overlap` | 102 |
| `test_tripo_fallback_for_goal_reactions_and_no_invented_receive` | 112 |
<!-- /AUTO -->

- **Qué podría romperse:** deslizamiento tipo hielo o giros instantáneos; pelota que se escapa al trotar; patada que se aplica antes/después del gesto; jugador atravesando paredes (`test_player_collides_with_walls`).

## Calidad de la conducción y los pases (medida)

Cambios de la pasada de calidad (2026-10-26) en `BallHandler` y `AIInput`, medidos con `tests/test_gameplay_feel.gd`:

- **Giros con pelota:** antes, un giro de 90°–180° a trote o carrera perdía la pelota 1–3 s (hasta 6 m). Ahora el toque de redirección empuja la pelota hacia el rumbo nuevo, calcula el recorrido del jugador con el frenado del giro (`Locomotion` baja la velocidad objetivo a ~caminar en giros ≥ 55°), limita el error angular del toque (`touch_error_max_deg`) y hay **toque de recuperación** (`touch_escape_factor`): si la pelota va a salirse del alcance en 0.14 s se toca sin esperar al intervalo (con un mínimo del 20 % del intervalo). Resultado: giros de 60°/90°/135°/−90° — trote 0/20, carrera 0/20, sprint 1/20 intentos pierden la pelota.
- **Patada con clip:** durante el balanceo el jugador ignora la colisión de su propia cápsula con la pelota (`set_ball_ghost`), así su ajuste de zancada no la empuja antes del golpeo; el pase/tiro pulsado espera hasta 0.5 s a que algún pie llegue (`PENDING_KICK_MAX`). Pase pulsado conduciendo: parado/trote/carrera 12/12, sprint 12/12 (muestras del test).
- **Recepción:** un pase raso de 10 m a un receptor parado se controla 6/6 veces (`first_touch`).

## Limitaciones conocidas

- La IA (`AIInput`) y el cambio de jugador existen (ver [MATCH](MATCH.md)); `PlayerActions` añade barrida, caídas, levantarse y regate (`skill_pressed`, tecla U / botón REGATE) con movimiento de raíz. Límite: la IA no se ha calibrado contra humanos.
- Las señales `Footballer.tackled`/`Footballer.kicked` y `BallHandler.touched_ball` se emiten sin ningún consumidor.
- `Footballer.display_name`, `shirt_number` y `is_human_controlled` no los usa ninguna lógica o interfaz todavía.
- **Patada con clip (medido, `test_pack_dribble_metrics`):** latencia 0.20 s frente a 0.10–0.18 s de la patada procedural; a sprint el pase/tiro se ejecuta el 88 % de las pulsaciones (el resto se descarta por no haber pie que llegue). El ajuste de zancada (media 0.26–0.47 m) mueve el cuerpo sin pasos animados y es sobre todo lateral: puede verse un deslizamiento leve (solo medido, no mirado en vídeo). `soccer_penalty_kick` y `Chip` no están conectados (llevan carrera de 2.5 / 4.4 m).
- **Cadencia de toques ≠ fase del paso:** con el pack el intervalo entre toques sigue a la frecuencia de apoyos de la animación, pero no se sincroniza con el pie que pisa.
- **Sin estado de caída/falta/salto:** `fall`, `getup`, `soccer_tackle`, `soccer_trip` y los saltos del catálogo no tienen disparador (no se inventó mecánica).
- El atributo `dribbling` (regate) no se usa; no hay amagues ni regates con ventanas de ejecución (solo toques de colocación).

## Historial

Ver [CHANGELOG.md](../CHANGELOG.md): «Control asistido» (locomoción y conducción), «Esqueleto único v1.0» (patada sincronizada).
