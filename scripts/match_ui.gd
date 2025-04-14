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

# Turn and Targeting State
var is_player_turn: bool = false
var is_targeted: bool = false
var current_target: int = -1  # Default to -1 until set
var is_attack_locked: bool = false
var is_defense_locked: bool = false

@onready var player_list_item_instance = preload("res://scenes/ui/card/PlayerIndicatorUi.tscn")
@onready var card = preload("res://scenes/ui/card/SpellUi.tscn")
@onready var card_effect = preload("res://scenes/ui/card/Card_Effect_Ui.tscn")

func set_current_target_randomly():
	print("set_current_target_randomly called")
	print("Current LOBBY_MEMBERS: ", Globals.LOBBY_MEMBERS)
	if Globals.LOBBY_MEMBERS.size() > 1:
		var possible_targets = []
		for member in Globals.LOBBY_MEMBERS:
			if member["steam_id"] != Globals.STEAM_ID:
				possible_targets.append(member["steam_id"])
		print("Possible targets: ", possible_targets)
		if not possible_targets.is_empty():
			current_target = possible_targets[randi() % possible_targets.size()]
			print("Selected target: ", current_target)
			print(Steam.getFriendPersonaName(current_target))
			defender_label.text = Steam.getFriendPersonaName(current_target)
			print("Defender label set to: ", defender_label.text)
		else:
			print("No possible targets found")
	else:
		print("Not enough players in lobby")

func set_is_player_turn(value: bool):
	print("set_is_player_turn called with value: ", value)
	is_player_turn = value
	if value:
		print("It's our turn, setting random target")
		set_current_target_randomly()
	# We'll add UI updates here later

func set_is_targeted(value: bool):
	is_targeted = value
	# We'll add UI updates here later

func _ready():
	clear_design_elements()
	# Connect to the signal from MatchState
	MatchState.populate_player_list.connect(_on_populate_player_list)
	MatchState.update_player_area_with_locked_in_attack.connect(_on_update_player_area_with_locked_in_attack)
	MatchState.update_player_area_with_locked_in_defense.connect(_on_update_player_area_with_locked_in_defense)
	MatchState.player_updated.connect(_on_player_updated)
	
	# Set initial target to a random other player
	set_current_target_randomly()

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
	
	# Clear all labels
	attacker_label.text = ""
	defender_label.text = ""
	attack_status_indicator.text = ""
	defense_status_indicator.text = ""

# Hand management
func add_card_to_hand(card_instance):
	hand_container.add_child(card_instance)

func remove_card_from_hand(card_instance):
	if card_instance in hand_container.get_children():
		hand_container.remove_child(card_instance)
		card_instance.queue_free()

func replenish_hand(new_cards: Array):
	#print("Replenishing hand with new cards: ", new_cards)
	for i in range(new_cards.size()):
		var card_instance = card.instantiate()
		card_instance.update_card_by_id(new_cards[i])
		card_instance.hand_order_index = i  # Set the index based on position
		card_instance.card_hovered.connect(_on_card_hovered)  # Connect to the hover signal
		card_instance.card_clicked.connect(_on_card_clicked)
		add_card_to_hand(card_instance)
		card_info.set_card_data(card_instance.card_data)

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

# Add this new function
func _on_populate_player_list(players: Dictionary, turn_order: Array):
	# Clear existing player list first
	for child in player_list_container.get_children():
		child.queue_free()
	
	# Add players in turn order
	for steam_id in turn_order:
		var player_data = players[steam_id]
		# Create a new player instance
		var player_instance = player_list_item_instance.instantiate()
		add_player_to_list(player_instance)
		player_instance.update_player_indicator(player_data)
		player_instance.set_player_id(steam_id["steam_id"])
		player_instance.player_indicator_selected.connect(_on_player_indicator_selected)

func _on_player_indicator_selected(player_data: Dictionary):
	if not is_player_turn:
		print("Cannot select target - not your turn")
		return
		
	current_target = player_data["steam_id"]["steam_id"]
	defender_label.text = Steam.getFriendPersonaName(current_target)

func update_turn_indicators(current_player_id: int):
	#print("\n=== Updating Turn Indicators ===")
	#print("Current player ID: ", current_player_id)
	#print("Number of player indicators: ", player_list_container.get_child_count())
	
	for child in player_list_container.get_children():
		#print("\nChecking player indicator...")
		if child.has_method("toggle_turn_indicator_by_id"):
			#print("  Found valid player indicator")
			child.toggle_turn_indicator_by_id(current_player_id)
		else:
			print("  Not a valid player indicator")
	
	#print("=== Finished Updating Turn Indicators ===\n")

func _on_card_hovered(card_data: Dictionary):
	card_info.set_card_data(card_data)

func update_attacker_label(text: String):
	attacker_label.text = text

func update_defender_label(text: String):
	defender_label.text = text

func validate_attack_cards_limit() -> bool:
	return attack_cards_container.get_child_count() == 0

func can_add_card_to_attack_area() -> bool:
	var action_count = 0
	for child in attack_cards_container.get_children():
		if child.card_data["type"] == "spell":
			action_count += 1
		elif child.card_data["type"] == "cantrip":
			# If it's a combo cantrip (must explicitly have combo=true), don't count it
			# All other cantrips (no combo field or combo=false) should be counted
			if not child.card_data.has("combo") or not child.card_data["combo"]:
				action_count += 1
	return action_count == 0

func can_add_card_to_defense_area() -> bool:
	# Defense area can have unlimited abjuration cards
	return true

func _on_card_clicked(card_data: Dictionary, hand_order_index: int):
	if is_attack_locked:
		return
		
	# Check if this card is already in the attack/defense area
	var container = attack_cards_container if is_player_turn else defend_cards_container
	for child in container.get_children():
		if child.hand_order_index == hand_order_index:
			print("Removing card from area, hand index: ", hand_order_index)
			container.remove_child(child)
			child.queue_free()
			return
		
	if is_player_turn:
		# Handle attack cards (cantrips)
		if card_data["type"] == "cantrip":
			# If it's a combo cantrip, allow it regardless of other cards
			if card_data.has("combo") and card_data["combo"]:
				print("Playing combo cantrip: ", card_data, " at position: ", hand_order_index)
				var card_effect_instance = card_effect.instantiate()
				card_effect_instance.set_card_data(card_data)
				card_effect_instance.hand_order_index = hand_order_index
				add_card_to_attack(card_effect_instance)
				return
				
			# For non-combo cantrips, check if we can add it
			if not can_add_card_to_attack_area():
				print("Cannot play another cantrip, attack area already has a cantrip")
				return
				
			print("Selecting cantrip: ", card_data, " at position: ", hand_order_index)
			var card_effect_instance = card_effect.instantiate()
			card_effect_instance.set_card_data(card_data)
			card_effect_instance.hand_order_index = hand_order_index
			add_card_to_attack(card_effect_instance)
	elif is_targeted:
		# Handle defense cards (abjurations)
		if card_data["type"] == "abjuration":
			print("Selecting abjuration: ", card_data, " at position: ", hand_order_index)
			var card_effect_instance = card_effect.instantiate()
			card_effect_instance.set_card_data(card_data)
			card_effect_instance.hand_order_index = hand_order_index
			add_card_to_defense(card_effect_instance)

func _on_attack_area_button_pressed():
	if is_attack_locked:
		print("Attack area is locked, cannot play cards")
		return
		
	var hand_data = []
	for child in attack_cards_container.get_children():
		hand_data.append(child.card_data)
		
	if hand_data.is_empty():
		print("Empty attack area")
		return
		
	var attack_damage_value = 0
	for card in hand_data:
		if card["type"] == "cantrip":
			attack_damage_value += card["atk"]
			
	print("Attack area cards: ", hand_data)
	print("Total attack damage: ", attack_damage_value)
	
	is_attack_locked = true
	MatchState.lock_in_attack(Globals.STEAM_ID, current_target, hand_data)

func _on_defense_button_pressed():
	if is_defense_locked:
		print("Defense area is locked, cannot play cards")
		return
		
	var hand_data = []
	for child in defend_cards_container.get_children():
		hand_data.append(child.card_data)
		
	if hand_data.is_empty():
		print("Empty defense area")
		return
		
	var defense_block_value = 0
	for card in hand_data:
		if card["type"] == "abjuration":
			defense_block_value += card["def"]
			
	print("Defense area cards: ", hand_data)
	print("Total defense block: ", defense_block_value)
	
	is_defense_locked = true
	MatchState.lock_in_defense(Globals.STEAM_ID, current_target, hand_data)

func update_attack_area_by_attack_lock_in(steam_id: int, target_steam_id: int, hand_data: Array):
	# Update the attacker and defender labels with personalized names
	attacker_label.text = Steam.getFriendPersonaName(steam_id)
	defender_label.text = Steam.getFriendPersonaName(target_steam_id)
	
	# Check if we are the target
	is_targeted = (target_steam_id == Globals.STEAM_ID)
	
	# Clear any existing cards in the attack area
	clear_attack_area()
	
	# Create and add new card effects for each card in hand_data
	for card_data in hand_data:
		var card_effect_instance = card_effect.instantiate()
		card_effect_instance.set_card_data(card_data)
		add_card_to_attack(card_effect_instance)

func _on_update_player_area_with_locked_in_attack(steam_id: int, target_steam_id: int, attack_cards: Array):
	update_attack_area_by_attack_lock_in(steam_id, target_steam_id, attack_cards)

func update_defense_area_by_defense_lock_in(steam_id: int, target_steam_id: int, hand_data: Array):
	# Clear any existing cards in the defense area
	clear_defense_area()
	
	# Create and add new card effects for each card in hand_data
	for card_data in hand_data:
		var card_effect_instance = card_effect.instantiate()
		card_effect_instance.set_card_data(card_data)
		add_card_to_defense(card_effect_instance)

func _on_update_player_area_with_locked_in_defense(steam_id: int, target_steam_id: int, defense_cards: Array):
	update_defense_area_by_defense_lock_in(steam_id, target_steam_id, defense_cards)

func _on_player_updated(player_data: Dictionary):
	print("\n=== Match UI: Processing Player Update ===")
	var target_steam_id = player_data["steam_id"]["steam_id"]
	print("Looking for player with steam_id: ", target_steam_id)
	
	# Search through all children of player_list_container
	for child in player_list_container.get_children():
		# Check if this child has the player_indicator_ui script
		if child.has_method("set_player_id"):
			print("Found player indicator with steam_id: ", child.player_steam_id)
			# If the steam_id matches, update the indicator
			if child.player_steam_id == target_steam_id:
				print("Updating matching player indicator")
				child.update_player_indicator(player_data)
				break
	print("=== Player Update Complete ===\n")
