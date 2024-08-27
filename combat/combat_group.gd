extends Node2D
class_name CombatGroup


var leader   : CombatUnit
var units    : Array[CombatUnit] = []
var player   : Player

var combat       : Combat
var flag_square  : CombatSquare
var reserves_row : CombatSquare

var num_init_units : int
var num_attacks    : int
var is_retreating  : bool = false
var is_attacker    : bool = false


func start_combat() -> void:
	num_init_units = units.size()

	# -- Fill "Reserves Row"..
	for unit : CombatUnit in units:
		unit.start_combat()
		unit.begin_turn()
		
		reserves_row.add_unit(unit)


#region TURN MANAGEMENT
func begin_turn() -> void:
	num_attacks = get_init_num_attacks()

	# -- Reset each unit's move and attack points..
	for unit: CombatUnit in units:
		unit.begin_turn()

	# -- Check if human player..
	if not is_human_player():
		printt("-- AI TURN", "--------")
		printt("--")
		ai_simulate_turn()
	else:
		printt("-- PLAYER TURN", "----")
		printt("--")

#endregion


#region COMPUTER AI
func ai_simulate_turn() -> void:

	# -- Sort units from "best" to "worst"..
	units.sort_custom(Def.sort_combat_units_by_health)

	# -- Simulate attacks..
	ai_simulate_attacks(units)

	# -- Simulate moves..
	ai_simulate_moves(units)

	# --
	combat.end_turn()


func ai_simulate_attacks(_units: Array[CombatUnit]) -> void:
	var squares : Dictionary = {}

	# -- Loop through recording CombatUnits attacking CombatSquares..
	for unit: CombatUnit in _units:
		if unit.attack_points > 0:
			var square : CombatSquare = ai_unit_attempt_attack(unit)
			if square != null:
				if squares.has(square):
					squares[square].append(unit)
				else:
					squares[square] = [unit]

				# -- BREAK on attack limit..
				if num_attacks == 0:
					break

	# -- Loop through selecting CombatUnits attacking CombatSquares..
	for square: CombatSquare in squares:
		for unit : CombatUnit in squares[square]:
			combat.select_unit(unit)

		# --
		combat.attack_square(square)
		
		# -- BREAK on victory conditions..
		if combat.victory_group != null:
			break


func ai_unit_attempt_attack(_unit: CombatUnit) -> CombatSquare:
	var squares : Array[CombatSquare] = get_squares_in_attack_range(_unit)
	#TODO: loop through squares -> attack best square (weakest units?)
	
	# -- Choose random square..
	if squares.size() > 0:
		var random_index : int = randi() % squares.size()
		return squares[random_index]

	return null


func ai_simulate_moves(_units : Array[CombatUnit]) -> void:
	var squares : Dictionary = {}

	# -- Loop through recording CombatSquares with moving CombatUnits..
	for unit: CombatUnit in _units:
		if unit.move_points > 0:
			var square : CombatSquare = ai_unit_attempt_move(unit)
			if square != null:
				if squares.has(square):
					squares[square].append(unit)
				else:
					squares[square] = [unit]

	# -- Loop through selecting CombatSquares with moving CombatUnits..
	for square : CombatSquare in squares:
		for unit : CombatUnit in squares[square]:
			combat.select_unit(unit)

		# --
		combat.move_selected_units_to_square(square)

		# -- BREAK on victory conditions..
		if combat.victory_group != null:
			break


func ai_unit_attempt_move(_unit: CombatUnit) -> CombatSquare:
	var squares : Array[CombatSquare] = get_squares_in_move_range(_unit)
	
	if squares.size() > 0:
		# -- Sort squares by distance to flag square..
		var _sort_by_target_distance : Callable = func (a: CombatSquare, b: CombatSquare) -> bool:
			var target : CombatSquare = combat.defend_group.flag_square
			var a_distance : float = Vector2(a.coords).distance_to(target.coords)
			var b_distance : float = Vector2(b.coords).distance_to(target.coords)
			return a_distance < b_distance

		# -- Sort squares by priority..
		squares.sort_custom(_sort_by_target_distance)

		return squares[0]
	
	return null

#endregion


#region RETREAT MANAGEMENT
func ai_test_for_retreat() -> void:
	var opponent : CombatGroup = combat.turn_group
	#TODO: based on CombatGroup's leader's charisma
	#TODO: based on lost % of CombatUnits

	# -- Calculate retreat chance..
	var offense : float = log(opponent.get_lost_units() + opponent.leader.stat.stat_props.reputation)
	var defense : float = log(get_lost_units() + leader.stat.stat_props.charisma)
	
	var chance  : float = (offense - defense) / 10.0
	chance = clamp(chance, 0.0, 1.0)

	is_retreating = randf() < chance


func can_retreat() -> bool:
	return not has_attacked_this_turn()


func retreat() -> void:
	is_retreating = true
	combat.end_turn()

#endregion


func is_human_player() -> bool:
	return player.is_human


func has_attacked_this_turn() -> bool:
	return num_attacks < get_init_num_attacks()


func get_lost_units() -> int:
	return num_init_units - units.size()


func get_alive_units() -> Array[CombatUnit]:
	var alive_units : Array[CombatUnit] = []
	for unit : CombatUnit in units:
		if unit.is_alive():
			alive_units.append(unit)
	return alive_units
	

func get_num_units() -> int:
	return units.size()


func get_init_num_attacks() -> int:
	if leader != null:
		return leader.stat.stat_props.attacks_in_combat
	else:
		return units.size()


func get_squares_in_attack_range(_unit: CombatUnit) -> Array[CombatSquare]:
	var squares : Array[CombatSquare] = []

	if _unit.stat.unit_type == Term.UnitType.ARTILLARY:
		# Attack Range:
		# - O -
		# - X -
		# - X -
		# - X -
		pass

		# -- Get squares in attack range..
		for x: int in range(3):
			var square_offset : Vector2i = Vector2i(-x, 0)
			if is_attacker:
				square_offset = Vector2i(x, 0)

			var square_coords : Vector2i = _unit.combat_square.coords + square_offset
			var square        : CombatSquare = combat.battlefield.get(square_coords)
			
			if square != null:
				if can_attack_square(square) and _unit.can_attack_square(square):
					squares.append(square)
	else:
		# Attack Range:
		# - X -
		# X O X
		# - X -

		var r_min : int = -_unit.attack_points
		var r_max : int = _unit.attack_points + 1
		var r_arr : Array = range(r_min, r_max)
	
		# -- Get squares in attack range..
		for x: int in r_arr:
			for y: int in r_arr:
				var distance : int = abs(x) + abs(y)
				
				if distance != 0 and distance <= _unit.attack_points:
					var square_coords : Vector2i = _unit.combat_square.coords + Vector2i(x, y)
					var square        : CombatSquare = combat.battlefield.get(square_coords)
					
					if square != null:
						if can_attack_square(square) and _unit.can_attack_square(square):
							squares.append(square)
	
	return squares


func _recursive_squares_in_move_range(_unit: CombatUnit, _squares:Array[CombatSquare], _square: CombatSquare, _distance: int = 0) -> void:
	#printt("Enter", _square.coords, _distance)
	if _distance == _unit.move_points:
		#printt("Append", _square.coords)
		_squares.append(_square)
		return

	# --
	var movement : int = 1
	var x_arr    : Array
	var y_arr    : Array

	# --
	if _square.is_reserves_row:
		y_arr = range(3)
	else:
		y_arr = range(-movement,  movement + 1)

	# --
	if not combat.defend_group.is_attacker:
		if _square.is_reserves_row:
			x_arr = range(movement, movement + 1)
		else:
			x_arr = range(0, movement + 1)
	else:
		if _square.is_reserves_row:
			x_arr = range(-movement, -movement + 1)
		else:
			x_arr = range(-movement, 0)

	# --
	for x: int in x_arr:
		for y: int in y_arr:
			var distance : int = abs(x) + abs(y)
			
			if _square.is_reserves_row:
				distance = abs(y)

			if distance == movement:
				var new_coords : Vector2i = _square.coords + Vector2i(x, y)
				var new_square : CombatSquare = combat.battlefield.get(new_coords)

				if new_square != null:
					#printt("Next", new_coords, _distance)
					if can_move_to_square(new_square) and _unit.can_move_to_square(new_square):
						_recursive_squares_in_move_range(_unit, _squares, new_square, _distance + 1)
					else:
						_recursive_squares_in_move_range(_unit, _squares, _square, _distance + 1)


func get_squares_in_move_range(_unit: CombatUnit) -> Array[CombatSquare]:

	var squares : Array[CombatSquare] = []
	_recursive_squares_in_move_range(_unit, squares, _unit.combat_square)

	# Range of 1:
	# - - -
	# X O X
	# - X -

	# Range of 2:
	# - - -
	# X O X
	# X X X
	# - X -

	# var r_min : int = -_unit.move_points
	# var r_max : int = _unit.move_points + 1
	# var x_arr : Array = range(r_min, r_max)
	# var y_arr : Array = range(r_min, 0)
	
	# if _unit.combat_square.is_reserves_row:
	# 	# -- If _unit is on "Reserves Row" allow access to all x-squares
	# 	x_arr = range(3)

	# if combat.defend_group.is_human_player():
	# 	y_arr = range(0, r_max)
	
	# # -- Get squares in move range..
	# for x: int in x_arr:
	# 	for y: int in y_arr:
	# 		var distance : int = abs(x) + abs(y)
			
	# 		if _unit.combat_square.is_reserves_row:
	# 			distance = abs(y)

	# 		if distance != 0 and distance <= _unit.move_points:
	# 			var square_coords : Vector2i = _unit.combat_square.coords + Vector2i(x, y)
	# 			var square        : CombatSquare = combat.battlefield.get(square_coords)

	# 			if square != null:
	# 				if can_move_to_square(square) and _unit.can_move_to_square(square):
	# 					squares.append(square)

	return squares


func can_move_to_square(_square: CombatSquare) -> bool:
	
	# -- Can move if square is empty..
	if _square.is_empty():
		return true
		
	# -- Can move if square is occupied by friendly units..
	if _square.occupied_by == self:
		return true

	# -- Can move if square is occupied by this group..
	if _square.owned_by == self:
		return true

	return false


func can_attack_square(_square: CombatSquare) -> bool:

	# -- Deny if out of attacks this turn..
	if num_attacks == 0:
		return false

	# -- Deny if square is "Reserves Row"..
	if _square.is_reserves_row:
		return false

	# -- Deny if square is empty of units..
	if _square.is_empty():
		return false

	# -- Deny if square is occupied by friendly units..
	if _square.occupied_by == self:
		return false

	# --
	return _square.occupied_by == combat.defend_group
