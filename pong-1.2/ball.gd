extends CharacterBody2D
# Skrypt odpowiada za ruch, odbicia i dźwięk piłki w grze Pong.

var win_size : Vector2   # rozmiar okna gry

const START_SPEED : int = 500        # prędkość początkowa piłki
const MAX_Y_VECTOR : float = 0.8     # maksymalny kąt odbicia w pionie
const SERVE_OFFSET_X : float = 60.0  # przesunięcie piłki przy serwisie
const PUSH_OUT : float = 6.0         # odsunięcie po kolizji

var speed : int                      # aktualna prędkość piłki
var dir : Vector2 = Vector2.ZERO     # kierunek lotu piłki

# -1 = Player serwuje, 1 = CPU serwuje
var server : int = -1

# zabezpieczenie przed wielokrotnym odbiciem w jednej klatce
var bounce_cd := 0.0

# dźwięk odbicia piłki
@onready var hit_sound: AudioStreamPlayer2D = $HitSound


# Inicjalizacja piłki po uruchomieniu gry
func _ready() -> void:
	randomize()
	win_size = get_viewport_rect().size


# Zatrzymuje piłkę (np. po zdobyciu punktu)
func stop_ball() -> void:
	velocity = Vector2.ZERO
	dir = Vector2.ZERO


# Ustawia nowy serwis piłki po rozpoczęciu rundy
func new_ball() -> void:
	if get_parent().game_over:
		return

	speed = START_SPEED
	bounce_cd = 0.0

	var player_paddle = $"../Player"
	var cpu_paddle = $"../CPU"

	var server_paddle = player_paddle if server == -1 else cpu_paddle
	var other_paddle  = cpu_paddle if server == -1 else player_paddle

	position.y = randf_range(200.0, win_size.y - 200.0)

	var x_dir: int = 1 if other_paddle.position.x > server_paddle.position.x else -1
	position.x = server_paddle.position.x + x_dir * SERVE_OFFSET_X

	dir = Vector2(x_dir, randf_range(-MAX_Y_VECTOR, MAX_Y_VECTOR)).normalized()
	velocity = Vector2.ZERO


# Główna logika ruchu i kolizji piłki
func _physics_process(delta: float) -> void:
	if get_parent().game_over:
		velocity = Vector2.ZERO
		return

	if bounce_cd > 0.0:
		bounce_cd -= delta

	velocity = dir * speed
	move_and_slide()

	# Obsługa odbić od ścian i paletek
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var n = col.get_normal()
		var c = col.get_collider()

		if abs(n.y) > 0.5 and bounce_cd <= 0.0:
			dir.y *= -1.0
			position.y += dir.y * PUSH_OUT
			bounce_cd = 0.05
			hit_sound.play()

		if c and (c.name == "Player" or c.name == "CPU"):
			if bounce_cd <= 0.0:
				bounce(c.position.y)
				bounce_cd = 0.05
				hit_sound.play()

		break


# Oblicza odbicie piłki od paletki

func bounce(paddle_y: float) -> void:
	# odbicie w poziomie
	dir.x *= -1.0
	position.x += dir.x * PUSH_OUT

	# odległość od środka paletki
	var dist = position.y - paddle_y

	# SKALA KĄTA (im mniejsza liczba, tym ostrzejsze kąty)
	var angle_strength := 90.0

	# wyliczenie kąta w pionie
	dir.y = dist / angle_strength

	# ograniczenie maksymalnego kąta
	dir.y = clamp(dir.y, -MAX_Y_VECTOR, MAX_Y_VECTOR)

	# normalizacja wektora
	dir = dir.normalized()

	#  przyspieszenie z odbiciem
	speed += 70
