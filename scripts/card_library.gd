# CardLibrary.gd
# Singleton responsible for storing and retrieving card data by ID in Warlock Wars
#
# Card Structure:
# All cards share a common base structure with the following fields:
#   - id: String - Unique identifier for the card
#   - name: String - Display name of the card
#   - type: String - Card type (cantrip, abjuration, magic_item, spell, summon, curse, equipment, wish)
#   - element: String - Elemental affinity (Non-element, Fire, Water, Earth, Air, Necromancy, Holy)
#   - treasure_cost: int - Cost in treasure to buy or sell the card
#   - flux_cost: int - Cost in arcane flux to play the card
#   - description: String - Card effect description
#   - texture_path: String - Path to the card's texture (optional)
#   - rarity: Rarity - Card rarity (DEFAULT, COMMON, RARE, LEGENDARY)
#
# Type-specific fields:
#   Cantrips:
#     - atk: int - Attack damage value
#     - combo: bool (optional) - Whether the card can combo with other cantrips
#
#   Abjuration:
#     - def: int - Defense value
#
#   Magic Items:
#     - atk: int (optional) - Attack damage if applicable
#     - hp: int (optional) - Health points if applicable
#
#   Spells:
#     - atk: int (optional) - Attack damage if applicable
#
#   Summons:
#     - hp: int - Health points
#     - independent_chance: float - Chance to act independently
#
#   Curses:
#     - damage: int (optional) - Damage dealt when drawn
#
#   Equipment:
#     - hp: int (optional) - Health points if applicable
#
#   Wish:
#     - No additional fields
#
# Steam Inventory Override Cards:
#   - override_id: String - ID of the default card this version overrides

extends Node

enum Rarity {
	DEFAULT,
	COMMON,
	RARE,
	LEGENDARY
}

# Dictionary to store all cards, key = card_id, value = card_data
var card_dict: Dictionary = {}

# Default set of cards
var default_cards := {
	# Cantrips (Attack Cards)
	"001": {
		"id": "001",
		"name": "Arcane Bolt",
		"type": "cantrip",
		"element": "Non-element",
		"atk": 10,
		"treasure_cost": 1,
		"flux_cost": 0,
		"description": "Deals 10 damage to a target.",
		"texture_path": "res://assets/textures/cantrips/arcane_bolt.png",
		"rarity": Rarity.DEFAULT
	}
}

# Called when the Singleton is initialized
func _ready():
	# Ensure this is autoloaded in project settings under "AutoLoad" as "CardLibrary"
	print("CardLibrary initialized")
	# Initialize with default cards
	_initialize_default_cards()
	# Load Steam inventory cards
	_load_steam_inventory_cards()

# Initialize the default card set
func _initialize_default_cards():
	for card_id in default_cards.keys():
		card_dict[card_id] = default_cards[card_id]

# Placeholder function to load cards from Steam inventory
func _load_steam_inventory_cards():
	var steam_cards = _fetch_steam_inventory()
	for card_id in steam_cards.keys():
		card_dict[card_id] = steam_cards[card_id]

# Simulated Steam inventory fetch
func _fetch_steam_inventory() -> Dictionary:
	# Example Steam inventory cards that override default cards
	return {
		"001_common": {
			"id": "001_common",
			"name": "Arcane Bolt",
			"type": "cantrip",
			"element": "Non-element",
			"atk": 10,
			"treasure_cost": 1,
			"flux_cost": 0,
			"description": "Deals 10 damage to a target.",
			"texture_path": "res://assets/textures/cantrips/arcane_bolt.png",
			"rarity": Rarity.COMMON,
			"override_id": "001"  # This indicates it overrides the default Arcane Bolt
		},
		"001_rare": {
			"id": "001_rare",
			"name": "Arcane Bolt",
			"type": "cantrip",
			"element": "Non-element",
			"atk": 10,
			"treasure_cost": 1,
			"flux_cost": 0,
			"description": "Deals 10 damage to a target.",
			"texture_path": "res://assets/textures/cantrips/arcane_bolt.png",
			"rarity": Rarity.RARE,
			"override_id": "001"  # This indicates it overrides the default Arcane Bolt
		},
		"001_legendary": {
			"id": "001_legendary",
			"name": "Arcane Bolt",
			"type": "cantrip",
			"element": "Non-element",
			"atk": 10,
			"treasure_cost": 1,
			"flux_cost": 0,
			"description": "Deals 10 damage to a target.",
			"texture_path": "res://assets/textures/cantrips/arcane_bolt.png",
			"rarity": Rarity.LEGENDARY,
			"override_id": "001"  # This indicates it overrides the default Arcane Bolt
		}
	}

# Function to retrieve card data by ID
func get_card_data(card_id: String) -> Dictionary:
	if card_id in card_dict:
		return card_dict[card_id]
	else:
		printerr("Card ID not found: ", card_id)
		return {}

# Function to get all card IDs
func get_all_card_ids() -> Array:
	return card_dict.keys()

# Function to get all available cards
func get_all_cards() -> Dictionary:
	return card_dict.duplicate() # Return a copy to prevent modification
