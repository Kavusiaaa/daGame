extends Node

signal inventory_changed
signal item_added(item_id: StringName, amount: int)
signal item_removed(item_id: StringName, amount: int)
signal coins_changed(amount: int)

const ItemDefinition = preload("res://scripts/inventory_item.gd")
const TEACHER_NOTE: InventoryItem = preload("res://teacher_note.tres")
var _definitions: Dictionary = {}
var _stacks: Dictionary = {}
var _claimed_rewards: Dictionary = {}
var _coins := 0

func _ready() -> void:
	register_item(TEACHER_NOTE)

func register_item(definition: InventoryItem) -> bool:
	if definition == null or definition.id.is_empty():
		push_warning("Inventory item definitions need a unique, non-empty ID.")
		return false
	_definitions[definition.id] = definition
	return true

func add_item(item_id: StringName, amount: int = 1) -> int:
	if amount <= 0 or not _definitions.has(item_id):
		return 0
	var definition: InventoryItem = _definitions[item_id]
	var current := int(_stacks.get(item_id, 0))
	var accepted := mini(amount, maxi(0, definition.max_stack - current))
	if accepted == 0:
		return 0
	_stacks[item_id] = current + accepted
	item_added.emit(item_id, accepted)
	inventory_changed.emit()
	return accepted

func remove_item(item_id: StringName, amount: int = 1) -> int:
	if amount <= 0 or not _stacks.has(item_id):
		return 0
	var removed := mini(amount, int(_stacks[item_id]))
	var remaining := int(_stacks[item_id]) - removed
	if remaining == 0:
		_stacks.erase(item_id)
	else:
		_stacks[item_id] = remaining
	item_removed.emit(item_id, removed)
	inventory_changed.emit()
	return removed

func has_item(item_id: StringName, amount: int = 1) -> bool:
	return amount > 0 and int(_stacks.get(item_id, 0)) >= amount

func get_item_count(item_id: StringName) -> int:
	return int(_stacks.get(item_id, 0))

func add_coins(amount: int) -> int:
	if amount <= 0:
		return _coins
	_coins += amount
	coins_changed.emit(_coins)
	return _coins

func remove_coins(amount: int) -> int:
	if amount <= 0:
		return _coins
	_coins = maxi(0, _coins - amount)
	coins_changed.emit(_coins)
	return _coins

func get_coins() -> int:
	return _coins

func grant_coins_once(reward_id: StringName, amount: int) -> bool:
	if reward_id.is_empty() or amount <= 0 or _claimed_rewards.has(reward_id):
		return false
	add_coins(amount)
	_claimed_rewards[reward_id] = true
	return true

func to_save_data() -> Dictionary:
	return {"items": _stacks.duplicate(true), "coins": _coins, "claimed_rewards": _claimed_rewards.duplicate(true)}

func apply_save_data(data: Dictionary) -> void:
	_stacks.clear()
	for raw_id in data.get("items", {}):
		var item_id := StringName(raw_id)
		if _definitions.has(item_id):
			var amount := maxi(0, int(data["items"][raw_id]))
			if amount > 0:
				_stacks[item_id] = mini(amount, (_definitions[item_id] as InventoryItem).max_stack)
	_coins = maxi(0, int(data.get("coins", 0)))
	_claimed_rewards = data.get("claimed_rewards", {}).duplicate(true)
	coins_changed.emit(_coins)
	inventory_changed.emit()

func grant_reward_once(reward_id: StringName, item_id: StringName, amount: int = 1) -> bool:
	if reward_id.is_empty() or _claimed_rewards.has(reward_id):
		return false
	if has_item(item_id):
		_claimed_rewards[reward_id] = true
		return false
	if add_item(item_id, amount) != amount:
		return false
	_claimed_rewards[reward_id] = true
	return true

func has_claimed_reward(reward_id: StringName) -> bool:
	return _claimed_rewards.has(reward_id)

func get_definition(item_id: StringName) -> InventoryItem:
	return _definitions.get(item_id) as InventoryItem

func get_items(category: InventoryItem.Category) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in _stacks:
		var definition: InventoryItem = _definitions.get(item_id)
		if definition != null and (definition.categories & category) != 0:
			result.append({"definition": definition, "amount": int(_stacks[item_id])})
	return result

func use_item(item_id: StringName, user: Node = null) -> bool:
	var definition := get_definition(item_id)
	if definition == null or not definition.usable or not has_item(item_id):
		return false
	if not definition.use(user):
		return false
	if definition.consumable:
		remove_item(item_id, 1)
	return true
