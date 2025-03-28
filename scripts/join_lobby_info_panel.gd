extends HBoxContainer

@onready var lobby_info_label = $lobby_info_label

var LOBBY_JOIN_ID: int = 0

signal lobby_search_panel_join_request(lobby_id:int)

func join_button_setup(lobby_id):
	#Grab desired lobby data
	var LOBBY_NAME = Steam.getLobbyData(lobby_id, "name")
	# Get the current number of members
	var LOBBY_MEMBERS = Steam.getNumLobbyMembers(lobby_id)
	
	lobby_info_label.set_text("Lobby Name: " + str(LOBBY_NAME) + "\nPlayers:(" + str(LOBBY_MEMBERS) + "/12)")
	LOBBY_JOIN_ID = lobby_id
	
func _on_join_lobby_button_pressed():
	lobby_search_panel_join_request.emit(LOBBY_JOIN_ID)
