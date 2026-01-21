extends CharacterBody2D

# ------------------ ZMIENNE ------------------

# rozmiary ekranu i paletki
var win_height: float
var p_height: float
var start_x: float   # stała pozycja X paletki CPU

# parametry AI (zmieniane przez poziom trudności)
@export var cpu_speed := 350.0        # prędkość CPU
@export var reaction_delay := 1.0     # opóźnienie reakcji
@export var dead_zone := 18.0         # strefa bez ruchu
@export var error_range := 20.0       # losowy błąd celu

var delay_timer := 0.0
var can_move := false
var target_y := 0.0


# ------------------ START ------------------

# Inicjalizacja parametrów CPU
func _ready() -> void:
	randomize()
	win_height = get_viewport_rect().size.y
	p_height = $ColorRect.size.y
	target_y = position.y
	start_x = position.x


#RUCH CPU 

# Logika ruchu paletki CPU
func _physics_process(delta: float) -> void:
	# blokada osi X
	position.x = start_x

	if get_parent().game_over:
		velocity = Vector2.ZERO
		return

	var ball = $"../Ball"

	# brak reakcji gdy piłka oddala się od CPU
	if ball.dir.x < 0:
		can_move = false
		delay_timer = reaction_delay
		velocity = Vector2.ZERO
		return

	# opóźnienie reakcji CPU
	if not can_move:
		delay_timer -= delta
		if delay_timer <= 0.0:
			can_move = true
		else:
			velocity = Vector2.ZERO
			return

	# wyznaczenie celu ruchu
	target_y = ball.position.y + randf_range(-error_range, error_range)

	var diff = target_y - position.y
	if abs(diff) < dead_zone:
		velocity = Vector2.ZERO
		return

	# ruch paletki w pionie
	var vy = clamp(diff, -1.0, 1.0) * cpu_speed
	velocity = Vector2(0.0, vy)
	move_and_slide()

	# ograniczenie ruchu do obszaru ekranu
	position.y = clamp(position.y, p_height / 2.0, win_height - p_height / 2.0)

	# korekta X po kolizjach
	position.x = start_x


	# -------------Trudnośc-----------

	# Ustawia poziom trudności CPU
	# 0 Easy, 1 Normal, 2 Hard, 3 TURBO KOZAK
func set_difficulty(level: int) -> void:
	match level:
		0: # EASY
			cpu_speed = 260.0
			reaction_delay = 0.25
			error_range = 45.0
			dead_zone = 26.0

		1: # NORMAL
			cpu_speed = 350.0
			reaction_delay = 0.15
			error_range = 25.0
			dead_zone = 18.0

		2: # HARD
			cpu_speed = 470.0
			reaction_delay = 0.05
			error_range = 10.0
			dead_zone = 10.0
			
			
		3: # TURBO KOZAK
			cpu_speed = 670.0
			reaction_delay = 0.04
			error_range = 4.0
			dead_zone = 6.0
