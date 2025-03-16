extends Control

# Audio player for the backing track, responsible for playing the song
@onready var audio_player = $BackingSong
# MIDI player, responsible for handling MIDI note events
@onready var visualMIDI = $VisualMIDI
# Metronome display and audio
@onready var metronome = $Metronome

func _ready():
	adjust_fall_speed()

	# PLAY AUDIO #
	# MIDI
#	visualMIDI.set_soundfont(Global.soundfont)
#	midi_player.set_file("res://maps/LyricWulfFish.mid")
	visualMIDI.set_file("res://maps/Shelter/LyricWulfShelter.mid")

	# Start playback for audio, MIDI, and metronome
	metronome.start()
#	audio_player.play()
	visualMIDI.play()


# MIDI EVENTS #
# Visuals
func _on_midi_player_midi_event(channel, event):
	# Spawn notes
	match event.type:
		SMF.MIDIEventType.note_on:
			spawnNote(event.note)

	# Output event data to stdout
	if(Global.debug_print):
		var event_string = ""
		match event.type:
			SMF.MIDIEventType.note_off:
				event_string = "NoteOff %d" % event.note
			SMF.MIDIEventType.note_on:
				event_string = "NoteOn note[%d] velocity[%d]" % [ event.note, event.velocity ]
			SMF.MIDIEventType.polyphonic_key_pressure:
				event_string = "PolyphonicKeyPressure note[%d] value[%d]" % [ event.note, event.value ]
			SMF.MIDIEventType.control_change:
				event_string = "ControlChange number[%d] value[%d]" % [ event.number, event.value ]
			SMF.MIDIEventType.program_change:
				event_string = "ProgramChange #%d" % event.number
			SMF.MIDIEventType.pitch_bend:
				event_string = "PitchBend %d -> %f" % [ event.value, ( event.value / 8192.0 ) - 1.0 ]
			SMF.MIDIEventType.channel_pressure:
				event_string = "ChannelPressure %d" % event.value
			SMF.MIDIEventType.system_event:
				event_string = "SystemEvent %d" % event.args.type

		print( channel, event, "channel:%d event-type:%s" % [
		channel.number,
		event_string,
		])

## NOTE VISUALS ##
# Spawning
func spawnNote(note:int) -> void:
	# Load the note scene
	var note_scene = preload("res://scenes/note.tscn")
	var note_instance = note_scene.instantiate()
	add_child(note_instance)

	# Find the key
	var target_key_path:String = "Piano/Oct" + str(Global.octaveOf(note)) + "/Key" + str(note)
	var key: Node = get_node(target_key_path)

	# Put the note where it's supposed to go
	if key:
		var key_center_position = key.global_position + (key.size * 0.25)
		note_instance.position = Vector2(key_center_position.x, 0)
	else:
		push_error("Failed to get key.")

# Note speed is calculated under Map.gd and stored as class variables.
# Note speed is dependent on window size and the distance between the piano and top of the game viewport.
func adjust_fall_speed():
	var piano_node = $Piano
	var pointA = Vector2(0,0)
	var pointB = Vector2(0, piano_node.position.y)
	Map.set_fall_speed(pointA.distance_to(pointB))

func _on_resized() -> void:
	adjust_fall_speed()

## GAME END
func _on_midi_player_finished() -> void:
	get_tree().change_scene_to_file("res://scenes/GameEnd.tscn")
