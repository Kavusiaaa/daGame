extends Control
class_name NoteReader

# Inspector: edit Note Title, Note Text, Credits Text, Note Image or Image Path
# on the root NoteReader node. BBCode supports [img]res://...[/img].
@export var note_title: String = "Notatka"
@export_multiline var note_text: String = ""
@export_multiline var credits_text: String = ""
@export var note_image: Texture2D
@export_file("*.png", "*.jpg", "*.webp") var image_path: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	%Close.pressed.connect(close_reader)
	refresh()

func set_note(title: String, body: String, credits: String = "", image: Texture2D = null) -> void:
	note_title = title
	note_text = body
	credits_text = credits
	note_image = image
	refresh()

func refresh() -> void:
	if not is_node_ready():
		return
	%Title.text = note_title
	%Body.text = note_text
	%Credits.text = credits_text
	var texture := note_image
	if texture == null and not image_path.is_empty():
		texture = load(image_path) as Texture2D
	%NoteImage.texture = texture
	%NoteImage.visible = texture != null
	%NoteImage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func open_note() -> void:
	visible = true

func close_reader() -> void:
	visible = false
