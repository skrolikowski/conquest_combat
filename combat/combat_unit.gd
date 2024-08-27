extends Area2D
class_name CombatUnit

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D as AnimatedSprite2D
@onready var shape  : CollisionShape2D = $CollisionShape2D as CollisionShape2D

var stat          : UnitStats : set = _set_stat
var is_selected   : bool : set = _set_selected
var is_panicked   : bool = false

var morale_points : int
var move_points   : int
var attack_points : int
var combat_group  : CombatGroup
var combat_square : CombatSquare

var base_attack_points  : int = 6
var base_defense_points : int = 1
var bonus_points        : int = 0


#region TURN MANAGEMENT
func start_combat() -> void:
	stat.combat_stats.battles += 1

	if not combat_group.is_attacker:
		sprite.scale = Vector2(-1.00, 1.00)

	# -- Unable selection for AI units..
	if not combat_group.is_human_player():
		shape.disabled = true


func begin_turn() -> void:
	attack_points = 1
	bonus_points  = 0

	# --
	if stat.unit_type == Term.UnitType.CALVARY:
		move_points = 2
	else:
		move_points = 1

	# --
	reduce_panic()

#endregion


#region PANIC MANAGEMENT
func test_for_panic(_damage_taken: int) -> void:
	var group_leader    : CombatUnit = combat_group.leader
	var opponent_leader : CombatUnit = combat_group.combat.turn_group.leader

	if group_leader == null or opponent_leader == null:
		# -- Ignore for single unit armies..
		return

	# --
	var defense : float = log(2.50 + group_leader.stat.stat_props.charisma)
	var offense : float = log(1.50 + opponent_leader.stat.stat_props.reputation)

	# -- Calculate panic chance..
	var chance : float = (defense - offense) / 10.0
	chance = clamp(chance, 0.0, 1.0)

	if randf() < chance:
		is_panicked = true
		morale_points = 2


func reduce_panic() -> void:
	if is_panicked:
		morale_points += 1
		morale_points = max(morale_points, 0)

		if morale_points == 0:
			is_panicked = false

#endregion


#region STATS
func get_attack_points() -> int:
	#TODO: include War Academy bonus (+2 per level)
	return base_attack_points


func get_defense_points() -> int:
	#TODO: include War Academy bonus (+1 per level)
	return base_defense_points


func take_damage(_damage: int) -> bool:
	test_for_panic(_damage)

	# -- Check for target panic..
	if is_panicked and not can_retreat():
		printt("PANIC RETREAT!", stat.title, combat_group.is_human_player())
		_damage += 1

	# --
	stat.health -= _damage
	if stat.health <= 0:
		die()
		return true
	else:
		animation_hurt()
	
	return false


func die() -> void:
	var _on_finished : Callable = func() -> void:
		combat_group.units.erase(self)
		combat_square.remove_unit(self)
		queue_free()
		
	sprite.play("die")
	sprite.connect("animation_finished", _on_finished, CONNECT_ONE_SHOT)


func _set_stat(_stat:UnitStats) -> void:
	stat = _stat
	
	# --
	sprite = $AnimatedSprite2D as AnimatedSprite2D
	shape  = $CollisionShape2D as CollisionShape2D
	
	# --
	if stat.unit_type == Term.UnitType.ARTILLARY:
		sprite.sprite_frames = Preload.combat_artillary_unit
	elif stat.unit_type == Term.UnitType.CALVARY:
		sprite.sprite_frames = Preload.combat_calvary_unit
	elif stat.unit_type == Term.UnitType.INFANTRY:
		sprite.sprite_frames = Preload.combat_infantry_unit
		

#endregion


#region SELECTION
func can_select() -> bool:
	
	# -- Deny if unit is dead..
	if stat.is_dead():
		return false

	# -- Deny if unit is out of action points..
	if attack_points == 0 and move_points == 0:
		return false

	return true


func _set_selected(_selected: bool) -> void:
	is_selected = _selected

#endregion


func animation_hurt() -> void:
	var _on_finished : Callable = func() -> void:
		animation_idle()
	sprite.play("hurt")
	sprite.connect("animation_finished", _on_finished, CONNECT_ONE_SHOT)


func animation_idle() -> void:
	sprite.play("idle")

	if combat_group.is_attacker:
		sprite.scale = Vector2i(1, 1)
	else:
		sprite.scale = Vector2i(-1, 1)


func about_face(_direction: Vector2) -> void:
	if combat_group.is_attacker:
		if _direction.x < 0:
			sprite.scale = Vector2i(-1, 1)
		else:
			sprite.scale = Vector2i(1, 1)
	else:
		if _direction.x > 0:
			sprite.scale = Vector2i(1, 1)
		else:
			sprite.scale = Vector2i(-1, 1)


#region MOVEMENT
func animate_move(_target_position: Vector2) -> void:
	sprite.play("move")
	about_face(global_position.direction_to(_target_position))

	var _on_finished_animation : Callable = func() -> void:
		global_position = _target_position
		animation_idle()
			
	# --
	var tween : Tween = create_tween()
	tween.tween_property(self, "global_position", _target_position, 0.5)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(_on_finished_animation)
	
	
func move_to_square(_square: CombatSquare) -> void:
	move_points  -= get_distance_to_square(_square)
	combat_square = _square

	# -- Restrict attack if already moved..
	if move_points == 0:
		attack_points = 0
		

func can_move_to_square(_square: CombatSquare) -> bool:

	# -- Deny if moving to same square..
	if combat_square == _square:
		return false

	# -- Verify move distance..
	if move_points < get_distance_to_square(_square):
		return false

	# -- Artillary can only occupy the "Reserves" or "Home Row"
	if stat.unit_type == Term.UnitType.ARTILLARY:
		return _square.is_reserves_row or _square.is_home_row

	return true


func can_retreat() -> bool:
	if combat_square.is_reserves_row:
		return false
	
	return get_retreat_square() != null


func get_retreat_square() -> CombatSquare:
	
	# -- Get retreat direction..
	var retreat_direction : Vector2i

	if combat_group.is_human_player():
		retreat_direction = Vector2i( 1, 0)
	else:
		retreat_direction = Vector2i(-1, 0)

	# --
	var square : CombatSquare = combat_group.combat.battlefield.get(combat_square.coords + retreat_direction)
	if combat_group.can_move_to_square(square):
		return square

	return null


func get_distance_to_square(_square: CombatSquare) -> int:

	# -- Calculate move distance..
	var x_diff : int = abs(combat_square.coords.x - _square.coords.x)
	var y_diff : int = abs(combat_square.coords.y - _square.coords.y)
	
	if combat_square.is_reserves_row or _square.is_reserves_row:
		return x_diff
	else:
		return x_diff + y_diff

#endregion


#region ATTACK
func can_attack_square(_square: CombatSquare) -> bool:
	
	# -- Deny if out of attack points..
	if attack_points == 0:
		return false

	# -- Deny if attempting to attack same square..
	if combat_square == _square:
		return false

	# -- Deny if invalid attack range..
	if stat.unit_type == Term.UnitType.ARTILLARY:
		"""
		ARTILLARY
			- Can only attack enemies in the same row
		"""
		if combat_square.coords.y != _square.coords.y:
			return false
	
	elif stat.unit_type == Term.UnitType.CALVARY:
		"""
		CALVARY
			- Can move 1x square and attack adjacent enemy squares
			- Can attack adjacent enemy squares
		"""
		return get_distance_to_square(_square) <= move_points
	
	elif stat.unit_type == Term.UnitType.INFANTRY:
		"""
		INFANTRY
			- Can attack adjacent enemy squares
		"""
		return get_distance_to_square(_square) <= move_points

	return true


func calculate_attack_on_square(_square: CombatSquare, _assault: CombatAssault) -> void:
	var target : CombatUnit = _square.get_weighted_random_unit(self)
	var bonus  : int = 0

	# --
	# -- Unit Type Bonus..
	if stat.unit_type == target.stat.unit_type:
		# -- [BONUS] - decrease "bonus chance" for attacking same unit type
		bonus -= 1
	else:
		# -- [BONUS] - increase "bonus chance" for attacking different unit type
		bonus += 1

	# --
	# -- Combined Arms Bonus..
	var combined_arms : int = _square.get_num_unit_types()
	# -- [BONUS] - extra "bonus chance" for attacking different unit type
	var combined_arms_bonus : int = 2 * (combined_arms - 1)
	if combined_arms_bonus > 0:
		print("-- [Combined Arms Bonus +" + str(combined_arms_bonus) + "]")
		bonus += combined_arms_bonus

	# --
	# -- Special Unit Type Bonus..
	if stat.unit_type == Term.UnitType.ARTILLARY:
		# -- [BONUS] - increase "bonus chance" for "range bonus"
		var distance    : int = get_distance_to_square(_square)
		var range_bonus : int = 4 - distance
		if range_bonus > 1:
			print("-- [Artillary Range Bonus +" + str(range_bonus) + "]")
			bonus += range_bonus

		if stat.unit_type != target.stat.unit_type:
			# -- [BONUS] - extra "bonus chance" for attacking different unit type
			print("-- [Artillary Bonus +1]")
			bonus += 1

	# --
	# -- Record Attack..
	var attack : CombatAttack = CombatAttack.new()
	attack.attacker     = self
	attack.defender     = target
	attack.offense      = get_attack_points()
	attack.defense      = target.get_defense_points()
	attack.bonus_points = bonus_points + bonus
	attack.roll()

	_assault.attacks.append(attack)


func animation_attack(_square: CombatSquare) -> void:
	about_face(global_position.direction_to(_square.global_position))

	var _on_finished : Callable = func() -> void:
		sprite.play("idle")
		
	sprite.play("attack")
	sprite.connect("animation_finished", _on_finished, CONNECT_ONE_SHOT)

#endregion
