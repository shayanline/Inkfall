extends SceneTree
## Throwaway probe: load a rendered PNG and report the hue / saturation of its most saturated,
## reasonably bright pixels (the neon tubes and letters). Confirms a red sign reads red, not pink.

func _init() -> void:
	for path in ["/tmp/t12_casino.png", "/tmp/t12_street.png", "/tmp/t12_alley.png"]:
		_probe(path)
	quit()


func _probe(path: String) -> void:
	var img := Image.load_from_file(path)
	if img == null:
		print(path, ": could not load")
		return
	var w := img.get_width()
	var h := img.get_height()
	# bucket the most saturated bright pixels by hue
	var red_like := 0      # hue near 0/360 (red)
	var pink_like := 0     # hue 300..345 (magenta/pink) i.e. red drifting toward magenta
	var yellow_like := 0   # hue 45..70
	var cream_like := 0    # high value, low sat, warm (creamy)
	var samples := 0
	var sum_sat := 0.0
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			var c := img.get_pixel(x, y)
			var v: float = maxf(maxf(c.r, c.g), c.b)
			if v < 0.45:
				continue
			var s := c.s
			if s < 0.25:
				# bright but desaturated: a creamy/white blowout if it is warm
				if c.r > 0.6 and c.g > 0.5 and v > 0.7:
					cream_like += 1
				continue
			samples += 1
			sum_sat += s
			var hue := c.h * 360.0
			if hue <= 20.0 or hue >= 350.0:
				red_like += 1
			elif hue >= 300.0 and hue < 350.0:
				pink_like += 1
			elif hue >= 45.0 and hue <= 70.0:
				yellow_like += 1
	var avg_sat := (sum_sat / samples) if samples > 0 else 0.0
	print(path)
	print("  saturated bright pixels: ", samples, "  avg sat: %.2f" % avg_sat)
	print("  red(0): ", red_like, "  pink/magenta(300-350): ", pink_like,
		"  yellow(45-70): ", yellow_like, "  creamy blowout: ", cream_like)
