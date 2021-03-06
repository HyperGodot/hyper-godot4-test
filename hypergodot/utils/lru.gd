# Least Recently Used Cache
## Use this if you want to keep track of a set, but with a limit

# Map from value to time last used
var values = {}
const DEFAULT_SIZE = 512

var max_size = DEFAULT_SIZE

func _init(new_max = DEFAULT_SIZE):
	max_size = new_max

func has(value):
	return value in values

func track(value):
	var time = Time.get_ticks_msec()
	
	values[value] = time

func is_full():
	return size() > max_size

func size():
	return values.size()

func clear_oldest():
	var oldest = get_oldest()
	values.erase(oldest)
	
func get_oldest():
	var oldestTime = Time.get_ticks_msec()
	var oldestValue = null
	for value in values.keys():
		var valueTime = values[value]
		if valueTime < oldestTime:
			oldestTime = valueTime
			oldestValue = value
	return oldestValue
