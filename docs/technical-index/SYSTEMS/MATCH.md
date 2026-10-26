# MATCH — Reglas y flujo del partido, contexto y composición de la escena

## Identificación

- **Responsabilidad exacta:**
  - `MatchManager`: máquina de estados del partido (saque → juego → gol → saque…, pausa, fin de tiempo), marcador, reloj, goles en contra y asistencias. **No crea ni mueve entidades**: pide la reposición con la señal `kickoff_requested`.
  - `MatchContext`: vista compartida (pelota, cancha, cámara, futbolistas, `tick`, `match_time`, `input_enabled`) y bus de eventos. **No contiene reglas.**
  - `MatchScene`: raíz de composición. Crea cancha, pelota, cámara, equipos, `MatchManager`, `Hud`, y reposiciona en cada saque.
- **Estado:** implementado y probado: **4 contra 4 con arquero** por equipo (`home_field_players = away_field_players = 4`, `with_keepers`), un humano local (el compañero más cercano a la pelota se controla con el cambio de jugador, `auto_switch`) y el resto con `AIInput`; árbitro y presentación previa (`intro_seconds`, `with_referee`). Las pruebas de flujo desactivan arqueros, árbitro y presentación para aislar el reloj.
- **Última verificación:** <!-- AUTO:verified -->
2026-10-26
<!-- /AUTO -->

## Archivos responsables

| Ruta | Función | Símbolos relevantes | Dependencias directas |
|---|---|---|---|
| `scripts/gameplay/match_manager.gd` | Estados, marcador, reloj, saque, gol (`_on_goal`), pausa | `MatchManager.State`, `MatchManager._on_goal`, `MatchManager._begin_kickoff`, `MatchManager.toggle_pause`, `MatchManager.restart_play`, `MatchManager.restart_match` | `MatchContext`, `Pitch.goal_scored`, `Ball.touched`, `GameEvent` |
| `scripts/gameplay/match_context.gd` | Contexto compartido | `MatchContext.emit_event`, `MatchContext.attacking_goal`, `MatchContext.teammates_of`, `MatchContext.screen_to_world`, `MatchContext.keeper_defending` | `Ball`, `Pitch`, `MatchCamera`, `Footballer` |
| `scripts/gameplay/match_scene.gd` | Composición y formación de saque | `MatchScene._ready`, `MatchScene._spawn_teams`, `MatchScene.kickoff_positions`, `MatchScene._on_kickoff_requested` | todo lo anterior + `Hud`, `HumanInput`, `PlayerAttributes` |
| `scenes/main/match.tscn` | Escena principal (`run/main_scene`): un `Node3D` con `match_scene.gd`; todo lo demás se crea por código | nodo `Match` | `MatchScene` |

**No modificar para cambiar el balance de juego:** `match_manager.gd` no tiene física; el gol lo decide `Goal` (ver [PITCH](PITCH.md)).

## Mapa de parámetros

<!-- AUTO:params:MatchManager -->
| Parámetro | Defecto | Rango / tipo | Definido en | Dónde se usa (accesos reales) | Descripción |
|---|---|---|---|---|---|
| `duration_seconds` | `300.0` | float | `scripts/gameplay/match_manager.gd:18` | `scripts/gameplay/match_manager.gd:98`, `scripts/gameplay/match_scene.gd:62` | Duracion en segundos (0 = sin limite, util en el laboratorio). |
| `goal_celebration_seconds` | `3.0` | float | `scripts/gameplay/match_manager.gd:19` | `scripts/gameplay/match_manager.gd:138`, `scripts/gameplay/match_manager.gd:142` |  |
| `pre_kickoff_seconds` | `1.2` | float | `scripts/gameplay/match_manager.gd:20` | `scripts/gameplay/match_manager.gd:79` |  |
| `intro_seconds` | `0.0` | float | `scripts/gameplay/match_manager.gd:22` | `scripts/gameplay/match_manager.gd:78`, `scripts/gameplay/match_manager.gd:79`, `scripts/gameplay/match_scene.gd:63` | Presentacion antes del primer saque (calentamiento y arbitro). 0 = sin presentacion. |
| `assist_window_seconds` | `6.0` | float | `scripts/gameplay/match_manager.gd:24` | `scripts/gameplay/match_manager.gd:133` | Ventana para considerar asistencia el pase previo al gol. |
| `ctx` | `—` | MatchContext | `scripts/gameplay/match_manager.gd:26` | `scripts/gameplay/match_manager.gd:36`, `scripts/gameplay/match_manager.gd:37`, `scripts/gameplay/match_manager.gd:38`, `scripts/gameplay/match_manager.gd:43` (+18) |  |
| `state` | `State.PRE_KICKOFF` | State | `scripts/gameplay/match_manager.gd:27` | `scripts/ui/hud.gd:187`, `scripts/gameplay/match_manager.gd:53`, `scripts/gameplay/match_manager.gd:63`, `scripts/gameplay/match_manager.gd:66` (+6) |  |
| `score` | `[0, 0]` | Array[int] | `scripts/gameplay/match_manager.gd:28` | `scripts/ui/hud.gd:63`, `scripts/gameplay/match_manager.gd:42`, `scripts/gameplay/match_manager.gd:101`, `scripts/gameplay/match_manager.gd:102` (+3) |  |
| `kickoff_team` | `0` | int | `scripts/gameplay/match_manager.gd:29` | `scripts/gameplay/match_manager.gd:45`, `scripts/gameplay/match_manager.gd:55`, `scripts/gameplay/match_manager.gd:75` |  |
| `_state_timer` | `0.0` | float | `scripts/gameplay/match_manager.gd:31` | `scripts/gameplay/match_manager.gd:79`, `scripts/gameplay/match_manager.gd:82`, `scripts/gameplay/match_manager.gd:83`, `scripts/gameplay/match_manager.gd:91` (+4) |  |
| `_state_before_pause` | `State.PLAYING` | State | `scripts/gameplay/match_manager.gd:32` | `scripts/gameplay/match_manager.gd:54`, `scripts/gameplay/match_manager.gd:65`, `scripts/gameplay/match_manager.gd:67` |  |
| `_last_touch_time_by_actor` | `{}` | Dictionary | `scripts/gameplay/match_manager.gd:33` | `scripts/gameplay/match_manager.gd:115`, `scripts/gameplay/match_manager.gd:133` |  |
| `_last_scoring_team` | `0` | int | `scripts/gameplay/match_manager.gd:110` | `scripts/gameplay/match_manager.gd:106`, `scripts/gameplay/match_manager.gd:136` |  |
<!-- /AUTO -->

<!-- AUTO:params:MatchScene -->
| Parámetro | Defecto | Rango / tipo | Definido en | Dónde se usa (accesos reales) | Descripción |
|---|---|---|---|---|---|
| `duration_seconds` | `300.0` | float | `scripts/gameplay/match_scene.gd:8` | `scripts/gameplay/match_scene.gd:62` |  |
| `home_field_players` | `4` | int | `scripts/gameplay/match_scene.gd:10` | `scripts/gameplay/match_scene.gd:85` | Cantidad de futbolistas de campo por equipo en esta etapa (1 = etapa inicial). |
| `away_field_players` | `4` | int | `scripts/gameplay/match_scene.gd:11` | `scripts/gameplay/match_scene.gd:92` |  |
| `auto_switch` | `true` | bool | `scripts/gameplay/match_scene.gd:13` | `scripts/gameplay/match_scene.gd:174` | Cambia solo al jugador del humano mas cercano a la pelota cuando el actual queda lejos. |
| `ai_skill` | `0.6` | float | `scripts/gameplay/match_scene.gd:15` | `scripts/gameplay/match_scene.gd:87`, `scripts/gameplay/match_scene.gd:94`, `scripts/gameplay/match_scene.gd:211` | Calidad de decision de la IA (0..1). |
| `intro_seconds` | `4.5` | float | `scripts/gameplay/match_scene.gd:17` | `scripts/gameplay/match_scene.gd:63` | Presentacion antes del primer saque (s): calentamiento de los jugadores y arbitro contando. 0 = sin presentacion. |
| `with_referee` | `true` | bool | `scripts/gameplay/match_scene.gd:18` | `scripts/gameplay/match_scene.gd:55` |  |
| `referee` | `null` | Referee | `scripts/gameplay/match_scene.gd:19` | `scripts/gameplay/match_scene.gd:56`, `scripts/gameplay/match_scene.gd:57`, `scripts/gameplay/match_scene.gd:58`, `scripts/gameplay/match_scene.gd:59` |  |
| `ctx` | `—` | MatchContext | `scripts/gameplay/match_scene.gd:21` | `scripts/gameplay/match_scene.gd:38`, `scripts/gameplay/match_scene.gd:47`, `scripts/gameplay/match_scene.gd:48`, `scripts/gameplay/match_scene.gd:53` (+5) |  |
| `pitch` | `—` | Pitch | `scripts/gameplay/match_scene.gd:22` | `scripts/gameplay/match_scene.gd:39`, `scripts/gameplay/match_scene.gd:40`, `scripts/gameplay/match_scene.gd:41`, `scripts/gameplay/match_scene.gd:42` (+2) |  |
| `ball` | `—` | Ball | `scripts/gameplay/match_scene.gd:23` | `scripts/gameplay/match_scene.gd:34`, `scripts/gameplay/match_scene.gd:43`, `scripts/gameplay/match_scene.gd:44`, `scripts/gameplay/match_scene.gd:45` (+8) |  |
| `camera` | `—` | MatchCamera | `scripts/gameplay/match_scene.gd:24` | `scripts/gameplay/match_scene.gd:50`, `scripts/gameplay/match_scene.gd:51`, `scripts/gameplay/match_scene.gd:52`, `scripts/gameplay/match_scene.gd:53` (+5) |  |
| `manager` | `—` | MatchManager | `scripts/gameplay/match_scene.gd:25` | `scripts/gameplay/match_scene.gd:60`, `scripts/gameplay/match_scene.gd:61`, `scripts/gameplay/match_scene.gd:62`, `scripts/gameplay/match_scene.gd:63` (+7) |  |
| `hud` | `—` | Hud | `scripts/gameplay/match_scene.gd:26` | `scripts/gameplay/match_scene.gd:67`, `scripts/gameplay/match_scene.gd:68`, `scripts/gameplay/match_scene.gd:69`, `scripts/gameplay/match_scene.gd:70` (+7) |  |
| `controlled` | `null` | Footballer | `scripts/gameplay/match_scene.gd:27` | `scripts/gameplay/match_scene.gd:76`, `scripts/gameplay/match_scene.gd:100`, `scripts/gameplay/match_scene.gd:101`, `scripts/gameplay/match_scene.gd:160` (+14) |  |
| `home` | `[]` | Array[Footballer] | `scripts/gameplay/match_scene.gd:28` | `scripts/gameplay/match_scene.gd:90`, `scripts/gameplay/match_scene.gd:99`, `scripts/gameplay/match_scene.gd:100`, `scripts/gameplay/match_scene.gd:150` (+5) |  |
| `away` | `[]` | Array[Footballer] | `scripts/gameplay/match_scene.gd:29` | `scripts/gameplay/match_scene.gd:97`, `scripts/gameplay/match_scene.gd:150` |  |
| `keepers` | `[]` | Array[Goalkeeper] | `scripts/gameplay/match_scene.gd:30` | `scripts/gameplay/match_scene.gd:111` |  |
| `with_keepers` | `true` | bool | `scripts/gameplay/match_scene.gd:32` | `scripts/gameplay/match_scene.gd:102` | Con false no se crean arqueros (algunas pruebas y la practica los omiten). |
| `_switch_cooldown` | `0.0` | float | `scripts/gameplay/match_scene.gd:164` | `scripts/gameplay/match_scene.gd:169`, `scripts/gameplay/match_scene.gd:174`, `scripts/gameplay/match_scene.gd:216` |  |
<!-- /AUTO -->

`MatchScene.duration_seconds` (300) se copia a `MatchManager.duration_seconds` en `_ready`; **el valor efectivo es el de la escena**. `0` = sin límite (lo usan las pruebas).

### Riesgos al modificar

| Elemento | Efecto real y riesgo |
|---|---|
| `duration_seconds` | `test_pause_and_full_time` usa 3 s y espera `FULL_TIME` a los 3.5 s. |
| `goal_celebration_seconds` (3), `pre_kickoff_seconds` (1.2) | Tiempo con `input_enabled = false`. |
| `assist_window_seconds` (6) | Un pase solo cuenta como asistencia si el pasador tocó la pelota hace ≤ 6 s (`_last_touch_time_by_actor`). |
| `home_field_players` / `away_field_players` | 4 por defecto. Los jugadores que no controla el humano usan `AIInput` (roles cierre/alas/pivote); con `InputSource` vacío se quedarían quietos. Las pruebas de flujo los ponen a 1/0 y desactivan arqueros, árbitro y presentación. |
| `MatchScene.kickoff_positions` | Formación de saque de 4 jugadores por equipo (cierre, alas, pivote); los arqueros van a su arco. |
| Orden de señales `goal_scored` → `score_changed` → mensaje → evento `GOAL` | `Hud` se suscribe a `score_changed`, `clock_changed`, `message`, `state_changed`. |

## Mapa de funciones

<!-- AUTO:funcs:scripts/gameplay/match_manager.gd -->
| Función | Línea | Qué hace |
|---|---|---|
| `MatchManager.setup(context: MatchContext)` | 35 |  |
| `MatchManager.start_match()` | 41 |  |
| `MatchManager.restart_play()` | 52 | Reinicia la jugada actual (sin tocar el marcador): saque de centro del mismo equipo. |
| `MatchManager.restart_match()` | 58 |  |
| `MatchManager.toggle_pause()` | 62 |  |
| `MatchManager.is_playing()` | 71 |  |
| `MatchManager._begin_kickoff(team: int, intro: bool = false)` | 74 |  |
| `MatchManager._physics_process(delta: float)` | 85 |  |
| `MatchManager._on_ball_touched(actor: Node)` | 112 |  |
| `MatchManager._on_goal(goal: Goal, _ball_pos: Vector3)` | 117 |  |
| `MatchManager._set_state(s: State)` | 146 |  |
| `MatchManager.format_clock(seconds: float)` | 150 |  |
<!-- /AUTO -->

<!-- AUTO:signals:scripts/gameplay/match_manager.gd -->
| Señal | Línea | Descripción |
|---|---|---|
| `MatchManager.state_changed(new_state: int)` | 8 | Reglas y flujo del partido: saque, juego, gol (la pelota cruza COMPLETAMENTE la linea), celebracion, reinicio de jugada / partido, pausa y fin de tiempo. No crea ni mueve entidades por si mismo: pide a la escena que las reposicione mediante la senal kickoff_requested. Pensado para que un servidor autoritativo pueda ejecutar este mismo codigo. |
| `MatchManager.score_changed(home: int, away: int)` | 9 |  |
| `MatchManager.goal_scored(team: int, scorer_id: int, assist_id: int, own_goal: bool)` | 10 |  |
| `MatchManager.kickoff_requested(kicking_team: int)` | 11 |  |
| `MatchManager.message(text: String, seconds: float)` | 12 |  |
| `MatchManager.clock_changed(seconds: float)` | 13 |  |
<!-- /AUTO -->

<!-- AUTO:funcs:scripts/gameplay/match_scene.gd -->
| Función | Línea | Qué hace |
|---|---|---|
| `MatchScene._ready()` | 37 |  |
| `MatchScene._spawn_teams()` | 83 |  |
| `MatchScene._seed_ai(f: Footballer, id: int)` | 113 |  |
| `MatchScene._make_footballer(team: int, id: int, source: InputSource)` | 117 |  |
| `MatchScene._on_quit_requested()` | 127 | Con el partido como escena actual, «Salir» cierra el juego; si lo aloja otro nodo (pruebas) solo avisa. |
| `MatchScene._on_practice_requested()` | 133 | Abre la sala de practica (galeria de animaciones y malabares) y vuelve aqui con «Volver». |
| `MatchScene.kickoff_positions(team: int)` | 139 | Formacion de saque. Hoy: un jugador por equipo; preparado para 4 + arquero por equipo. |
| `MatchScene._on_kickoff_requested(_kicking_team: int)` | 148 |  |
| `MatchScene._charge_state()` | 159 |  |
| `MatchScene._physics_process(delta: float)` | 166 |  |
| `MatchScene.switch_to_nearest_to_ball()` | 178 | Pasa el control humano al companero mas cercano a la pelota (distinto del actual). |
| `MatchScene._auto_switch()` | 191 |  |
| `MatchScene._give_control(target: Footballer)` | 207 |  |
<!-- /AUTO -->

<!-- AUTO:funcs:scripts/gameplay/match_context.gd -->
| Función | Línea | Qué hace |
|---|---|---|
| `MatchContext.emit_event(e: GameEvent)` | 19 |  |
| `MatchContext.register_footballer(f: Footballer)` | 24 |  |
| `MatchContext.unregister_footballer(f: Footballer)` | 28 |  |
| `MatchContext.teammates_of(p: Footballer)` | 31 |  |
| `MatchContext.opponents_of(p: Footballer)` | 38 |  |
| `MatchContext.opponents_of_team(team: int)` | 45 |  |
| `MatchContext.attacking_goal(team: int)` | 53 | Arco que ataca un equipo: el equipo 0 ataca +X. |
| `MatchContext.defending_goal(team: int)` | 56 |  |
| `MatchContext.register_keeper(k: Node)` | 59 |  |
| `MatchContext.unregister_keeper(k: Node)` | 63 |  |
| `MatchContext.keeper_defending(team: int)` | 66 |  |
| `MatchContext.nearest_footballer(pos: Vector3, team: int = -1, exclude: Footballer = null)` | 73 | Jugador (no arquero) del equipo dado mas cercano a un punto. |
| `MatchContext.screen_to_world(v: Vector2)` | 86 | Convierte un vector 2D de pantalla en direccion de mundo usando la camara si existe. |
<!-- /AUTO -->

## Recorrido de ejecución

**Arranque** (`MatchScene._ready`): `Pitch.build(Tuning.pitch)` → `Ball` en `(0, 0.2, 0)` → `MatchCamera` → equipos (`_spawn_teams`: atributos neutros `PlayerAttributes.reset_to(55)`, el primero de casa con `HumanInput`) → `MatchManager.setup(ctx)` (conecta `Pitch.goal_scored` y `Ball.touched`) → `Hud` (`bind`) → `camera.setup` → `GraphicsSettings.apply()` → `manager.start_match()`.

**Saque:** `_begin_kickoff(team)`: `input_enabled = false`, `Pitch.reset_goal_latches()`, estado `PRE_KICKOFF` durante `pre_kickoff_seconds`, señal `kickoff_requested` → `MatchScene._on_kickoff_requested`: `ball.reset_at((0, 0.11, 0))`, `place_at` de cada futbolista (equipo 0 mira a +X), `camera.snap_to_target()`. Al acabar el temporizador: `input_enabled = true`, estado `PLAYING`. El equipo que saca se registra en `kickoff_team` y en el evento, pero **las posiciones no dependen de quién saca**.

**Gol** (`_on_goal`, solo en `PLAYING`): el equipo anotador es el que ataca ese arco (arco `+X` → equipo 0). Gol en contra si el último toque fue de un equipo distinto del anotador. Asistencia: `previous_toucher` del equipo anotador, distinto del goleador y dentro de la ventana. Sube el marcador, `input_enabled = false`, estado `GOAL` durante `goal_celebration_seconds`, mensaje «¡GOL!», evento `GOAL`, y el siguiente saque lo hace el equipo que recibió el gol (`1 − _last_scoring_team`).

**Fin:** al llegar `match_time ≥ duration_seconds` (si > 0): estado `FULL_TIME`, `input_enabled = false`, mensaje con el marcador 6 s, evento `MATCH_END`.

**Pausa:** `toggle_pause` (tecla Esc, botón táctil «II», o `Hud`): `get_tree().paused`, estado `PAUSED`; restaura el estado anterior al reanudar. `MatchManager` es `PROCESS_MODE_PAUSABLE`; `Hud` y `TouchControls` son `ALWAYS`.

## Pruebas

- **Ejecutar:** `tools/run_tests.sh match_flow`.
- **Última ejecución (2026-10-26):** 6 pruebas / 28 comprobaciones sin fallos (suite completa: 57 / 212).

<!-- AUTO:tests:tests/test_match_flow.gd -->
| Prueba | Línea |
|---|---|
| `test_match_starts_with_kickoff_then_plays` | 17 |
| `test_goal_updates_score_stats_and_restarts_kickoff` | 28 |
| `test_ball_on_the_line_without_crossing_is_no_goal` | 58 |
| `test_own_goal_is_credited_to_the_opponent` | 67 |
| `test_restart_play_keeps_score_and_restart_match_resets_it` | 80 |
| `test_pause_and_full_time` | 98 |
| `test_full_scene_has_a_keeper_per_team_and_a_goal_still_counts_when_the_keeper_is_beaten` | 112 |
<!-- /AUTO -->

- **Qué podría romperse:** gol que se cuenta dos veces (se controla con `Pitch.reset_goal_latches` y el estado `PLAYING`), gol en contra mal atribuido, reloj que avanza en pausa, jugadores que no vuelven a su sitio tras un gol.

## Limitaciones conocidas

- **«Salir» no hace nada:** `Hud.quit_requested` → `MatchScene.quit_requested`, pero **nadie conecta esa señal** ni llama a `get_tree().quit()`. En un móvil no hay salida desde el menú.
- **Tras `FULL_TIME` no hay salida de la pantalla:** `toggle_pause` ignora el estado `FULL_TIME` (no se puede abrir el menú de pausa para «Reiniciar partido») y no existe pantalla de resultado. Verificado leyendo el código; la prueba `test_pause_and_full_time` solo comprueba que el partido termina y la entrada se bloquea.
- Sin reglas de saque de banda, córner, tiro libre, falta, tarjetas ni sustituciones: la pelota rebota en las paredes (ver [PITCH](PITCH.md)).
- La IA (`AIInput`) es simple: decide cada 0.12 s con reglas (tiro solo con ángulo de arco ≥ 16° y sin rival a menos de 0.95 m de la pelota, pase por presión o a un compañero libre, barullo resuelto tras 0.9 s despejando, un único portador por equipo) y no se ha calibrado contra jugadores humanos. Medido con 3 partidos de 120 s: la pelota nunca queda quieta más de ~2 s en juego y ~29 % de sus patadas se pierden por un toque rival o de un compañero (`test_ai_match`). Sin estadísticas por jugador: los eventos se emiten pero nadie los agrega.
- `MatchContext.keepers` nunca se rellena (no hay arquero; ver [GOALKEEPER](GOALKEEPER.md)).

## Historial

Ver [CHANGELOG.md](../CHANGELOG.md): «Partido jugable».
