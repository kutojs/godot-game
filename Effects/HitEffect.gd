extends Node2D


func _ready():
	$SmokeParticles2D2.emitting = true
	$SparkParticles2D.emitting = true
	$HitSounds.play()
