extends Node2D

#----Resources----
var rect : Texture2D = load("res://rect.png")

var new_player : Player
var enemy : Enemy
var enemy_spawner : EnemySpawner

var label : Label
var waves : Label

var original_values = {}
var wave_count = 0

@export var enemies : float = 0

func _ready():
	new_player = Player.new()
	new_player.position = Vector2(512,333)
	add_child(new_player)
	
	enemy_spawner = EnemySpawner.new()
	enemy_spawner.player = new_player
	add_child(enemy_spawner)
	
	label_rdy()
	wave_rdy()
	
	label.text = 'Press "Space" to Start'
	
	original_values = {
		"ply_speed": new_player.ply_speed,
		"ply_health": new_player.ply_health,
		"ply_shoot_cooldown": new_player.ply_shoot_cooldown
	}

func wave_rdy():
	waves = Label.new()
	
	waves.position =  Vector2(10,10)
	
	add_child(waves)

func label_rdy():
	label = Label.new()
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(500,512)
	
	add_child(label)

func _process(_delta):
	
	waves.text = 'Waves: ' + str(enemy_spawner.wave)
	
	if enemy_spawner.wave > 0:
		if !enemy_spawner.is_wave:
			enemy_spawner.is_wave = true
			generate_powerup()
			
			enemy_spawner.wait_time *= 0.9
			print('Cooldown:',enemy_spawner.wait_time)
			
			if enemy_spawner.wave >= 1:
				label.text = 'Press "Space" for the next wave'
			
	if Input.is_action_pressed("start"):
		label.text = ' '

func generate_powerup():
	var power_up_type = randi() % 3
	match power_up_type:
		0:
			new_player.ply_speed *= 1.5
			print("Power-up: aumento de velocidad = " , new_player.ply_speed)
		1:
			new_player.ply_health += 10
			print("Power-up: Aumento de salud = " , new_player.ply_health)
		2:
			new_player.ply_shoot_cooldown *= 0.5
			print("Power-up: Reduccion de cooldown = " , new_player.ply_shoot_cooldown)

	wave_count += 1
	if wave_count >= 2:
		reset_player_values()
		wave_count = 0

func reset_player_values():
	new_player.ply_speed = original_values["ply_speed"]
	new_player.ply_health = original_values["ply_health"]
	new_player.ply_shoot_cooldown = original_values["ply_shoot_cooldown"]

#----Player----
class Player extends CharacterBody2D:
	
	var rect : Texture2D = load("res://rect.png")
	
	var ply_sprite : Sprite2D
	var ply_col : CollisionShape2D
	var ply_timer : Timer
	
	var ply_speed : float = 400
	var ply_health: float = 30
	var ply_shoot_cooldown : float = 0.5
	
	var can_shoot : bool = true
	
	func _ready():
		name = "Player"
		
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		
		ply_sprite = Sprite2D.new()
		ply_col = CollisionShape2D.new()
		ply_timer = Timer.new()
		
		
		add_child(ply_sprite)
		add_child(ply_col)
		add_child(ply_timer)
		
		#----PlyColision----
		ply_col.shape = RectangleShape2D.new()
		ply_col.shape.size = Vector2(40,40)
		
		#----PlySprite----
		ply_sprite.texture = rect
		
		#----PlyTimer----
		ply_timer.wait_time = ply_shoot_cooldown
		ply_timer.one_shot = true
		ply_timer.timeout.connect(time_out)
	
	
	func _physics_process(_delta):
		var input_vector = Input.get_vector("left","right","up","down")
		velocity = input_vector*ply_speed
		
		if can_shoot:
			if Input.is_action_pressed("shoot"):
				shoot()
				can_shoot = false
				ply_timer.start()
		
		move_and_slide()
	
	func shoot():
		var new_bullet = Bullet.new()
		new_bullet.global_position = position
		
		var mouse_pos = get_global_mouse_position()
		var direction = (mouse_pos - global_position).normalized()
		new_bullet.direction = direction
		
		
		get_parent().add_child(new_bullet)
	
	func take_damage(damage: float):
		ply_health -= damage
		if ply_health <= 0:
			get_tree().reload_current_scene()
			
	func time_out():
		can_shoot = true

#----Bullet----
class Bullet extends Area2D:
	
	var rect : Texture2D = load("res://rect.png")
	
	var blt_sprite : Sprite2D
	var blt_col : CollisionShape2D
	
	@export var blt_speed: float = 500
	@export var blt_range: float = 1200
	@export var blt_damage: float = 10
	
	var blt_travelled_distance = 0
	
	var direction : Vector2
	
	func _ready():
		name = "Bullet"
		
		blt_sprite = Sprite2D.new()
		blt_col = CollisionShape2D.new()
		
		add_child(blt_sprite)
		add_child(blt_col)
		
		#----BltColision----
		blt_col.shape = RectangleShape2D.new()
		blt_col.shape.size = Vector2(10,10)
		
		#---BltSprite----
		blt_sprite.texture = rect
		blt_sprite.scale = Vector2(0.25,0.25)
		
		body_entered.connect(is_body_enter)
		

	func _physics_process(_delta):
		position += direction * blt_speed * _delta
		
		blt_travelled_distance += blt_speed * _delta
	
		if blt_travelled_distance > blt_range:
			queue_free()
	
	func is_body_enter(body):
		if body is Enemy:
			body.take_damage(blt_damage)
			queue_free()

#----Enemy----
class Enemy extends CharacterBody2D:
	
	var rect : Texture2D = load("res://rect.png")
	
	var eny_sprite : Sprite2D
	var eny_col : CollisionShape2D
	var eny_area2d : Area2D
	
	var eny_speed : float = 200
	var eny_health : float = 10
	var eny_damage : float = 10
	
	var direction : Vector2
	
	var player: Player
	
	
	func _ready():
		name = "Enemy"
		
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
		
		eny_sprite = Sprite2D.new()
		eny_col = CollisionShape2D.new()
		eny_area2d = Area2D.new()
		var area_col = CollisionShape2D.new()
		
		add_child(eny_sprite)
		add_child(eny_col)
		add_child(eny_area2d)
		
		#----Colision----
		eny_col.shape = RectangleShape2D.new()
		eny_col.shape.size = Vector2(40,40)
		
		#----Sprite----
		eny_sprite.texture = rect
		eny_sprite.self_modulate = Color(1,0,0)
		
		#----Area2D----
		eny_area2d.add_child(area_col)
		area_col.shape = RectangleShape2D.new()
		area_col.shape.size = Vector2(60,60)
		area_col.debug_color = Color(1,1,1,0.107)
		eny_area2d.body_entered.connect(is_body_enter)
		
	
	func set_player(player_inst):
		player = player_inst
	
	func _physics_process(_delta):
		direction = (player.global_position - global_position).normalized()
		
		velocity = direction * eny_speed
		move_and_collide(velocity * _delta)
	
	func take_damage(damage: float):
		eny_health -= damage
		if eny_health <= 0:
			queue_free()
	
	func is_body_enter(body):
		if body is Player:
			body.take_damage(eny_damage)
			queue_free()
			print(name + ": Player detected")

#----EnemySpawner----
class EnemySpawner extends Node2D:
	
	var timer : Timer
	var eny : Enemy
	var player : CharacterBody2D
	
	var wait_time : float = 1.5
	var max_enemies : float = 10
	var enemies : float = 0
	
	var wave = 0
	
	var is_wave : bool = false
	
	func _ready():
		timer = Timer.new()
		
		add_child(timer)
		
		#----Timer----
		timer.one_shot = true
		timer.timeout.connect(time_out)
		
	
	func _physics_process(_delta):
		if Input.is_action_just_released("start"):
			start_wave()
		
		timer.wait_time =  wait_time
		
		if enemies == max_enemies:
			stop_wave()
	
	func start_wave():
		timer.start()
		add_enemy()
		is_wave = true
		
		wave += 1
	
	func stop_wave():
		timer.stop()
		enemies = 0
		max_enemies += 5
		is_wave = false
		
		if wave % 5 == 0:
			reduce_enemy_spawn_cooldown()
			print("El cooldown de generacion de enemigos a disminuido : ", wait_time)

	func reduce_enemy_spawn_cooldown():
		wait_time = max(0.1, wait_time * 0.9)
		timer.wait_time = wait_time
		print("Reducción de cooldown de spawn de enemigos: Nuevo tiempo de espera = ", wait_time)
	
	func set_player(player_inst):
		player = player_inst
	
	func add_enemy():
		eny = Enemy.new()
		add_child(eny)
		eny.set_player(player)
		var pos = enemy_position()
		eny.position = pos
		enemies += 1
	
	func time_out():
		add_enemy()
		timer.start()
	
	func enemy_position() -> Vector2:
		var visible_rect = get_viewport().get_visible_rect()
		var screen_size = visible_rect.size
		
		
		var edge = randi() % 4
		
		var pos = Vector2()
		
		match edge:
			0: #-Arriba-
				pos.x = randf_range(-screen_size.x * 0.5, screen_size.x * 1.5)
				pos.y = -10
			1: #-Abajo-
				pos.x = randf_range(-screen_size.x * 0.5, screen_size.x * 1.5)
				pos.y = screen_size.y + 10
			2: #-Izquierda-
				pos.x = -10
				pos.y = randf_range(-screen_size.y * 0.5, screen_size.y * 1.5)
			3: #-Derecha-
				pos.x = screen_size.x + 10
				pos.y = randf_range(-screen_size.y * 0.5, screen_size.y * 1.5)
		
		return pos

