# GOALKEEPER — Arquero (implementado)

## Identificación

- **Responsabilidad:** un arquero por equipo (`Goalkeeper`, `CharacterBody3D` en `Ball.LAYER_KEEPERS`) que se posiciona sobre el arco, anticipa los disparos con la trayectoria predicha de la pelota, **planifica la atajada con la trayectoria de manos medida de cada clip** (`KeeperPlanner`), la ejecuta con el clip y el movimiento de raíz reales y solo cuenta el contacto si las manos llegan a la pelota. Después bloquea o desvía por impulso, sostiene la pelota (`Ball.hold`) y la saca con la mano o con el pie.
- **Estado real:** operativo en el partido (`MatchScene.with_keepers`, un arquero por equipo, registrado con `MatchContext.register_keeper`). Usa los 37 clips de `pack_keeper.res` (atajadas, estiradas, bloqueos, recogida, saques, reposo, festejos propios).
- **Última verificación:** <!-- AUTO:verified -->
2026-10-26
<!-- /AUTO -->

## Cómo funciona

| Estado (`Goalkeeper.State`) | Qué hace |
|---|---|
| `POSITION` | Se mueve sobre un arco de circunferencia delante de la línea de gol mirando la pelota; sale a achicar (`base_depth`..`max_depth`) según la distancia y la amenaza; evalúa cada disparo (`_assess_shot`: velocidad ≥ `shot_min_speed`, cruza el plano del arco dentro de `plan_horizon`). |
| `PREPARE` | Reacciona (`reaction_time` + anticipación por distancia, escalada por el atributo `reflexes`). Se **planta** y replanifica desde la posición real (`_origin_after_stop`); si la amenaza desaparece (rebote, otro jugador) cancela. |
| `ACTION` | Reproduce el clip elegido por `KeeperPlanner` (espejo incluido) con `ActionMotion` (raíz) y en el instante de contacto comprueba que las manos están dentro del radio del clip (`SAVE_CLIPS`) de la pelota real: **bloquea** si la velocidad lo permite (`catch_speed_max`, `dive_catch_factor`), **desvía** (`parry_speed_max`, `deflect_damping`) o queda **superado**. |
| `HOLD` | Sostiene la pelota (`Ball.hold`) entre `hold_time_min` y `hold_time_max`. |
| `DISTRIBUTE` | Elige lanzamiento con la mano, pase rodado o patada de despeje (`goalkeeper_drop_kick`, puntera medida) según el compañero libre; la pelota sale con `Ball.release`/`Ball.kick` en el instante de la mano/pie del clip. |

Recogida de pelota suelta y lenta dentro de su área (`pickup_*`): solo con clips bajos y nunca detrás de la línea de gol; si la pelota lleva ≥ 1.2 s parada en el área con rivales encima (barullo, `SCRUM_SECONDS`) la recoge igualmente. **Lectura del disparo:** si un rival cercano a la pelota está armando una patada, la reacción empieza hasta 0.22 s antes de que salga la pelota (`KICK_READ_MAX`, escalado por reflejos). Medido con tiradores reales (80 tiros desde 8–14 m a 0.5–1.2 m del centro, `ShotAssist` y clips): 74 a puerta, 22 % goles, 36 % atajadas con las manos y 42 % bloqueos con el cuerpo/desvío. Eventos: `SAVE`, `KEEPER_CATCH`, `KEEPER_DISTRIBUTE`. `stats`, `save_log` y la señal `saved(kind)` sirven para diagnóstico y pruebas.

## Piezas

| Ruta | Qué hay | Símbolos |
|---|---|---|
| `scripts/goalkeeper/goalkeeper.gd` | Entidad, máquina de estados, contacto y saque | `Goalkeeper.setup`, `Goalkeeper._assess_shot`, `Goalkeeper._evaluate_contact`, `Goalkeeper._choose_distribution` |
| `scripts/goalkeeper/keeper_planner.gd` | Planificador puro: elige clip/instante/velocidad para que las manos lleguen a la pelota; utilidades de trayectoria (`path_world`, `path_world_at_body`, `peak_speed_time`) | `KeeperPlanner.candidates`, `KeeperPlanner.plan_save`, `KeeperPlanner.hands_world` |
| `scripts/goalkeeper/keeper_tuning.gd` | Parámetros (ver tabla) | `KeeperTuning` |
| `scripts/ball/ball_predictor.gd` | Trayectoria predicha (gravedad, arrastre, rebote, rodadura), calibrada contra la física real | `BallPredictor.trajectory`, `BallPredictor.crossing_x` |
| `scripts/animation/action_motion.gd` | Movimiento de raíz del clip | `ActionMotion` |
| `scripts/assistance/shot_assist.gd` | El tiro asistido ya apunta al lado opuesto del arquero real | `ShotAssist.compute` |
| `scripts/progression/player_attributes.gd` | Atributos de arquero (`reflexes`, `positioning`, `catching`, `diving`, `aerial`, `throwing`, `kicking`, `rebound_control`) que escalan reacción, alcance y saque dentro de límites | `PlayerAttributes.KEEPER_ATTRIBUTES` |

## Mapa de parámetros (`KeeperTuning`)

<!-- AUTO:params:KeeperTuning -->
| Parámetro | Defecto | Rango / tipo | Definido en | Dónde se usa (accesos reales) | Descripción |
|---|---|---|---|---|---|
| `move_speed` | `4.2` | float | `scripts/goalkeeper/keeper_tuning.gd:6` | `scripts/goalkeeper/goalkeeper.gd:183` |  (Movimiento) |
| `accel` | `14.0` | float | `scripts/goalkeeper/keeper_tuning.gd:7` | `scripts/goalkeeper/goalkeeper.gd:186`, `scripts/goalkeeper/goalkeeper.gd:261`, `scripts/goalkeeper/goalkeeper.gd:268` |  (Movimiento) |
| `base_depth` | `0.9` | float | `scripts/goalkeeper/keeper_tuning.gd:9` | `scripts/goalkeeper/goalkeeper.gd:118`, `scripts/goalkeeper/goalkeeper.gd:176` | Distancia a la linea de gol a la que se posiciona por defecto (m). (Movimiento) |
| `max_depth` | `4.2` | float | `scripts/goalkeeper/keeper_tuning.gd:11` | `scripts/goalkeeper/goalkeeper.gd:176`, `scripts/goalkeeper/goalkeeper.gd:177` | Profundidad maxima al salir a achicar (m). (Movimiento) |
| `rush_speed` | `5.6` | float | `scripts/goalkeeper/keeper_tuning.gd:12` | **sin uso** |  (Movimiento) |
| `reaction_time` | `0.14` | float | `scripts/goalkeeper/keeper_tuning.gd:16` | `scripts/goalkeeper/goalkeeper.gd:241` | Segundos de reaccion con reflejos 50. (Reaccion) |
| `anticipation_gain` | `0.05` | float | `scripts/goalkeeper/keeper_tuning.gd:18` | `scripts/goalkeeper/goalkeeper.gd:241` | Segundos adicionales por cada 10 m de distancia al disparo (el arquero lee antes los tiros lejanos). (Reaccion) |
| `shot_min_speed` | `5.5` | float | `scripts/goalkeeper/keeper_tuning.gd:20` | `scripts/goalkeeper/goalkeeper.gd:209`, `scripts/goalkeeper/goalkeeper.gd:220`, `scripts/goalkeeper/goalkeeper.gd:287` | Velocidad minima de la pelota (m/s) para considerarla un disparo. (Reaccion) |
| `prediction_horizon` | `1.6` | float | `scripts/goalkeeper/keeper_tuning.gd:21` | **sin uso** |  (Reaccion) |
| `reach` | `1.05` | float | `scripts/goalkeeper/keeper_tuning.gd:25` | **sin uso** | Alcance de las manos desde el centro del cuerpo (m). (Atajada) |
| `dive_reach` | `1.9` | float | `scripts/goalkeeper/keeper_tuning.gd:26` | **sin uso** |  (Atajada) |
| `dive_speed` | `5.8` | float | `scripts/goalkeeper/keeper_tuning.gd:27` | **sin uso** |  (Atajada) |
| `dive_duration` | `0.55` | float | `scripts/goalkeeper/keeper_tuning.gd:28` | **sin uso** |  (Atajada) |
| `recover_duration` | `0.9` | float | `scripts/goalkeeper/keeper_tuning.gd:29` | **sin uso** |  (Atajada) |
| `catch_speed_max` | `15.0` | float | `scripts/goalkeeper/keeper_tuning.gd:31` | `scripts/goalkeeper/goalkeeper.gd:377` | Velocidad maxima de la pelota (m/s) que puede blocar con seguridad con estirada 50. (Atajada) |
| `deflect_speed_min` | `9.0` | float | `scripts/goalkeeper/keeper_tuning.gd:33` | **sin uso** | Velocidad a partir de la cual solo puede desviar. (Atajada) |
| `deflect_damping` | `0.42` | float | `scripts/goalkeeper/keeper_tuning.gd:34` | `scripts/goalkeeper/goalkeeper.gd:393` |  (Atajada) |
| `hold_time_min` | `1.1` | float | `scripts/goalkeeper/keeper_tuning.gd:35` | `scripts/goalkeeper/goalkeeper.gd:430` |  (Atajada) |
| `hold_time_max` | `2.4` | float | `scripts/goalkeeper/keeper_tuning.gd:36` | `scripts/goalkeeper/goalkeeper.gd:430` |  (Atajada) |
| `throw_speed` | `12.5` | float | `scripts/goalkeeper/keeper_tuning.gd:39` | `scripts/goalkeeper/goalkeeper.gd:580` |  (Distribucion) |
| `kick_speed` | `17.0` | float | `scripts/goalkeeper/keeper_tuning.gd:40` | `scripts/goalkeeper/goalkeeper.gd:580`, `scripts/goalkeeper/goalkeeper.gd:582` |  (Distribucion) |
| `clearance_speed` | `21.0` | float | `scripts/goalkeeper/keeper_tuning.gd:41` | `scripts/goalkeeper/goalkeeper.gd:582` |  (Distribucion) |
| `plan_horizon` | `2.5` | float | `scripts/goalkeeper/keeper_tuning.gd:45` | `scripts/goalkeeper/goalkeeper.gd:223`, `scripts/goalkeeper/goalkeeper.gd:290` | Segundos hacia adelante que predice la trayectoria de la pelota para anticipar los disparos. (Estirada y contacto con clips) |
| `effort_radius` | `1.5` | float | `scripts/goalkeeper/keeper_tuning.gd:47` | `scripts/goalkeeper/goalkeeper.gd:245`, `scripts/goalkeeper/goalkeeper.gd:292` | Maxima distancia (m) entre manos y pelota prevista para intentar la atajada (mas lejos: no se lanza). (Estirada y contacto con clips) |
| `dive_catch_factor` | `0.8` | float | `scripts/goalkeeper/keeper_tuning.gd:49` | `scripts/goalkeeper/goalkeeper.gd:377` | Factor de velocidad de la pelota que vuelve imposible blocar el balon con ese tipo de clip (estirada = menos). (Estirada y contacto con clips) |
| `parry_speed_max` | `30.0` | float | `scripts/goalkeeper/keeper_tuning.gd:51` | `scripts/goalkeeper/goalkeeper.gd:388` | Velocidad maxima (m/s) de un balon que aun se puede desviar con las manos. (Estirada y contacto con clips) |
| `pickup_distance` | `5.0` | float | `scripts/goalkeeper/keeper_tuning.gd:53` | `scripts/goalkeeper/goalkeeper.gd:310` | Distancia (m) a la que sale a recoger una pelota suelta y lenta dentro de su area. (Estirada y contacto con clips) |
| `pickup_ball_speed_max` | `3.0` | float | `scripts/goalkeeper/keeper_tuning.gd:54` | `scripts/goalkeeper/goalkeeper.gd:302` |  (Estirada y contacto con clips) |
| `pickup_opponent_clearance` | `2.2` | float | `scripts/goalkeeper/keeper_tuning.gd:56` | `scripts/goalkeeper/goalkeeper.gd:316` | Distancia maxima (m) a la que un jugador rival puede estar de la pelota suelta para que salga a recogerla. (Estirada y contacto con clips) |
| `carry_height` | `1.15` | float | `scripts/goalkeeper/keeper_tuning.gd:58` | `scripts/goalkeeper/goalkeeper.gd:71`, `scripts/goalkeeper/goalkeeper.gd:431`, `scripts/goalkeeper/goalkeeper.gd:432`, `scripts/goalkeeper/goalkeeper.gd:441` (+1) | Altura del ancla (m) donde sostiene la pelota parado. (Estirada y contacto con clips) |
| `carry_forward` | `0.35` | float | `scripts/goalkeeper/keeper_tuning.gd:59` | `scripts/goalkeeper/goalkeeper.gd:431`, `scripts/goalkeeper/goalkeeper.gd:441`, `scripts/goalkeeper/goalkeeper.gd:526` |  (Estirada y contacto con clips) |
<!-- /AUTO -->

Los valores son el punto de partida de la calibración (ver «Pruebas»); `Tuning.keeper` los carga y se ajustan aquí, no en el código.

## Pruebas

- **Ejecutar:** `tools/run_tests.sh goalkeeper` (y `ai_match`, que juega partidos completos con arqueros).
- `tests/test_goalkeeper.gd`: posición sobre el arco y seguimiento; el planificador encuentra un clip cuyas manos alcanzan la pelota prevista; un tiro lento a las manos se bloquea y se saca; **el contacto es real** (si la pelota está fuera del alcance de las manos no hay atajada); tasa de atajadas según velocidad y colocación. `test_save_rate_depends_on_speed_and_placement` (12 tiros al arco por velocidad, con semilla): 9 m/s → 9 de 12 (75 %), 15 m/s → 8 de 12 (67 %), 24 m/s → 5 de 12 (42 %); un tiro más fuerte es más difícil de detener.
- **No probado:** el arquero con el esqueleto vivo (render) más allá de las pruebas del pack; sin dispositivo Android.

## Dependencias

[BALL](BALL.md) (`Ball.hold/release/kick`, predictor), [ANIMATIONS](ANIMATIONS.md) y [ANIMATION_PACK](ANIMATION_PACK.md) (clips y trayectorias de manos), [PITCH](PITCH.md) (`Goal`), [MATCH](MATCH.md) (`MatchContext.keepers`), [ASSISTANCE](ASSISTANCE.md), [PROGRESSION](PROGRESSION.md).

## Historial

Ver [CHANGELOG.md](../CHANGELOG.md): «Arquero, IA de equipos y acciones».
