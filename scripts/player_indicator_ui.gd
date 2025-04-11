extends Control

@onready var player_name = $MarginContainer/CardContent/VBoxContainer/Header/PlayerName
@onready var vigor_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/VIG
@onready var flux_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/FLUX
@onready var fort_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/FORT

# Status indicators for curses
@onready var necromancy_indicator = $MarginContainer/CardContent/Indicators/NecromancyIndicator
@onready var darkness_indicator = $MarginContainer/CardContent/Indicators/DarknessIndicator
@onready var dispel_indicator = $MarginContainer/CardContent/Indicators/DispelIndicator
@onready var chaos_surge_indicator = $MarginContainer/CardContent/Indicators/ChaosSurgeIndicator
@onready var marked_indicator = $MarginContainer/CardContent/Indicators/MarkedIndicator
@onready var charmed_indicator = $MarginContainer/CardContent/Indicators/CharmedIndicator
@onready var illusion_indicator = $MarginContainer/CardContent/Indicators/IllusionIndicator

signal player_indicator_selected(player_data: Dictionary)

@onready var turn_indicator = $MarginContainer/CardContent/TurnIndicator

# Turn indicator textures
var active_turn_texture = preload("res://assets/textures/turn_indicators/is_turn.png")
var inactive_turn_texture = preload("res://assets/textures/turn_indicators/is_not_turn.png")

var current_player_data
var player_steam_id: int = 0  # New variable to store player ID

func _ready():
	# Add error checking to verify nodes are found
	if !player_name:
		push_error("PlayerIndicatorUI: player_name node not found")
		return
		
	if !vigor_label || !flux_label || !fort_label:
		push_error("PlayerIndicatorUI: stat labels not found")
		return
		
	if !necromancy_indicator || !darkness_indicator || !dispel_indicator || \
	   !chaos_surge_indicator || !marked_indicator || !charmed_indicator || \
	   !illusion_indicator:
		push_error("PlayerIndicatorUI: status indicators not found")
		return
	
	# Connect to signal only if all nodes are properly loaded
	MatchState.player_updated.connect(update_player_indicator)
	

func update_player_indicator(player_data: Dictionary):
	current_player_data = player_data
	# Add null checks
	if !player_name || !vigor_label || !flux_label || !fort_label:
		push_error("PlayerIndicatorUI: Trying to update with null nodes")
		return
		
	#print(player_data)
	var steam_id: int = player_data["steam_id"]["steam_id"]
	player_name.text = Steam.getFriendPersonaName(steam_id)
	
	# Update stats
	vigor_label.text = "VIG:" + str(player_data["vigor"])
	flux_label.text = "FLX:" + str(player_data["arcane_flux"])
	fort_label.text = "FORT:" + str(player_data["treasure"])
	
	# Update curse indicators
	update_status_indicators(player_data["curses"])

func update_status_indicators(curses: Array):
	# Add null checks
	if !necromancy_indicator || !darkness_indicator || !dispel_indicator || \
	   !chaos_surge_indicator || !marked_indicator || !charmed_indicator || \
	   !illusion_indicator:
		push_error("PlayerIndicatorUI: Trying to update indicators with null nodes")
		return
		
	# Reset all indicators to hidden first
	necromancy_indicator.visible = false
	darkness_indicator.visible = false
	dispel_indicator.visible = false
	chaos_surge_indicator.visible = false
	marked_indicator.visible = false
	charmed_indicator.visible = false
	illusion_indicator.visible = false
	
	# Show relevant curse indicators
	for curse in curses:
		match curse:
			"Life Steal", "Life Drain", "Undeath", "Lich", "Divine Wrath":
				necromancy_indicator.visible = true
			"Darkness":
				darkness_indicator.visible = true
			"Dispel":
				dispel_indicator.visible = true
			"Chaos Surge":
				chaos_surge_indicator.visible = true
			"Marked":
				marked_indicator.visible = true
			"Charmed":
				charmed_indicator.visible = true
			"Illusion":
				illusion_indicator.visible = true

func toggle_turn_indicator(is_active: bool):
	if turn_indicator:
		turn_indicator.texture = active_turn_texture if is_active else inactive_turn_texture

func toggle_turn_indicator_by_id(steam_id: int):
	toggle_turn_indicator(player_steam_id == steam_id)

func set_player_id(steam_id: int):
	player_steam_id = steam_id

func _on_button_pressed():
	emit_signal("player_indicator_selected", current_player_data)
