extends Node2D
class_name CombatManager

var combat_queue : Array[CombatQueue] = []
var combat       : Combat = null


func _ready() -> void:
	%MenuCanvas.connect("new_combat", _on_new_combat)
	
	%CombatCanvas.hide()
	#%CombatCanvas.connect("end_turn", _on_end_turn_pressed)
	%CombatCanvas.connect("end_combat", _on_end_combat)


func _on_new_combat(_attacker:UnitStats, _defender:UnitStats) -> void:
	%MenuCanvas.hide()
	%CombatCanvas.show()

	create_unit_combat(_attacker, _defender)
	load_queued_combat()


func _on_end_combat() -> void:
	%MenuCanvas.show()
	%CombatCanvas.hide()
	
	if combat != null:
		combat.queue_free()


func load_queued_combat() -> void:
	if combat_queue.size() > 0:
		var queue      : CombatQueue = combat_queue.pop_front()
		var new_combat : Combat = queue.create_combat()
		
		if new_combat != null:
			load_combat(new_combat)


func load_combat(_combat: Combat) -> void:
	if combat != null:
		combat.queue_free()

	add_child(_combat)
	
	# -- [UI]
	%CombatCanvas.combat = _combat

	# -- Load new combat..
	combat = _combat
	combat.start_combat()
	

func create_unit_combat(_attacker:UnitStats, _defender:UnitStats) -> void:
	var queue: CombatQueue = CombatQueue.new()
	queue.name = "UnitCombatQueue"
	queue.attacker = _attacker
	queue.defender = _defender
	
	combat_queue.append(queue)


#func create_colony_combat(_attacker:UnitStats, _defender:Building) -> void:
	#var queue: CombatQueue = CombatQueue.new()
	#queue.name = "ColonyCombatQueue"
	#queue.attacker = _attacker
	#queue.building = _defender
	#
	#combat_queue.append(queue)




func _unhandled_input(_event:InputEvent) -> void:
	if _event is InputEventMouseButton:
		var mouse_event    : InputEventMouseButton = _event as InputEventMouseButton
		var world_position : Vector2 = get_global_mouse_position()
		
		if mouse_event.button_index == 1 and mouse_event.pressed:
			
			# -- Modifier: select multiple units
			# if not Input.is_action_pressed("move_left"):
			# 	combat.unselect_all_units()

			"""
			Mouse Button - Press
			"""
			attempt_select_area2D(world_position)


func attempt_select_area2D(_position : Vector2) -> void:
	var collision : Node = detect_collision(_position)
	if collision:
		if collision is CombatUnit:
			select_combat_unit(collision as CombatUnit)
		elif collision is CombatSquare:
			select_combat_square(collision as CombatSquare)
	else:
		combat.unselect_all_units()


func detect_collision(_position : Vector2) -> Node:
	var space : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query : PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.collide_with_areas  = true
	query.collide_with_bodies = false
	query.position            = _position

	var results : Array[Dictionary] = space.intersect_point(query, 2)
	results.sort_custom(_sort_collision_results)
	
	if results.size() > 0:
		return results[0]['collider']
	return null


func _sort_collision_results(_a: Dictionary, _b: Dictionary) -> bool:
	return _a.collider is CombatUnit


func select_combat_unit(_unit: CombatUnit) -> void:
	if combat.can_select_unit(_unit):
		combat.select_unit(_unit)


func select_combat_square(_combat_square: CombatSquare) -> void:
	if combat.selected_units.size() > 0:
		
		# -- Move selected units to square..
		if combat.can_move_to_square(_combat_square):
			combat.move_selected_units_to_square(_combat_square)
			return

		# -- Attack square..
		if combat.can_attack_square(_combat_square):
			combat.attack_square(_combat_square)
			#combat.selected_units.clear()
			return



func _on_end_turn_pressed() -> void:
	if combat and combat.turn_group.is_human():
		combat.end_turn()
