extends Resource
class_name InventoryItem

enum Category { COLLECTIBLE = 1, GAMEPLAY = 2 }

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_flags("Collectible", "Gameplay Item") var categories: int = Category.COLLECTIBLE
@export var icon: Texture2D
@export_range(1, 999, 1) var max_stack: int = 1
@export var usable: bool = false
@export var consumable: bool = false

# Override in a specialized item script when gameplay behavior is introduced.
func use(_user: Node) -> bool:
	return false
