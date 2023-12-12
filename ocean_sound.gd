extends AudioStreamPlayer

var basePitch = 0.88
var vibratoTime = 7.2
var vibratoWidth = 0.4
var vibratoPhase = 0.0

func _process(delta):
	vibratoPhase = fmod(vibratoPhase, 1.0)

	var a = sin(2.0 * PI * vibratoPhase)
	var pitchMod = 2.0 ** (vibratoWidth * a / 12.0)
	pitch_scale = basePitch * pitchMod

	vibratoPhase += delta / vibratoTime
