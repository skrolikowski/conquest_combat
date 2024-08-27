extends Area2D
class_name CombatSquare

#signal square_occupied(_group : CombatGroup)

var slots         : Dictionary = {}
var owned_by      : CombatGroup
var occupied_by   : CombatGroup
var flag_owned_by : CombatGroup

@export var coords          : Vector2i = Vector2i.ZERO
@export var grid_size       : Vector2i = Vector2i(2, 3)
@export var is_flag_square  : bool = false
@export var is_home_row     : bool = false
@export var is_reserves_row : bool = false


func _ready() -> void:
	if is_reserves_row:
		# -- resize reserves row..
		var shape  : Shape2D = ($CollisionShape2D as CollisionShape2D).shape
		var width  : float = shape.get_rect().size.x
		var height : float = shape.get_rect().size.y
		shape.size = Vector2(width, height * 3)
	
	# -- Initialize slots..
	for x: int in range(grid_size.x):
		for y: int in range(grid_size.y):
			slots[Vector2i(x, y)] = null
	
	## --	
	# %SquareCoordsLabel.text = str(coords.x) + "," + str(coords.y)
		
	# if is_home_row:
	# 	%SquareCoordsLabel.text += " [H]"
		
	# if is_flag_square:
	# 	%SquareCoordsLabel.text += " [F]"
		
	# if is_reserves_row:
	# 	%SquareCoordsLabel.text += " [R]"


func is_empty() -> bool:
	for slot: Vector2i in slots:
		if slots[slot] != null:
			return false
	return true


func has_unit(_unit: CombatUnit) -> bool:
	for slot: Vector2i in slots:
		if slots[slot] == _unit:
			return true
	return false


func get_num_units() -> int:
	"""
	Returns number of units in the square.
	"""
	var count : int = 0
	for slot: Vector2i in slots:
		if slots[slot] != null:
			count += 1
	return count


func get_num_unit_types() -> int:
	"""
	Returns number of unique unit types..
	"""
	var count : int = 0
	var types : Array = []
	for slot: Vector2i in slots:
		if slots[slot] != null and not types.has(slots[slot].stat.unit_type):
			types.append(slots[slot].stat.unit_type)
			count += 1
	return count


func get_all_units() -> Array[CombatUnit]:
	"""
	Returns all units in the square.
	"""
	var units : Array[CombatUnit] = []
	for slot : Vector2i in slots:
		if slots[slot] != null:
			units.append(slots[slot])
	return units


func get_weighted_random_unit(_unit: CombatUnit) -> CombatUnit:
	"""
	Pulls a random unit weighted by same unit type.
	"""
	var units: Array[CombatUnit] = get_all_units()
	var weighted_units: Array[CombatUnit] = []
	
	# Add units to the weighted list, with duplicates for same type units
	for target_unit: CombatUnit in units:
		weighted_units.append(target_unit)
		if target_unit.stat.unit_type == _unit.stat.unit_type:
			# Increase the weight for units of the same type
			weighted_units.append(target_unit)
			# weighted_units.append(target_unit)
	
	# Select a random unit from the weighted list
	if weighted_units.size() > 0:
		var random_index: int = randi() % weighted_units.size()
		return weighted_units[random_index]
	
	return null


func _get_slot_position(_unit: CombatUnit, _slot: Vector2i) -> Vector2:
	var rect   : Rect2 = ($CollisionShape2D as CollisionShape2D).shape.get_rect()
	var width  : float = rect.size.x / grid_size.x
	var height : float = rect.size.y / grid_size.y

	# Adjust spacing for reserves row
	if is_reserves_row:
		height = rect.size.y / grid_size.y * 2

	# -- Adjust offset for artillary and calvary units..
	var offset_x: float
	var offset_y: float = width * 0.5
	if _unit.stat.unit_type == Term.UnitType.CALVARY:
		offset_x = width * 1.0
	else:
		offset_x = width * 0.5
	
	return global_position + rect.position + Vector2(width * _slot.x, height * _slot.y) + Vector2(offset_x, offset_y)




#region UNIT MANAGEMENT
func can_add_unit(_unit: CombatUnit) -> bool:
	"""
	Returns true if there is an open spot for a unit.
	"""
	return is_empty() or _get_next_open_spot(_unit) != Vector2i.MAX


func add_unit(_unit: CombatUnit, _animate:bool = false) -> void:
	"""
	Add unit.
	"""
	var slot : Vector2i = _get_next_open_spot(_unit)
	if slot == Vector2i.MAX:
		# -- Reorganize to make room if possible..
		_reorganize_square()
		# -- Try again..
		slot = _get_next_open_spot(_unit)
		# -- If still no room, return..
		if slot == Vector2i.MAX:
			return

	# -- Add unit to square..
	slots[slot] = _unit
	%Combatants.add_child(_unit)
	
	# -- Assure occupancy..
	_update_occupancy()

	# --
	_unit.combat_square = self

	# -- update position..
	var new_position : Vector2 = _get_slot_position(_unit, slot)
	if _animate:
		_unit.animate_move(new_position)
	else:
		_unit.global_position = new_position


func remove_unit(_unit: CombatUnit) -> void:
	for slot: Vector2i in slots:
		if slots[slot] == _unit:
			
			# -- Remove unit from square..
			slots[slot] = null
			%Combatants.remove_child(_unit)
			
			_update_occupancy()
			return

#endregion


#region ORGANIZATION
func _update_occupancy() -> void:
	if is_empty():
		occupied_by = null
	else:
		for slot: Vector2i in slots:
			if slots[slot] != null:
				occupied_by = slots[slot].combat_group
				
				# square_occupied.emit(slots[slot].combat_group)


func _reorganize_square() -> void:
	# print("_reorganize_square")
	# -- Collect existing units..
	var units : Array = []

	# -- Clear slots..
	for slot : Vector2i in slots:
		if slots[slot] != null:
			units.append(slots[slot])
			slots[slot] = null

	# -- Sort units by type..
	units.sort_custom(Def.sort_combat_units_by_type)
	#for unit : CombatUnit in units:
		#print("Unit:", unit.stat.unit_type)

	# -- Reassign units to slots..
	for unit : CombatUnit in units:
		var slot : Vector2i = _get_next_open_spot(unit)
		if slot != Vector2i.MAX:
			slots[slot] = unit
			unit.global_position = _get_slot_position(unit, slot)


func _get_next_open_spot(_unit: CombatUnit) -> Vector2i:
	"""
	Returns the next open spot for a unit based on unit type.
	"""
	if _unit.stat.unit_type == Term.UnitType.CALVARY:
		for y: int in range(grid_size.y):
			if slots[Vector2i(0, y)] == null and slots[Vector2i(1, y)] == null:
				return Vector2i(0, y)
	else:
		for y: int in range(grid_size.y):
			if slots[Vector2i(0, y)] == null:
				return Vector2i(0, y)
			elif slots[Vector2i(1, y)] == null and slots[Vector2i(0, y)].stat.unit_type != Term.UnitType.CALVARY:
				return Vector2i(1, y)

	return Vector2i.MAX


#endregion
