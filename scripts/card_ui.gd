extends Control

# UI References

@onready var card_name_label: Label = $MarginContainer/CardContent/Header/Label
@onready var level_stars: HBoxContainer = $MarginContainer/CardContent/LevelStars
@onready var star: TextureRect = $MarginContainer/CardContent/LevelStars/StarExample
@onready var card_artwork: TextureRect = $MarginContainer/CardContent/CardArtwork
@onready var atk_label: Label = $MarginContainer/CardContent/TypeIcons/Atk
@onready var def_label: Label = $MarginContainer/CardContent/TypeIcons/Def
@onready var card_button: Button = $Button

# Card Data
var card_data: Dictionary = {
	"name": "test",
	"attribute": "fire",  # Elemental attribute: normal, fire, air, earth, water, darkness, holy
	"attack": 20,
	"defense": 20,
	"artwork": "res://assets/textures/texture_00021_.png"
}

# Elemental Attribute Star Textures (Replace with your assets)
var attribute_star_textures: Dictionary = {
	"normal": preload("res://assets/textures/texture_00021_.png"),
	"fire": preload("res://assets/textures/texture_00021_.png"),
	"air": preload("res://assets/textures/texture_00021_.png"),
	"earth": preload("res://assets/textures/texture_00021_.png"),
	"water": preload("res://assets/textures/texture_00021_.png"),
	"darkness": preload("res://assets/textures/texture_00021_.png"),
	"holy": preload("res://assets/textures/texture_00021_.png")
}

# Signals
signal card_clicked(card_data)

func _ready():
	# Ensure only one star exists in LevelStars
	update_card_ui()
	card_button.connect("pressed", _on_card_clicked)


func update_card_ui():
	# Card Name
	card_name_label.text = card_data["name"]

	# Elemental Attribute Star
	if card_data["attribute"] in attribute_star_textures:
		star.texture = attribute_star_textures[card_data["attribute"]]
		star.modulate = {
			"normal": Color("#A68A64"),  # Arcane gold (default)
			"fire": Color("#B04A5A"),    # Crimson (fire)
			"air": Color("#6A8299"),     # Mystical blue (wind)
			"earth": Color("#4A3C2F"),   # Parchment brown (earth)
			"water": Color("#3F5A3C"),   # Muted green (water)
			"darkness": Color("#2A1B1F"),  # Dark crimson-tinged black
			"holy": Color("#D9A66F")     # Warm arcane amber (light)
		}[card_data["attribute"]]

	# Card Artwork
	if card_data["artwork"]:
		card_artwork.texture = load(card_data["artwork"])

	# Attack and Defense
	atk_label.text = "Atk: %d" % card_data["attack"]
	def_label.text = "Def: %d" % card_data["defense"]

func set_card_data(data: Dictionary):
	card_data = data
	update_card_ui()

func _on_card_clicked():
	emit_signal("card_clicked", card_data)
