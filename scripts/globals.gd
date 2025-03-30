extends Node
#Steam Variables
var OWNED = false
var ONLINE = false
var STEAM_ID = 0
var STEAM_NAME = ""
var APP_ID = "3121430"
#Lobby Variables
var DATA
var LOBBY_ID = 0
var LOBBY_MEMBERS = []
var LOBBY_INVITE_ARG = false

func _ready():
	#Set steam variables
	OS.set_environment("SteamAppId", APP_ID)
	OS.set_environment("SteamGameId", APP_ID)
	
	#Initialize steam
	var INIT = Steam.steamInit()
	print(INIT)
	
	# Check initialization status (0 = success in Godot 4.4, not 1)
	if INIT['status'] != 1:
		print("Failed to initialize Steam. " + str(INIT['verbal']) + "Shutting down...")
		get_tree().quit()
	
	# Steam is initialzed set up core variables
	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	OWNED = Steam.isSubscribed()
	
	print("Steam ID: %d, Name: %s, Online: %s, Owned: %s" % [STEAM_ID, STEAM_NAME, ONLINE, OWNED])
	
	if OWNED == false:
		print("User does not own this game. Shutting down...")
		get_tree().quit()
	
	# Enable P2P packet relay
	Steam.allowP2PPacketRelay(true)
	print("P2P packet relay enabled %s" % Steam.allowP2PPacketRelay(true))

func _process(_delta):
	Steam.run_callbacks()
