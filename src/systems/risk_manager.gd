extends Node

signal risk_changed(risk_level: float, components: Dictionary)

var risk_level: float = 0.0
var loot_value_component: float = 0.0
var time_component: float = 0.0
var weather_component: float = 0.0
var player_density_component: float = 0.0

var _last_reported_level: float = -1.0

func _process(_delta: float) -> void:
	if TimeManager == null or not TimeManager.extraction_active:
		if risk_level != 0.0:
			_reset_risk()
		return

	_recalculate_risk()

func _reset_risk() -> void:
	risk_level = 0.0
	loot_value_component = 0.0
	time_component = 0.0
	weather_component = 0.0
	player_density_component = 0.0
	_last_reported_level = -1.0
	risk_changed.emit(risk_level, get_risk_components())

func _recalculate_risk() -> void:
	var loot_value: float = 0.0
	if InventoryManager:
		loot_value = float(InventoryManager.expedition_earnings)

	var duration: float = float(max(1.0, float(TimeManager.extraction_duration_seconds)))
	var elapsed: float = duration - float(TimeManager.extraction_remaining_seconds)
	var weather_severity: float = _get_weather_severity()
	var player_density: float = _get_player_density()

	# Normalized components 0..1
	var loot_norm: float = float(clamp(loot_value / 3200.0, 0.0, 1.0))
	var time_norm: float = float(clamp(elapsed / duration, 0.0, 1.0))
	var weather_norm: float = float(clamp(weather_severity, 0.0, 1.0))
	var density_norm: float = float(clamp(player_density / 4.0, 0.0, 1.0))

	# Weighted formula from GDD dimensions.
	loot_value_component = loot_norm * 38.0
	time_component = time_norm * 28.0
	weather_component = weather_norm * 24.0
	player_density_component = density_norm * 10.0
	risk_level = clamp(loot_value_component + time_component + weather_component + player_density_component, 0.0, 100.0)

	if abs(risk_level - _last_reported_level) >= 1.0:
		_last_reported_level = risk_level
		risk_changed.emit(risk_level, get_risk_components())

func _get_weather_severity() -> float:
	if WeatherManager == null:
		return 0.1

	if WeatherManager.current_weather == WeatherManager.WeatherType.STORM:
		return 1.0
	if WeatherManager.current_weather == WeatherManager.WeatherType.RAIN:
		return 0.6
	if WeatherManager.current_weather == WeatherManager.WeatherType.FOG:
		return 0.4
	return 0.1

func _get_player_density() -> float:
	if multiplayer == null:
		return 0.0
	var peers := multiplayer.get_peers()
	return float(peers.size())

func get_current_risk_level() -> float:
	return risk_level

func get_risk_components() -> Dictionary:
	return {
		"loot_value": loot_value_component,
		"time_in_match": time_component,
		"weather_severity": weather_component,
		"player_density": player_density_component
	}
