# CardLibrary.gd
# Singleton responsible for storing and retrieving card data by ID in Warlock Wars
#
# Card Structure:
# All cards share a common base structure with the following fields:
#   - id: String - Unique identifier for the card
#   - name: String - Display name of the card
#   - type: String - Card type (cantrip, abjuration, magic_item, spell, summon, curse, equipment, wish)
#   - element: String - Elemental affinity (Non-element, Fire, Water, Earth, Necromancy)
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
	},
	# "002": {
	# 	"id": "002",
	# 	"name": "Fire Lance",
	# 	"type": "cantrip",
	# 	"element": "Fire",
	# 	"atk": 10,
	# 	"treasure_cost": 4,
	# 	"flux_cost": 0,
	# 	"description": "Deals 10 Fire damage to a target.",
	# 	"texture_path": "",
	# 	"rarity": Rarity.DEFAULT
	# },
	# "003": {
	# 	"id": "003",
	# 	"name": "Combo Strike",
	# 	"type": "cantrip",
	# 	"element": "Non-element",
	# 	"atk": 3,
	# 	"treasure_cost": 2,
	# 	"flux_cost": 0,
	# 	"description": "Adds +3 ATK to another cantrip this turn.",
	# 	"combo": true,
	# 	"texture_path": "",
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Abjuration (Defense Cards)
	# "004": {
	# 	"id": "004",
	# 	"name": "Circle of Protection",
	# 	"type": "abjuration",
	# 	"element": "Non-element",
	# 	"def": 5,
	# 	"treasure_cost": 3,
	# 	"flux_cost": 0,
	# 	"description": "Blocks 5 damage from an attack.",
	# 	"rarity": Rarity.DEFAULT
	# },
	# "005": {
	# 	"id": "005",
	# 	"name": "Water Shield",
	# 	"type": "abjuration",
	# 	"element": "Water",
	# 	"def": 8,
	# 	"treasure_cost": 4,
	# 	"flux_cost": 0,
	# 	"description": "Blocks 8 damage from a Fire attack.",
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Magic Items
	# "006": {
	# 	"id": "006",
	# 	"name": "Illustrious Gem",
	# 	"type": "magic_item",
	# 	"element": "Non-element",
	# 	"atk": 1,
	# 	"treasure_cost": 25,
	# 	"flux_cost": 0,
	# 	"description": "Deals 1 damage or can be sold to another player.",
	# 	"rarity": Rarity.DEFAULT
	# },
	# "007": {
	# 	"id": "007",
	# 	"name": "Healing Salve",
	# 	"type": "magic_item",
	# 	"element": "Non-element",
	# 	"treasure_cost": 5,
	# 	"flux_cost": 0,
	# 	"description": "Restores 10 Vigor to the user.",
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Spell Cards
	# "008": {
	# 	"id": "008",
	# 	"name": "Invisibility",
	# 	"type": "spell",
	# 	"element": "Non-element",
	# 	"treasure_cost": 3,
	# 	"flux_cost": 6,  # Spells have both treasure and flux costs
	# 	"description": "Grants immunity to the next attack this game.",
	# 	"rarity": Rarity.DEFAULT
	# },
	# "009": {
	# 	"id": "009",
	# 	"name": "Necrotic Touch",
	# 	"type": "spell",
	# 	"element": "Necromancy",
	# 	"atk": 5,
	# 	"treasure_cost": 2,
	# 	"flux_cost": 4,
	# 	"description": "Deals 5 damage and applies or worsens a Curse.",
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Deck Manipulation Cards
	# "010": {
	# 	"id": "010",
	# 	"name": "Scry",
	# 	"type": "spell",
	# 	"element": "Non-element",
	# 	"treasure_cost": 1,
	# 	"flux_cost": 2,
	# 	"description": "Look at the top 3 cards of the deck and reorder them.",
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Summon Cards
	# "011": {
	# 	"id": "011",
	# 	"name": "Iron Golem",
	# 	"type": "summon",
	# 	"element": "Earth",
	# 	"hp": 10,
	# 	"treasure_cost": 5,
	# 	"flux_cost": 8,
	# 	"description": "Reduces incoming damage by 10 while active. Acts independently 25% of the time.",
	# 	"independent_chance": 0.25,
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Curse Cards
	# "012": {
	# 	"id": "012",
	# 	"name": "Curse of Pain",
	# 	"type": "curse",
	# 	"element": "Non-element",
	# 	"damage": 20,
	# 	"treasure_cost": 0,  # Curse cards auto-activate, so no play cost
	# 	"flux_cost": 0,
	# 	"description": "Deals 20 damage to the drawer immediately.",
	# 	"rarity": Rarity.DEFAULT
	# },
	# "013": {
	# 	"id": "013",
	# 	"name": "Elixir of Life",
	# 	"type": "curse",
	# 	"element": "Non-element",
	# 	"treasure_cost": 0,
	# 	"flux_cost": 0,
	# 	"description": "Grants 10 Vigor, 10 Arcane Flux, and 10 Treasure to the drawer.",
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Equipment Cards
	# "014": {
	# 	"id": "014",
	# 	"name": "Amulet of Power",
	# 	"type": "equipment",
	# 	"element": "Non-element",
	# 	"hp": 5,
	# 	"treasure_cost": 5,
	# 	"flux_cost": 0,
	# 	"description": "Increases all ATK values by 2 while equipped.",
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Wish Cards
	# "015": {
	# 	"id": "015",
	# 	"name": "Warlock Wars",
	# 	"type": "wish",
	# 	"element": "Non-element",
	# 	"treasure_cost": 10,
	# 	"flux_cost": 0,
	# 	"description": "Triggers a random global effect (e.g., 5 damage to all players).",
	# 	"rarity": Rarity.DEFAULT
	# },

	# # Lich-Specific Card
	# "016": {
	# 	"id": "016",
	# 	"name": "Lich Shield",
	# 	"type": "magic_item",
	# 	"element": "Necromancy",
	# 	"treasure_cost": 10,
	# 	"flux_cost": 0,
	# 	"description": "Blocks one instance of Divine Wrath. Single-use.",
	# 	"texture_path": "",
	# 	"rarity": Rarity.DEFAULT
	# }
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
