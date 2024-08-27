extends Node2D
class_name CombatQueue

var attacker : UnitStats
var defender : UnitStats
#var building : CenterBuilding


func create_combat() -> Combat:
	if attacker == null:
		return null

	if defender == null:
		return null

	# -- Create Combat w/ current information..
	var combat : Combat = Preload.combat.instantiate() as Combat

	# -- Ready combatants..
	combat.attacker = generate_attacker_combat_group()
	combat.defender = generate_defender_combat_group()

	return combat


func generate_attacker_combat_group() -> CombatGroup:
	var group : CombatGroup = _generate_combat_group(attacker)
	return group


func generate_defender_combat_group() -> CombatGroup:
	if defender != null:
		"""
		Defender is a Unit
		"""
		var group : CombatGroup = _generate_combat_group(defender)
		return group
	else:
		"""
		Defender is a Colony
		"""
		#TODO: pick best Leader residing in Colony
		#TODO: pick best Units residing in Colony
		#TODO: add 1x Militia Artillary Unit per Fort
		#TODO: add 1x Militia Infantry Unit per 1000 Population

		#TODO: limit number of units based on type and overall

		return null


func _generate_combat_group(_unit_stat: UnitStats) -> CombatGroup:
	var group : CombatGroup = CombatGroup.new()
	group.player = _unit_stat.player

	if _unit_stat.unit_type == Term.UnitType.LEADER:
		var leader : CombatUnit = _generate_combat_unit(_unit_stat, group)
		var units  : Array[CombatUnit] = []
		
		for stat : UnitStats in _unit_stat.attached_units:
			var unit : CombatUnit = _generate_combat_unit(stat, group)
			units.append(unit)
		
		group.leader = leader
		group.units  = units
	else:
		var units : Array[CombatUnit] = []
		var unit  : CombatUnit = _generate_combat_unit(_unit_stat, group)
		units.append(unit)
		
		group.units = units

	return group


func _generate_combat_unit(_stat: UnitStats, _combat_group: CombatGroup) -> CombatUnit:
	var unit : CombatUnit = Preload.combat_unit.instantiate() as CombatUnit
	unit.name = "CombatUnit"
	unit.combat_group = _combat_group
	unit.stat = _stat
		
	return unit
