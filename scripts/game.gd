extends Control

enum State {
	PREPARING,
	INSPECTING,
	FEEDBACK,
	FINISHED
}

@export_group("Game UI")
@export var visitor_card: VisitorCard
@export var accept_button: Button
@export var reject_button: Button
@export var score_label: Label
@export var round_label: Label
@export var time_label: Label
@export var feedback_label: Label

@export_group("Results UI")
@export var results_panel: PanelContainer
@export var final_score_label: Label
@export var restart_button: Button

@export_group("Loading UI - Optional")
@export var loading_panel: Control
@export var loading_label: Label

@export_group("Portraits")
@export var portraits: Array[Texture2D] = []

@export_group("Local AI")
@export var use_ai: bool = false
@export var ai_endpoint: String = ""
@export var ai_model: String = ""
@export var ai_api_key: String = ""
@export var ai_timeout: float = 20.0

const TOTAL_VISITORS := 10
const POINTS_PER_CORRECT := 100
const DECISION_SECONDS := 15.0
const FEEDBACK_SECONDS := 1.0

var state: State = State.PREPARING
var visitors: Array[VisitorData] = []
var current_index: int = -1
var score: int = 0

var decision_timer: Timer
var feedback_timer: Timer
var ai_client: LocalAIClient


func _ready() -> void:
	if not _validate_ui():
		return

	decision_timer = _get_or_create_timer("DecisionTimer")
	feedback_timer = _get_or_create_timer("FeedbackTimer")

	decision_timer.one_shot = true
	feedback_timer.one_shot = true
	decision_timer.stop()
	feedback_timer.stop()

	ai_client = LocalAIClient.new()
	add_child(ai_client)

	# Avoid duplicating your existing editor signal connections.
	if not accept_button.pressed.is_connected(
		_on_accept_button_pressed
	):
		accept_button.pressed.connect(_on_accept_button_pressed)

	if not reject_button.pressed.is_connected(
		_on_reject_button_pressed
	):
		reject_button.pressed.connect(_on_reject_button_pressed)

	if not restart_button.pressed.is_connected(
		_on_restart_button_pressed
	):
		restart_button.pressed.connect(_on_restart_button_pressed)

	if not decision_timer.timeout.is_connected(
		_on_decision_timer_timeout
	):
		decision_timer.timeout.connect(_on_decision_timer_timeout)

	if not feedback_timer.timeout.is_connected(
		_on_feedback_timer_timeout
	):
		feedback_timer.timeout.connect(_on_feedback_timer_timeout)

	start_game()


func _process(_delta: float) -> void:
	if state == State.INSPECTING:
		time_label.text = "Time: %d" % int(
			ceil(decision_timer.time_left)
		)

func start_game() -> void:
	state = State.PREPARING
	decision_timer.stop()
	feedback_timer.stop()

	score = 0
	current_index = -1

	results_panel.hide()
	visitor_card.hide()
	_set_buttons_enabled(false)
	restart_button.disabled = true

	feedback_label.text = ""
	score_label.text = "Score: 0"
	round_label.text = "Visitor: 0 / %d" % TOTAL_VISITORS
	time_label.text = "Time: --"

	if loading_panel != null:
		loading_panel.hide()

	visitors = VisitorFactory.create_roster(
		TOTAL_VISITORS,
		portraits
	)

	ai_client.endpoint = ai_endpoint
	ai_client.model_name = ai_model
	ai_client.api_key = ai_api_key
	ai_client.request_timeout = ai_timeout
	ai_client.server_available = true

	# No generation loop here.
	show_next_visitor()

func show_next_visitor() -> void:
	state = State.PREPARING
	decision_timer.stop()
	feedback_timer.stop()
	_set_buttons_enabled(false)

	current_index += 1

	if current_index >= visitors.size():
		finish_game()
		return

	visitor_card.hide()

	round_label.text = "Visitor: %d / %d" % [
		current_index + 1,
		TOTAL_VISITORS
	]
	time_label.text = "Time: --"
	feedback_label.text = "Preparing visitor..."

	if loading_label != null:
		loading_label.text = "Preparing visitor..."

	if loading_panel != null:
		loading_panel.show()

	var visitor: VisitorData = visitors[current_index]

	# Defaults to prepared dialogue.
	visitor.statement = visitor.fallback_statement

	# After repeated API failures, server_available becomes false.
	# Remaining visitors then use prepared dialogue without waiting.
	if use_ai and ai_client.server_available:
		visitor.statement = await ai_client.generate_statement(visitor)

	if loading_panel != null:
		loading_panel.hide()

	visitor_card.show_visitor(visitor)
	visitor_card.show()

	feedback_label.text = ""
	time_label.text = "Time: %d" % int(DECISION_SECONDS)

	state = State.INSPECTING
	_set_buttons_enabled(true)
	decision_timer.start(DECISION_SECONDS)

	print(
		"Visitor %d ready. AI generated: %s" % [
			current_index + 1,
			str(visitor.generated_by_ai)
		]
	)

func resolve_decision(accepted: bool) -> void:
	if state != State.INSPECTING:
		return

	# Lock the decision before changing the score.
	state = State.FEEDBACK
	decision_timer.stop()
	_set_buttons_enabled(false)

	var visitor: VisitorData = visitors[current_index]
	var correct: bool = accepted == (not visitor.is_ghost)
	var identity := "Ghost" if visitor.is_ghost else "Human"

	if correct:
		score += POINTS_PER_CORRECT

	score_label.text = "Score: %d" % score

	var outcome := "Correct! +100" if correct else "Wrong! +0"

	feedback_label.text = "%s — %s. %s" % [
		outcome,
		identity,
		visitor.explanation
	]

	feedback_timer.start(FEEDBACK_SECONDS)


func _on_decision_timer_timeout() -> void:
	if state != State.INSPECTING:
		return

	state = State.FEEDBACK
	_set_buttons_enabled(false)
	time_label.text = "Time: 0"

	var visitor: VisitorData = visitors[current_index]
	var identity := "Ghost" if visitor.is_ghost else "Human"

	feedback_label.text = "Time's up! +0 — %s. %s" % [
		identity,
		visitor.explanation
	]

	feedback_timer.start(FEEDBACK_SECONDS)


func finish_game() -> void:
	state = State.FINISHED
	decision_timer.stop()
	feedback_timer.stop()
	_set_buttons_enabled(false)

	visitor_card.hide()
	feedback_label.text = ""
	time_label.text = "Time: --"

	var correct_count := int(score / POINTS_PER_CORRECT)

	final_score_label.text = (
        "Final score: %d / %d\nCorrect decisions: %d / %d"
		% [
			score,
			TOTAL_VISITORS * POINTS_PER_CORRECT,
			correct_count,
			TOTAL_VISITORS
		]
	)

	restart_button.disabled = false
	results_panel.show()


func _on_accept_button_pressed() -> void:
	resolve_decision(true)

func _on_reject_button_pressed() -> void:
	resolve_decision(false)

func _on_feedback_timer_timeout() -> void:
	if state == State.FEEDBACK:
		show_next_visitor()


func _on_restart_button_pressed() -> void:
	if state == State.FINISHED:
		start_game()


func _set_buttons_enabled(enabled: bool) -> void:
	accept_button.disabled = not enabled
	reject_button.disabled = not enabled


func _get_or_create_timer(node_name: String) -> Timer:
	var timer := get_node_or_null(NodePath(node_name)) as Timer

	if timer == null:
		timer = Timer.new()
		timer.name = node_name
		add_child(timer)

	return timer


func _validate_ui() -> bool:
	var required := {
		"Visitor Card": visitor_card,
		"Accept Button": accept_button,
		"Reject Button": reject_button,
		"Score Label": score_label,
		"Round Label": round_label,
		"Time Label": time_label,
		"Feedback Label": feedback_label,
		"Results Panel": results_panel,
		"Final Score Label": final_score_label,
		"Restart Button": restart_button
	}

	var valid := true

	for field in required:
		if required[field] == null:
			push_error("Game Inspector: assign '%s'." % field)
			valid = false

	return valid
