class_name VisitorFactory
extends RefCounted

const GHOST_CLUES := [
	{
		"clue": "Walked directly through a solid, locked door.",
		"statement": "The entrance was locked, so I walked straight through the solid door without opening it.",
		"explanation": "They passed through a solid door."
	},
	{
		"clue": "Has no reflection in a working mirror.",
		"statement": "The mirror reflected everyone behind me, but it showed no reflection of me at all.",
		"explanation": "They had no reflection."
	},
	{
		"clue": "Their hand passed through a solid table.",
		"statement": "I tried to put my hand on the table, but it passed straight through the solid wood.",
		"explanation": "Their hand passed through solid wood."
	},
	{
		"clue": "Floated above the floor without any support.",
		"statement": "I floated a metre above the floor all the way here, with nothing supporting me.",
		"explanation": "They floated without support."
	}
]

const HUMAN_LINES := [
	"The entrance was locked, so I waited for the receptionist to open it.",
	"I missed my bus and had to walk here. Sorry for being late.",
	"I checked my hair in the mirror before leaving home.",
	"I spilled coffee on my sleeve while eating breakfast.",
	"My phone battery ran out, so I wrote the address on paper.",
    "I left my umbrella on the bus. Now my jacket is soaked."
]


static func create_roster(
	count: int,
	portraits: Array[Texture2D]
) -> Array[VisitorData]:
	var roster: Array[VisitorData] = []

	for i in range(count):
		var visitor := VisitorData.new()

		# Ten visitors gives five ghosts and five humans.
		visitor.is_ghost = i < int(count / 2)

		# All visitors are adults.
		visitor.birth_date = "%04d-%02d-%02d" % [
			randi_range(1960, 2000),
			randi_range(1, 12),
			randi_range(1, 28)
		]

		if not portraits.is_empty():
			visitor.portrait = portraits[randi_range(0, portraits.size() - 1)]

		visitor.situation = "Arriving at a building checkpoint."

		if visitor.is_ghost:
			var entry: Dictionary = GHOST_CLUES[
				randi_range(0, GHOST_CLUES.size() - 1)
			]
			visitor.clue = str(entry["clue"])
			visitor.explanation = str(entry["explanation"])
			visitor.fallback_statement = str(entry["statement"])
		else:
			visitor.explanation = "Their statement described an ordinary situation."
			visitor.fallback_statement = HUMAN_LINES[
				randi_range(0, HUMAN_LINES.size() - 1)
			]

		visitor.statement = visitor.fallback_statement
		roster.append(visitor)

	roster.shuffle()
	return roster
