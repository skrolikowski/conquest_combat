extends Node2D
class_name Combat

signal turn_started(_turn_group : CombatGroup, _defend_group : CombatGroup)
signal square_attacked(_square : CombatSquare, _assault : CombatAssault)
signal square_occupied(_square : CombatSquare, _movement : CombatMovement)
signal movement_undone
signal combat_ended(_victory_group: CombatGroup)

# Combat takes place on 3x4 grid
# Movement can be undone, up until the last attack
# Units can move to an empty square or square occupied by a friendly unit
# Click on units to select them, then click on a square to move or attack
# Each square can hold 6 Infantry units; Calvary and Artillary count as 2 Infantry units
# The goal is to capture the opponent's flag, or eliminate all opposing units
# The opponent may also choose to retreat, ending combat in your favor
# Retreating gives the opponent one last parting shot
# All units start combat in the "Reserves Row", off the battlefield
# The first row on the player's side is called "Home Row"

# Leaders determine the num of moves in combat, affect morale (thru charisma), and enemy morale (thru reputation)
# Leaders gain experience in battle to spend on stat points (i.e. charisma)
# A Leader's reputation is earned through battles won
# A Leader with high Charisma can reduce the chance of panic
# A Leader with high Reputation can increase the chance of panic in the enemy

# Infantry and Calvary can attack enemies in adjacent squares, not diagaonally
# Artillary can only attack enemies in the same column
# Infantry can move 1 square or attack an adjacent enemy square
# Calvary can move 2 squares, or move 1 square and attack or simply attack an adjacent enemy square
# Artillary can only occupy the "Reserves" or "Home Row"; when in home row can attack enemies in the same column

# Calvary receive a "charge bonus" for moving and attacking in the same turn (as long as they have not panicked in the previous turn)
# Artillary attacks are most effective in close range
# Artillary attacks are less effective against other Artillary units, more effective against Infantry and Calvary
# Infantry and Calvary attacks are more effective against Artillary units
# A unit's strength is determined by its level, the lower the level the lower the health/strange
# Attacks are more effective against enemy squares with multiple unit types (Combined Arms Bonus)
# Attacks are more effective when attacking an enemy square from multiple adjacent squares (Flanking Bonus)
# Units are more likely to attack units of their own type (Infantry vs Infantry, etc)

# When a unit is damaged, there is a chance it will panic and retreat one square towards their "Reserves Row"
# The greater damage a unit takes, the greater the chance it will panic

# When a unit's health reaches 0, it is dead
# Units heal 1 health point each game turn when residing in a Colony
# If a unit panics, and cannot retreat it'll take an additional point of damage

var battlefield      : Dictionary = {}
var selected_units   : Array[CombatUnit] = []
var selection_tweens : Array[Tween] = []
var move_history     : Array[CombatMovement] = []

var attacker      : CombatGroup
var defender      : CombatGroup
var turn_group    : CombatGroup
var defend_group  : CombatGroup
var victory_group : CombatGroup


#region READY COMBAT
func start_combat() -> void:
	
	# -- Build battlefield..
	var squares : Array[Node] = %CombatSquares.get_children()
	for square : CombatSquare in squares:
		battlefield[square.coords] = square
		
	# -- Ready combatants..
	_ready_attacker()
	_ready_defender()
	
	# -- Attacker goes first..
	begin_turn(attacker)


func end_combat() -> void:
	#TODO: create receipt for combat results..
	combat_ended.emit(victory_group)


func _ready_attacker() -> void:
	attacker.reserves_row = battlefield.get(Def.ATTACKER_RESERVE_ROW)
	attacker.reserves_row.owned_by = attacker
	attacker.flag_square  = battlefield.get(Def.ATTACKER_FLAG_SQUARE)
	attacker.combat       = self
	attacker.is_attacker  = true
	attacker.start_combat()


func _ready_defender() -> void:
	defender.reserves_row = battlefield.get(Def.DEFENDER_RESERVE_ROW)
	defender.reserves_row.owned_by = defender
	defender.flag_square  = battlefield.get(Def.DEFENDER_FLAG_SQUARE)
	defender.combat       = self
	defender.start_combat()

#endregion


#region TURN MANAGEMENT
func begin_turn(_turn_group: CombatGroup) -> void:
	unselect_all_units()

	# --
	if _turn_group == attacker:
		defend_group = defender
	else:
		defend_group = attacker
	
	# --
	turn_group = _turn_group
	turn_group.begin_turn()

	# --
	reset_undo()
	
	# -- [SIGNAL]
	turn_started.emit(turn_group, defend_group)


func end_turn() -> void:
	if not defend_group.is_human_player():
		defend_group.ai_test_for_retreat()
	
	# --
	check_victory_conditions()

	# --
	if victory_group != null:
		end_combat()
	else:
		# -- Switch turns..
		if turn_group == attacker:
			begin_turn(defender)
		else:
			begin_turn(attacker)
		


func check_victory_conditions() -> void:
	if victory_group == null:

		# -- Check if flag was captured..
		if turn_group.is_human_player():
			if battlefield.get(Def.DEFENDER_FLAG_SQUARE).occupied_by == turn_group:
				print("Human Captures Flag!")
				victory_group = turn_group
		else:
			if battlefield.get(Def.ATTACKER_FLAG_SQUARE).occupied_by == turn_group:
				print("AI Captures Flag!")
				victory_group = turn_group

		# -- Check if all units are defeated..
		if defend_group.get_num_units() == 0:
			print("Win by Defeat!")
			victory_group = turn_group

		# -- Check if opposing group is retreating..
		if defend_group.is_retreating:
			print("Win by Retreat!")
			victory_group = turn_group

#endregion


#region UNIT SELECTION
func can_select_unit(_unit: CombatUnit) -> bool:

	# -- Deny if not player's unit..
	if _unit.stat.player != turn_group.player:
		return false

	# -- Deny if unit rejects..
	if not _unit.can_select():
		return false

	return true


func select_unit(_unit: CombatUnit) -> void:
	if selected_units.has(_unit):
		unselect_unit(_unit)
	elif _unit.can_select():
		_unit.is_selected = true
		selected_units.append(_unit)

	# -- Highlight selected units..
	start_pulsing_effects()


func unselect_unit(_unit: CombatUnit) -> void:
	if selected_units.has(_unit):
		_unit.is_selected = false
		selected_units.erase(_unit)

	# -- Highlight selected units..
	start_pulsing_effects()

func unselect_all_units() -> void:
	for selected_unit : CombatUnit in selected_units:
		selected_unit.is_selected = false
	selected_units.clear()

	# -- Clear highlights..
	stop_all_pulsing_effects()

#endregion


#region PULSE HIGHLIGHT EFFECT
func start_pulsing_effects() -> void:
	stop_all_pulsing_effects()
	
	# -- Create highlight effect..
	for unit : CombatUnit in selected_units:
		var tween : Tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_loops(-1)
		
		# -- Set highlight effect..
		var property : Node = unit.get_node("AnimatedSprite2D") as Node
		tween.tween_property(property, "modulate", Color.YELLOW_GREEN, 0.5)
		tween.tween_property(property, "modulate", Color.WHITE, 0.5)
		
		selection_tweens.append(tween)


func stop_all_pulsing_effects() -> void:
	if selection_tweens.size() > 0:	
		for tween : Tween in selection_tweens:
			tween.stop()
		selection_tweens.clear()

		for unit : CombatUnit in turn_group.units:
			var property : Node = unit.get_node("AnimatedSprite2D") as Node
			property.modulate = Color.WHITE

#endregion


#region UNIT MOVEMENT
func can_move_to_square(_square: CombatSquare) -> bool:
	if selected_units.size() == 0:
		return false
	
	return turn_group.can_move_to_square(_square)


func can_move_unit_to_square(_unit: CombatUnit, _square: CombatSquare) -> bool:
	
	# -- Deny if invalid unit move..
	if not _unit.can_move_to_square(_square):
		return false

	# -- Deny if no more room in square..
	if not _square.can_add_unit(_unit):
		return false

	return true


func move_selected_units_to_square(_square: CombatSquare) -> void:
	var moved_units : Array[CombatUnit] = []
	
	# --
	for unit: CombatUnit in selected_units:
		if can_move_unit_to_square(unit, _square):
			moved_units.append(unit)

	# --
	var movement : CombatMovement = CombatMovement.record(battlefield, moved_units, _square)
	move_history.append(movement)

	# --
	for unit: CombatUnit in moved_units:
		move_unit_to_square(unit, _square)
		unselect_unit(unit)

	# --
	if moved_units.size() > 0:
		square_occupied.emit(_square, movement)

		# -- Check for victory conditions..
		check_victory_conditions()


func move_unit_to_square(_unit: CombatUnit, _square: CombatSquare) -> void:
	
	# -- Update unit..
	_unit.move_to_square(_square)
	
	# -- Remove unit from current square..
	var prev_square : CombatSquare = _unit.combat_square
	prev_square.remove_unit(_unit)

	# -- Add unit to new square..
	_square.add_unit(_unit, true)
	

func find_move_square_for_cavalry(_unit: CombatUnit, _square: CombatSquare) -> CombatSquare:
	var _sort_by_distance : Callable = func (_a: CombatSquare, _b: CombatSquare) -> bool:
		return _unit.get_distance_to_square(_a) < _unit.get_distance_to_square( _b)
	
	# -- Find all adjacent squares..
	var adj_squares : Array[CombatSquare] = []
	var directions  : Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for direction : Vector2i in directions:
		var adj_coords : Vector2i = _square.coords + direction
		if battlefield.has(adj_coords):
			var adj_square: CombatSquare = battlefield[adj_coords]
			if can_move_unit_to_square(_unit, adj_square):
				adj_squares.append(adj_square)

	# -- Choose the closest valid square..
	if adj_squares.size() > 0:
		adj_squares.sort_custom(_sort_by_distance)
		return adj_squares[0]

	return null

#endregion


#region UNDO MOVEMENT
func reset_undo() -> void:
	move_history.clear()
	move_history.append(CombatMovement.record(battlefield, turn_group.units))


func can_undo_last_move() -> bool:
	return turn_group.is_human_player() and move_history.size() > 1


func undo_last_move() -> void:
	if can_undo_last_move():
		move_history.pop_back()
		move_history.back().restore()
		
		# --
		movement_undone.emit()
		
		
#endregion


#region UNIT ATTACK
func can_attack_square(_square: CombatSquare) -> bool:
	if selected_units.size() == 0:
		return false

	# -- Deny if invalid group move..
	if not turn_group.can_attack_square(_square):
		return false

	return true


func attack_square(_square: CombatSquare) -> void:
	reset_undo()
	
	# --
	# -- Gather all units attacking requested CombatSquare..
	var attacking_units : Array[CombatUnit] = []
	for unit: CombatUnit in selected_units:
		if turn_group.can_attack_square(_square) and unit.can_attack_square(_square):
			attacking_units.append(unit)
	
	# --
	# -- Limit the number of attacking units to the number of attacks left
	attacking_units = attacking_units.slice(0, turn_group.num_attacks)

	# --
	# -- Assure attacking unit positioning..
	for unit: CombatUnit in attacking_units:
		if unit.stat.unit_type == Term.UnitType.CALVARY:
			"""
			CALVARY units can move 1 square before attacking
			"""
			if unit.get_distance_to_square(_square) == 2:
				var move_square: CombatSquare = find_move_square_for_cavalry(unit, _square)
				if move_square != null:
					move_unit_to_square(unit, move_square)
					
					# -- [BONUS] - increase for "charge bonus"
					printt("BONUS", "Charge", "+6")
					unit.bonus_points += 6

					#TODO: if cannot move (may be occupied), cancel attack

	# --
	# -- Flanking Bonus..
	for unit: CombatUnit in attacking_units:
		# -- [BONUS] - increase "bonus chance" for "flanking bonus"
		var flanking_bonus : int = calculate_flanking_bonus(_square, attacking_units)
		if flanking_bonus > 0:
			printt("BONUS", "Flank", str(flanking_bonus))
			unit.bonus_points += flanking_bonus

	# --
	var assault : CombatAssault = CombatAssault.new()
	assault.square = _square
	
	# --
	# -- Each attacking unit gets 1x attack per current health..
	for unit: CombatUnit in attacking_units:
		for i in range(unit.stat.health):
			unit.calculate_attack_on_square(_square, assault)
			unit.animation_attack(_square)
			unselect_unit(unit)
		
		# --
		unit.attack_points -= 1
		turn_group.num_attacks -= 1
		unit.move_points = 0

	# --
	# -- Apply damage to target units..
	var target_attacks : Dictionary = assault.get_target_attacks()
	for target: CombatUnit in target_attacks:
		var target_died : bool = target.take_damage(target_attacks[target])
		if target_died:
			assault.death_count += 1
		else:
			# --
			# -- Panic Retreat Check..
			if target.is_panicked:
				var retreat_square : CombatSquare = target.get_retreat_square()
				printt("PANIC RETREAT!", target.stat.title, retreat_square.coords)
				if retreat_square != null:
					move_unit_to_square(target, retreat_square)

	# --
	square_attacked.emit(_square, assault)

	# --
	# -- Check for victory conditions..
	check_victory_conditions()


func calculate_flanking_bonus(_square: CombatSquare, _attacking_units:Array[CombatUnit]) -> int:
	var bonus_points : int = -2
	var directions   : Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for direction: Vector2i in directions:
		var adj_coords : Vector2i = _square.coords + direction
		if battlefield.has(adj_coords):
			var adj_square : CombatSquare = battlefield[adj_coords]
			var has_unit   : bool = false
			for unit: CombatUnit in _attacking_units:
				if adj_square.has_unit(unit):
					has_unit = true
					bonus_points += 2
					break

	return bonus_points

#endregion
