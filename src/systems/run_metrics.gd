extends Node

const METRICS_PATH := "user://run_metrics.json"
const MAX_HISTORY_SESSIONS := 30

var metrics: Dictionary = {}
var active_session: Dictionary = {}

func _ready() -> void:
	_load_metrics()

func _default_metrics() -> Dictionary:
	return {
		"version": 1,
		"totals": {
			"sessions_started": 0,
			"sessions_completed": 0,
			"total_playtime_seconds": 0,
			"runs_started": 0,
			"runs_completed": 0,
			"days_advanced": 0,
			"casts": 0,
			"bites": 0,
			"hooks": 0,
			"catches": 0,
			"losses": 0,
			"bait_spent": 0,
			"expeditions_started": 0,
			"expeditions_successful": 0,
			"expeditions_failed": 0,
			"run_end_reasons": {},
			"extraction_end_reasons": {}
		},
		"last_session": {},
		"history": []
	}

func _new_session(entrypoint: String) -> Dictionary:
	var started_unix := int(Time.get_unix_time_from_system())
	return {
		"id": "%d-%d" % [started_unix, randi_range(1000, 9999)],
		"entrypoint": entrypoint,
		"started_unix": started_unix,
		"ended_unix": 0,
		"duration_seconds": 0,
		"session_end_reason": "",
		"run_active": false,
		"run_end_reason": "",
		"runs_started": 0,
		"runs_completed": 0,
		"max_day_reached": 0,
		"last_quota_target": 0,
		"casts": 0,
		"bites": 0,
		"hooks": 0,
		"catches": 0,
		"losses": 0,
		"bait_spent": 0,
		"expeditions_started": 0,
		"expeditions_successful": 0,
		"expeditions_failed": 0,
		"last_extraction_reason": ""
	}

func _load_metrics() -> void:
	metrics = _default_metrics()
	if not FileAccess.file_exists(METRICS_PATH):
		_persist()
		return

	var file := FileAccess.open(METRICS_PATH, FileAccess.READ)
	if file == null:
		return

	var raw := file.get_as_text()
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		metrics = _merge_defaults(parsed)
	else:
		metrics = _default_metrics()
		_persist()

func _merge_defaults(existing: Dictionary) -> Dictionary:
	var merged := _default_metrics()
	for key in existing.keys():
		merged[key] = existing[key]

	if not merged["totals"] is Dictionary:
		merged["totals"] = _default_metrics()["totals"]

	var default_totals: Dictionary = _default_metrics()["totals"]
	for key in default_totals.keys():
		if not merged["totals"].has(key):
			merged["totals"][key] = default_totals[key]

	if not merged["history"] is Array:
		merged["history"] = []

	if not merged["last_session"] is Dictionary:
		merged["last_session"] = {}

	return merged

func _persist() -> void:
	var file := FileAccess.open(METRICS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(metrics, "\t"))

func _inc_total(key: String, delta: int = 1) -> void:
	var totals: Dictionary = metrics.get("totals", {})
	totals[key] = int(totals.get(key, 0)) + delta
	metrics["totals"] = totals

func _inc_total_reason(bucket: String, reason: String) -> void:
	if reason.is_empty():
		reason = "unknown"
	var totals: Dictionary = metrics.get("totals", {})
	if not totals.has(bucket) or not totals[bucket] is Dictionary:
		totals[bucket] = {}
	var dict: Dictionary = totals[bucket]
	dict[reason] = int(dict.get(reason, 0)) + 1
	totals[bucket] = dict
	metrics["totals"] = totals

func _inc_session(key: String, delta: int = 1) -> void:
	if active_session.is_empty():
		start_session("implicit")
	active_session[key] = int(active_session.get(key, 0)) + delta

func start_session(entrypoint: String) -> void:
	if not active_session.is_empty():
		end_session("restarted")
	active_session = _new_session(entrypoint)
	_inc_total("sessions_started", 1)
	_persist()

func end_session(reason: String = "manual") -> void:
	if active_session.is_empty():
		return
	var ended_unix := int(Time.get_unix_time_from_system())
	var started_unix := int(active_session.get("started_unix", ended_unix))
	var duration: int = maxi(0, ended_unix - started_unix)
	active_session["ended_unix"] = ended_unix
	active_session["duration_seconds"] = duration
	active_session["session_end_reason"] = reason
	active_session["run_active"] = false

	metrics["last_session"] = active_session.duplicate(true)
	var history: Array = metrics.get("history", [])
	history.append(metrics["last_session"])
	while history.size() > MAX_HISTORY_SESSIONS:
		history.remove_at(0)
	metrics["history"] = history

	_inc_total("sessions_completed", 1)
	_inc_total("total_playtime_seconds", duration)
	active_session.clear()
	_persist()

func record_run_started() -> void:
	if active_session.is_empty():
		start_session("implicit")
	if not bool(active_session.get("run_active", false)):
		active_session["run_active"] = true
		active_session["run_end_reason"] = ""
		_inc_session("runs_started", 1)
		_inc_total("runs_started", 1)
		_persist()

func record_run_ended(reason: String) -> void:
	if active_session.is_empty():
		return
	if bool(active_session.get("run_active", false)):
		active_session["run_active"] = false
		active_session["run_end_reason"] = reason
		_inc_session("runs_completed", 1)
		_inc_total("runs_completed", 1)
		_inc_total_reason("run_end_reasons", reason)
		_persist()

func record_day_advanced(day: int, quota_target: int = 0) -> void:
	if active_session.is_empty():
		start_session("implicit")
	active_session["max_day_reached"] = max(int(active_session.get("max_day_reached", 0)), day)
	active_session["last_quota_target"] = quota_target
	_inc_total("days_advanced", 1)
	_persist()

func record_cast() -> void:
	_inc_session("casts", 1)
	_inc_total("casts", 1)
	_persist()

func record_bite() -> void:
	_inc_session("bites", 1)
	_inc_total("bites", 1)
	_persist()

func record_hook() -> void:
	_inc_session("hooks", 1)
	_inc_total("hooks", 1)
	_persist()

func record_catch() -> void:
	_inc_session("catches", 1)
	_inc_total("catches", 1)
	_persist()

func record_loss() -> void:
	_inc_session("losses", 1)
	_inc_total("losses", 1)
	_persist()

func record_bait_spent(amount: int = 1) -> void:
	if amount <= 0:
		return
	_inc_session("bait_spent", amount)
	_inc_total("bait_spent", amount)
	_persist()

func record_expedition_started() -> void:
	_inc_session("expeditions_started", 1)
	_inc_total("expeditions_started", 1)
	_persist()

func record_expedition_finished(reason: String) -> void:
	if active_session.is_empty():
		start_session("implicit")
	active_session["last_extraction_reason"] = reason
	if reason == "zone_extract":
		_inc_session("expeditions_successful", 1)
		_inc_total("expeditions_successful", 1)
	else:
		_inc_session("expeditions_failed", 1)
		_inc_total("expeditions_failed", 1)
	_inc_total_reason("extraction_end_reasons", reason)
	_persist()

func get_summary() -> Dictionary:
	var totals: Dictionary = metrics.get("totals", {})
	var casts: int = maxi(1, int(totals.get("casts", 0)))
	var bites: int = maxi(1, int(totals.get("bites", 0)))
	var hooks: int = maxi(1, int(totals.get("hooks", 0)))
	var expeditions: int = maxi(1, int(totals.get("expeditions_started", 0)))
	return {
		"totals": totals,
		"last_session": metrics.get("last_session", {}),
		"hook_rate": float(totals.get("hooks", 0)) / float(casts),
		"catch_rate_from_bites": float(totals.get("catches", 0)) / float(bites),
		"catch_rate_from_hooks": float(totals.get("catches", 0)) / float(hooks),
		"expedition_success_rate": float(totals.get("expeditions_successful", 0)) / float(expeditions)
	}
