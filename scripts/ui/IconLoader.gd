extends RefCounted
class_name IconLoader
## assets/icons altindaki game-icons SVG'lerini yukler + cache'ler.
## Tum ikonlar beyaz/transparent oldugu icin koyu arayuzde direkt kullanilir;
## renk gerekiyorsa cagiran modulate / icon_*_color uygular.

const ICON_DIR := "res://assets/icons/"

static var _cache: Dictionary = {}

static func get_icon(icon_name: String) -> Texture2D:
	if _cache.has(icon_name):
		return _cache[icon_name] as Texture2D
	var tex := load(ICON_DIR + icon_name + ".svg") as Texture2D
	if tex != null:
		_cache[icon_name] = tex
	return tex

static func has_icon(icon_name: String) -> bool:
	return get_icon(icon_name) != null
