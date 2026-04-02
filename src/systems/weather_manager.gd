extends Node

signal weather_changed(new_weather: int)

enum WeatherType { CLEAR, RAIN, FOG }
var current_weather: int = WeatherType.CLEAR

var rain_particles: GPUParticles3D
var world_env: WorldEnvironment

func _ready():
	# Select random weather at start of expedition
	var weather_types = [WeatherType.CLEAR, WeatherType.RAIN, WeatherType.FOG]
	var random_weather = weather_types[randi() % weather_types.size()]
	change_weather(random_weather)
	# Weather stays the same for entire expedition - no timer

func set_environment_references(env: WorldEnvironment, rain: GPUParticles3D):
	world_env = env
	rain_particles = rain
	apply_weather(current_weather)

func change_weather(type: int):
	current_weather = type
	emit_signal("weather_changed", type)
	apply_weather(type)
	print("Weather changed to: ", WeatherType.keys()[type])

func apply_weather(type: int):
	if not world_env or not rain_particles: return
	
	match type:
		WeatherType.CLEAR:
			rain_particles.emitting = false
			world_env.environment.fog_enabled = false
			world_env.environment.volumetric_fog_enabled = false
		
		WeatherType.RAIN:
			rain_particles.emitting = true
			world_env.environment.fog_enabled = true
			world_env.environment.fog_density = 0.02
			world_env.environment.fog_light_color = Color(0.3, 0.3, 0.4)
			
		WeatherType.FOG:
			rain_particles.emitting = false
			world_env.environment.fog_enabled = true
			world_env.environment.fog_density = 0.08 # Thicker fog
			world_env.environment.fog_light_color = Color(0.6, 0.6, 0.6)



func is_raining() -> bool:
	return current_weather == WeatherType.RAIN

func is_foggy() -> bool:
	return current_weather == WeatherType.FOG
