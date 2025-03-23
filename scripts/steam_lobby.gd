extends Control

enum lobby_status {Private, Friends, Public, Invisible}
enum search_distance {Close, Default, Far, Worldwide}

@onready var steamName = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/SteamName
@onready var lobbySetName = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/TextEdit
@onready var lobbyGetName = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/LobbyName
@onready var lobbyPlayerCount = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer/Players/VBoxContainer/Label
@onready var lobbyOutput = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer/Players/VBoxContainer/RichTextLabel
@onready var lobbyPanel = $LobbyPanel
@onready var lobbySearch = $FindLobbyPanel
@onready var lobbyList = $FindLobbyPanel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var chatInput = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/TextEdit
@onready var chatOutput = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/RichTextLabel

func _ready():
	#Set Steam Name
	steamName.text = Globals.STEAM_NAME
	#Steamwork Connections
	Steam.lobby_created.connect(_on_Lobby_Created)
	#Steam.lobby_match_list.connect(_on_Lobby_Match_List)
	#Steam.lobby_joined.connect(_on_Lobby_Joined)
	#Steam.lobby_chat_update.connect(_on_Lobby_Chat_Update)
	#Steam.lobby_message.connect(_on_Lobby_Message)
	#Steam.lobby_data_update.connect(_on_Lobby_Data_Update)
	#Steam.join_requested.connect(_on_Lobby_Join_Requested)
	
	check_Command_Line()
	
func create_Lobby():
	#Check no other Lobby is running
	if Globals.LOBBY_ID == 0:
		Steam.createLobby(lobby_status.Public,12)

func display_Message(message):
	chatOutput.add_text("\n" + str(message))

func _on_Lobby_Created(connect_status, lobbyID):
	if connect_status == 1:
		Globals.LOBBY_ID = lobbyID
		display_Message("Created lobby: " + lobbySetName.text)
		
		#Set Lobby Data
		Steam.setLobbyData(lobbyID, "name", lobbySetName.text)
		var lobby_name = Steam.getLobbyData(lobbyID, "name")
		lobbyGetName.text = str(lobby_name)
	
	
func check_Command_Line():
	var ARGUMENTS = OS.get_cmdline_args()
	
	if ARGUMENTS.size() > 0:
		for argument in ARGUMENTS:
			#Invite argument passed
			if Globals.LOBBY_INVITE_ARG:
				pass
				#join_Lobby(int(argument))
			
			#Steam connection argument
			if argument == "+connect_lobby":
				Globals.LOBBY_INVITE_ARG = true
	

func _on_create_lobby_pressed():
	if lobbySetName.text == "":
		lobbySetName.text = ""+steamName.text+"'s Lobby" 
		create_Lobby()
	else:
		create_Lobby()
	lobbySetName.text = ""
	
func _on_join_lobby_pressed():
	pass # Replace with function body.
	
func _on_leave_lobby_pressed():
	pass # Replace with function body.
	
func _on_start_game_pressed():
	pass # Replace with function body.
	
func _on_send_message_pressed():
	pass # Replace with function body.

func _on_lobby_search_exit_button_pressed():
	pass # Replace with function body.
