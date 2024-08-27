extends Node2D
class_name DefinitionsRef

# -- Combat constants
const DEFENDER_RESERVE_ROW : Vector2i = Vector2i(5, 0)
const DEFENDER_FLAG_SQUARE : Vector2i = Vector2i(4, 1)
const ATTACKER_RESERVE_ROW : Vector2i = Vector2i(0, 0)
const ATTACKER_FLAG_SQUARE : Vector2i = Vector2i(1, 1)

	
func get_canvas_layer() -> CanvasLayer:
	return get_tree().get_first_node_in_group("canvas_layer") as CanvasLayer


#func get_unit_scene_by_type(_unit_type: Term.UnitType) -> PackedScene:
	#return UnitScenes[_unit_type]
#
#
#func get_ui_unit_scene_by_type(_unit_type: Term.UnitType) -> PackedScene:
	#return UIUnitScenes[_unit_type]


func _convert_to_unit_type(_code: String) -> Term.UnitType:
	if _code == "settler":
		return Term.UnitType.SETTLER
	if _code == "ship":
		return Term.UnitType.SHIP
	if _code == "infantry":
		return Term.UnitType.INFANTRY
	if _code == "cavalry":
		return Term.UnitType.CALVARY
	if _code == "artillery":
		return Term.UnitType.ARTILLARY
	if _code == "explorer":
		return Term.UnitType.EXPLORER
	if _code == "leader":
		return Term.UnitType.LEADER

	return Term.UnitType.NONE

func get_unit_name_by_unit_type(_code:Term.UnitType) -> String:
	if _code == Term.UnitType.ARTILLARY:
		return "Artillary"
	if _code == Term.UnitType.CALVARY:
		return "Calvary"
	if _code == Term.UnitType.EXPLORER:
		return "Explorer"
	if _code == Term.UnitType.INFANTRY:
		return "Infantry"
	if _code == Term.UnitType.LEADER:
		return "Leader"
	if _code == Term.UnitType.SETTLER:
		return "Settler"
	if _code == Term.UnitType.SHIP:
		return "Ship"

	return "Unit"


static func sort_combat_units_by_type(a: CombatUnit, b: CombatUnit) -> bool:
	"""
	Sort units by type: See Term.UnitType
	"""
	return a.stat.unit_type > b.stat.unit_type


static func sort_combat_units_by_health(a: CombatUnit, b: CombatUnit) -> bool:
	"""
	Sort units by type: stat.health
	"""
	return a.stat.health > b.stat.health
