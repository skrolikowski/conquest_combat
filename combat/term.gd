extends Node
class_name Term

enum UnitCategory {
	NONE,
	SHIP,
	MILITARY
}

enum UnitType {
	NONE,
	SETTLER,
	EXPLORER,
	INFANTRY,
	CALVARY,
	ARTILLARY,
	LEADER,
	SHIP,
}

enum UnitState {
	IDLE,
	DISBAND,
	ATTACK,      # Leaders & Ships only..
	EXPLORE,     # Explorers only..
}
