extends CanvasLayer

# Card Play Area
@onready var attack_cards_container = $Control/CardPlayMargin/CardPlayArea/AttackArea/Button/ScrollContainer/AttackCards
@onready var defend_cards_container = $Control/CardPlayMargin/CardPlayArea/DefendArea/Button/ScrollContainer/DefendCards
@onready var attacker_label = $Control/CardPlayMargin/CardPlayArea/AttackArea/AttackerLabel
@onready var defender_label = $Control/CardPlayMargin/CardPlayArea/DefendArea/DefenderLabel
@onready var attack_status_indicator = $Control/CardPlayMargin/CardPlayArea/AttackArea/AttackStatusInidicator
@onready var defense_status_indicator = $Control/CardPlayMargin/CardPlayArea/DefendArea/DefenseStatusInidicator
@onready var direction_indicator = $Control/CardPlayMargin/CardPlayArea/DirectionIndicator/TextureRect

# Player Info Area
@onready var player_list_container = $Control/PlayerInfoArea/ScrollContainer/PlayerList

# Hand Area
@onready var hand_container = $Control/HandArea/ScrollContainer/HBoxContainer

# Card Info Area
@onready var card_info = $Control/CardInfoArea/VBoxContainer/CardInfo
@onready var spell_container = $Control/CardInfoArea/VBoxContainer/ScrollContainer/HBoxContainer

func _ready():
	clear_design_elements()

func begin_match():
	MatchState.start_new_match()

# Helper function to clear design elements
func clear_design_elements():
	# Clear hand cards
	for child in hand_container.get_children():
		child.queue_free()
	
	# Clear player list
	for child in player_list_container.get_children():
		child.queue_free()
	
	# Clear attack/defend areas
	for child in attack_cards_container.get_children():
		child.queue_free()
	for child in defend_cards_container.get_children():
		child.queue_free()
	
	# Clear spell area
	for child in spell_container.get_children():
		child.queue_free()

# Hand management
func add_card_to_hand(card_instance):
	hand_container.add_child(card_instance)

func remove_card_from_hand(card_instance):
	if card_instance in hand_container.get_children():
		hand_container.remove_child(card_instance)
		card_instance.queue_free()

# Attack/Defend area management
func add_card_to_attack(card_instance):
	attack_cards_container.add_child(card_instance)

func add_card_to_defense(card_instance):
	defend_cards_container.add_child(card_instance)

func clear_attack_area():
	for child in attack_cards_container.get_children():
		child.queue_free()

func clear_defense_area():
	for child in defend_cards_container.get_children():
		child.queue_free()

# Player list management
func add_player_to_list(player_instance):
	player_list_container.add_child(player_instance)

func remove_player_from_list(player_instance):
	if player_instance in player_list_container.get_children():
		player_list_container.remove_child(player_instance)
		player_instance.queue_free()

# Card info display
func show_card_info(card_data):
	card_info.update_info(card_data)  # Assuming there's an update_info method

# Spell display
func add_spell(spell_instance):
	spell_container.add_child(spell_instance)

func clear_spells():
	for child in spell_container.get_children():
		child.queue_free()

# Status indicators
func update_attack_status(status_text: String):
	attack_status_indicator.text = status_text

func update_defense_status(status_text: String):
	defense_status_indicator.text = status_text

func update_player_labels(attacker: String, defender: String):
	attacker_label.text = attacker
	defender_label.text = defender

# Direction indicator
func update_direction_indicator(texture: Texture2D):
	direction_indicator.texture = texture

