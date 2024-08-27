extends Node2D
class_name CombatAssault

var square  : CombatSquare
var attacks : Array[CombatAttack] = []

var death_count : int = 0


func get_target_attacks() -> Dictionary:
    var targets : Dictionary = {}

    for attack : CombatAttack in attacks:
        if not targets.has(attack.defender):
            targets[attack.defender] = attack.damage
        else:
            targets[attack.defender] += attack.damage

    return targets


func get_total_damage() -> int:
    var total_damage : int = 0

    for attack : CombatAttack in attacks:
        total_damage += attack.damage

    return total_damage