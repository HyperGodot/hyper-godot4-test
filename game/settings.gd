extends Node

@onready var jsonInstance = JSON.new()

enum ShadowsQuality {
	DISABLED = 0,
	SHADOWS_1024 = 1,
	SHADOWS_2048 = 2,
	SHADOWS_4096 = 3,
}

enum GIQuality {
	DISABLED = 0,
	LOW = 1,
	HIGH = 2,
}

enum AAQuality {
	DISABLED = 0,
	AA_2X = 1,
	AA_4X = 2,
	AA_8X = 3,
}

enum SSAOQuality {
	DISABLED = 0,
	LOW = 1,
	HIGH = 2,
}

enum BloomQuality {
	DISABLED = 0,
	LOW = 1,
	HIGH = 2,
}

enum Resolution {
	RES_540 = 0,
	RES_720 = 1,
	RES_1080 = 2,
	NATIVE = 3,
}

var shadows_quality = ShadowsQuality.SHADOWS_1024
var gi_quality = GIQuality.LOW
var aa_quality = AAQuality.AA_2X
var bloom_quality = BloomQuality.HIGH

func _ready():
	load_settings()

func load_settings():
	var f = File.new()
	var error = f.open("user://settings.json", File.READ)
	if error:
		print("There are no settings to load.")
		return

	# var d = parse_json(f.get_as_text())
	var e = jsonInstance.parse(f.get_as_text())
	if(e == OK):
		var d = jsonInstance.get_data()
		if typeof(d) != TYPE_DICTIONARY:
			return

		if "shadows" in d:
			shadows_quality = d.shadows
		
		if "gi" in d:
			gi_quality = d.gi

		if "aa" in d:
			aa_quality = d.aa

		if "bloom" in d:
			bloom_quality = d.bloom

func save_settings():
	var f = File.new()
	var error = f.open("user://settings.json", File.WRITE)
	assert(not error)

	var d = { "shadows":shadows_quality, "gi":gi_quality, "aa":aa_quality, "bloom":bloom_quality }
	f.store_line( jsonInstance.stringify(d))
