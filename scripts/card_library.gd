# CardLibrary.gd
# Singleton responsible for storing and retrieving card data by ID in Warlock Wars

extends Node

# Singleton declaration
func _ready():
	# Ensure this is autoloaded in project settings under "AutoLoad" as "CardLibrary"
	print("CardLibrary initialized")

# Card data stored as a dictionary with IDs as keys
# Each card has: id, name, type, element, atk/def/hp (if applicable), treasure_cost, flux_cost (if applicable), description, and optional special properties
var card_database := {
	# Cantrips (Attack Cards)
	"001": {
		"id": "001",
		"name": "Arcane Bolt",
		"type": "cantrip",
		"element": "Non-element",
		"atk": 14,
		"treasure_cost": 5,  # All cards now have a treasure cost
		"flux_cost": 0,      # Cantrips typically don't use Flux
		"description": "Deals 14 damage to a target."
	},
	"002": {
		"id": "002",
		"name": "Fire Lance",
		"type": "cantrip",
		"element": "Fire",
		"atk": 10,
		"treasure_cost": 4,
		"flux_cost": 0,
		"description": "Deals 10 Fire damage to a target."
	},
	"003": {
		"id": "003",
		"name": "Combo Strike",
		"type": "cantrip",
		"element": "Non-element",
		"atk": 3,
		"treasure_cost": 2,
		"flux_cost": 0,
		"description": "Adds +3 ATK to another cantrip this turn.",
		"combo": true  # Special property for combo cards
	},

	# Abjuration (Defense Cards)
	"004": {
		"id": "004",
		"name": "Circle of Protection",
		"type": "abjuration",
		"element": "Non-element",
		"def": 5,
		"treasure_cost": 3,
		"flux_cost": 0,
		"description": "Blocks 5 damage from an attack."
	},
	"005": {
		"id": "005",
		"name": "Water Shield",
		"type": "abjuration",
		"element": "Water",
		"def": 8,
		"treasure_cost": 4,
		"flux_cost": 0,
		"description": "Blocks 8 damage from a Fire attack."
	},

	# Magic Items
	"006": {
		"id": "006",
		"name": "Illustrious Gem",
		"type": "magic_item",
		"element": "Non-element",
		"atk": 1,
		"treasure_cost": 25,
		"flux_cost": 0,
		"description": "Deals 1 damage or can be sold to another player."
	},
	"007": {
		"id": "007",
		"name": "Healing Salve",
		"type": "magic_item",
		"element": "Non-element",
		"treasure_cost": 5,
		"flux_cost": 0,
		"description": "Restores 10 Vigor to the user."
	},

	# Spell Cards
	"008": {
		"id": "008",
		"name": "Invisibility",
		"type": "spell",
		"element": "Non-element",
		"treasure_cost": 3,
		"flux_cost": 6,  # Spells have both treasure and flux costs
		"description": "Grants immunity to the next attack this game."
	},
	"009": {
		"id": "009",
		"name": "Necrotic Touch",
		"type": "spell",
		"element": "Necromancy",
		"atk": 5,
		"treasure_cost": 2,
		"flux_cost": 4,
		"description": "Deals 5 damage and applies or worsens a Curse."
	},

	# Deck Manipulation Cards
	"010": {
		"id": "010",
		"name": "Scry",
		"type": "spell",
		"element": "Non-element",
		"treasure_cost": 1,
		"flux_cost": 2,
		"description": "Look at the top 3 cards of the deck and reorder them."
	},

	# Summon Cards
	"011": {
		"id": "011",
		"name": "Iron Golem",
		"type": "summon",
		"element": "Earth",
		"hp": 10,
		"treasure_cost": 5,
		"flux_cost": 8,
		"description": "Reduces incoming damage by 10 while active. Acts independently 25% of the time.",
		"independent_chance": 0.25
	},

	# Curse Cards
	"012": {
		"id": "012",
		"name": "Curse of Pain",
		"type": "curse",
		"element": "Non-element",
		"damage": 20,
		"treasure_cost": 0,  # Curse cards auto-activate, so no play cost
		"flux_cost": 0,
		"description": "Deals 20 damage to the drawer immediately."
	},
	"013": {
		"id": "013",
		"name": "Elixir of Life",
		"type": "curse",
		"element": "Non-element",
		"treasure_cost": 0,
		"flux_cost": 0,
		"description": "Grants 10 Vigor, 10 Arcane Flux, and 10 Treasure to the drawer."
	},

	# Equipment Cards
	"014": {
		"id": "014",
		"name": "Amulet of Power",
		"type": "equipment",
		"element": "Non-element",
		"hp": 5,
		"treasure_cost": 5,
		"flux_cost": 0,
		"description": "Increases all ATK values by 2 while equipped."
	},

	# Wish Cards
	"015": {
		"id": "015",
		"name": "Warlock Wars",
		"type": "wish",
		"element": "Non-element",
		"treasure_cost": 10,
		"flux_cost": 0,
		"description": "Triggers a random global effect (e.g., 5 damage to all players)."
	},

	# Lich-Specific Card
	"016": {
		"id": "016",
		"name": "Lich Shield",
		"type": "magic_item",
		"element": "Necromancy",
		"treasure_cost": 10,
		"flux_cost": 0,
		"description": "Blocks one instance of Divine Wrath. Single-use."
	}
}

# Function to retrieve card data by ID
func get_card_data(card_id: String) -> Dictionary:
	# Returns the card's data dictionary if found, otherwise an empty dictionary
	if card_id in card_database:
		return card_database[card_id]
	else:
		printerr("Card ID not found: ", card_id)
		return {}

# Optional: Function to get all card IDs (useful for deck generation)
func get_all_card_ids() -> Array:
	return card_database.keys()
