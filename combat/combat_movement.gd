extends Node2D
class_name CombatMovement

var battlefield : Dictionary
var unit_data   : Dictionary = {}


static func record(_battlefield: Dictionary, _units: Array[CombatUnit], _square: CombatSquare = null) -> CombatMovement:
	var movement : CombatMovement = CombatMovement.new()
	movement.battlefield = _battlefield
	
	# -- record units in square..
	for unit: CombatUnit in _units:
		movement.unit_data[unit] = {
			"move_points": unit.move_points,
			"prev_coords": unit.combat_square.coords
		}

		if _square == null:
			movement.unit_data[unit]["next_coords"] = movement.unit_data[unit]["prev_coords"]

			printt("SET UNIT", unit.stat.title, movement.unit_data[unit]["next_coords"])
		else:
			movement.unit_data[unit]["next_coords"] = _square.coords

			printt("MOVE UNIT", unit.stat.title, movement.unit_data[unit]["prev_coords"], movement.unit_data[unit]["next_coords"])

	return movement


func restore() -> void:
	for unit: CombatUnit in unit_data:
		var data : Dictionary = unit_data[unit]
		
		var prev_square : CombatSquare = battlefield.get(data.prev_coords)
		var next_square : CombatSquare = battlefield.get(data.next_coords)
		
		printt("UNDO MOVE", unit.stat.title, prev_square.coords, next_square.coords)

		prev_square.remove_unit(unit)
		
		unit.move_points   = data.move_points 
		unit.combat_square = next_square
		
		next_square.add_unit(unit, true)
