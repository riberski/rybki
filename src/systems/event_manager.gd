extends Node

# EventManager.gd
# Zarządza dynamicznymi wydarzeniami i eventami czasowymi

signal event_started(event)
signal event_ended(event)

var active_event = null
var events = [
	{"id": "holiday_fish_frenzy", "duration": 3, "desc": "Więcej rzadkich ryb!"},
	{"id": "winter_festival", "duration": 7, "desc": "Unikalne kosmetyki do zdobycia!"}
]

func start_event(event_id):
	for event in events:
		if event["id"] == event_id:
			active_event = event
			emit_signal("event_started", event)
			return

func end_event():
	if active_event:
		emit_signal("event_ended", active_event)
		active_event = null
