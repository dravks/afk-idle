extends RefCounted
class_name HeroSpriteFactory
## Prosedurel piksel kahramanlar: HeroData'da .tres karesi/portresi yoksa
## rol + kimlige gore uretir. Ayni id hep ayni seti alir (id koklu cache).
## Gercek assetler geldiginde data.sprite_frames/portrait dolacak ve bu
## uretim hic cagrilmayacak (Unit once .tres'e bakar).

const W := 24
const H := 32

static var _frames: Dictionary = {}
static var _portraits: Dictionary = {}

static func frames_of(data: HeroData) -> SpriteFrames:
	if data != null and data.sprite_frames != null:
		return data.sprite_frames
	var key := data.id if data != null else "?"
	if _frames.has(key):
		return _frames[key] as SpriteFrames
	var sf := _build_frames(data)
	_frames[key] = sf
	return sf

static func portrait_of(data: HeroData) -> Texture2D:
	if data != null and data.portrait != null:
		return data.portrait
	var key := data.id if data != null else "?"
	if _portraits.has(key):
		return _portraits[key] as Texture2D
	var tex := _build_portrait(data)
	_portraits[key] = tex
	return tex

# ---------------------------------------------------------------- palet

static func _palette(data: HeroData) -> Dictionary:
	var role := 1
	var hid := ""
	if data != null:
		role = int(data.role)
		hid = data.id
	if hid == "wolf":
		return {"beast": true, "fur": Color("#8a8a9a"), "dark": Color("#4a4a55"),
			"skin": Color("#8a8a9a"), "accent": Color("#d63a2f")}
	if hid == "dragon":
		return {"dragon": true, "red": Color("#b03030"), "dark": Color("#5a1414"),
			"belly": Color("#d06048"), "bone": Color("#e8e2d0")}
	var skin := Color("#e8b98a")
	var cloth := Color("#b0724f")
	var dark := Color("#4a3020")
	var accent := Color("#ffd966")
	var enemy := hid == "goblin" or hid == "orc" or hid == "shaman"
	if enemy:
		skin = Color("#7ec850") if hid != "orc" else Color("#5aa840")
	# Yeni fraksiyon yuzleri (eski kahramanlar degismez).
	if hid == "shemira" or hid == "silvina" or hid == "thorin":
		skin = Color("#c9d1c9")
	elif hid == "tasi" or hid == "eironn" or hid == "nemora":
		skin = Color("#d8a878")
	elif hid == "brutus" or hid == "saveas" or hid == "skreg":
		skin = Color("#c07848")
	match role:
		0:
			cloth = Color("#6f8fb8")
			dark = Color("#2a3a5a")
			accent = Color("#d63a2f")
		3:
			cloth = Color("#a06fc0")
			dark = Color("#4a2a6a")
			accent = Color("#8fd3ff")
		4:
			cloth = Color("#e8d890")
			dark = Color("#6a5a2a")
			accent = Color("#ffd966")
		_:
			pass
	return {"skin": skin, "cloth": cloth, "dark": dark,
		"pants": Color("#3a3a4a"), "accent": accent, "role": role,
		"hid": hid, "enemy": enemy}

# ---------------------------------------------------------------- cizim yardimcilari

static func _blank(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

static func _rect(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx >= 0 and yy >= 0 and xx < img.get_width() and yy < img.get_height():
				img.set_pixel(xx, yy, col)

static func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

# ---------------------------------------------------------------- humanoid

static func _humanoid(pal: Dictionary, legs: String, yoff: int, strike: bool) -> Image:
	var img := _blank(W, H)
	var skin: Color = pal["skin"]
	var cloth: Color = pal["cloth"]
	var dark: Color = pal["dark"]
	var pants: Color = pal["pants"]
	var accent: Color = pal["accent"]
	var role := int(pal.get("role", 1))
	var hid := str(pal.get("hid", ""))
	var leg_l := 0
	var leg_r := 0
	if legs == "walk_a":
		leg_l = -1
		leg_r = 1
	elif legs == "walk_b":
		leg_l = 1
		leg_r = -1
	# Bacaklar + ayakkabi
	_rect(img, 9, 18 + leg_l + yoff, 3, 8, pants)
	_rect(img, 12, 18 + leg_r + yoff, 3, 8, pants)
	_rect(img, 9, 25 + leg_l + yoff, 3, 1, dark)
	_rect(img, 12, 25 + leg_r + yoff, 3, 1, dark)
	# Govde + kemer + arma
	_rect(img, 8, 10 + yoff, 8, 8, cloth)
	_rect(img, 8, 16 + yoff, 8, 2, dark)
	_rect(img, 11, 12 + yoff, 2, 2, accent)
	# Kollar + eller
	_rect(img, 6, 10 + yoff, 2, 6, dark)
	_rect(img, 16, 10 + yoff, 2, 6, dark)
	_rect(img, 6, 14 + yoff, 2, 2, skin)
	_rect(img, 16, 14 + yoff, 2, 2, skin)
	# Kafa + gozler
	_rect(img, 9, 4 + yoff, 6, 6, skin)
	_rect(img, 10, 6 + yoff, 1, 1, dark)
	_rect(img, 13, 6 + yoff, 1, 1, dark)
	_headgear(img, role, hid, yoff, cloth, dark, accent)
	if bool(pal.get("enemy", false)):
		_rect(img, 7, 5 + yoff, 2, 2, skin)
		_rect(img, 15, 5 + yoff, 2, 2, skin)
	_weapon(img, role, hid, strike, yoff, dark, accent)
	# Tank kalkni (sol)
	if role == 0:
		_rect(img, 3, 12 + yoff, 3, 7, Color("#4f8fd6"))
		_rect(img, 3, 12 + yoff, 3, 1, dark)
		_rect(img, 4, 15 + yoff, 1, 1, accent)
	return img

static func _headgear(img: Image, role: int, hid: String, yoff: int, cloth: Color, dark: Color, accent: Color) -> void:
	match role:
		0:  # miğfer + sorguç
			_rect(img, 8, 2 + yoff, 8, 3, Color("#9aa4b0"))
			_rect(img, 8, 4 + yoff, 8, 1, dark)
			_rect(img, 11, 0 + yoff, 2, 2, accent)
		3:  # büyücü şapkası
			_rect(img, 11, 0 + yoff, 2, 1, dark)
			_rect(img, 10, 1 + yoff, 4, 1, dark)
			_rect(img, 9, 2 + yoff, 6, 1, dark)
			_rect(img, 8, 3 + yoff, 8, 1, dark)
		4:  # altın taç bandı
			_rect(img, 9, 3 + yoff, 6, 1, accent)
		2:  # avcı başlığı (yeşil kukuleta)
			_rect(img, 8, 2 + yoff, 8, 2, Color("#3f7a3f"))
			_rect(img, 8, 4 + yoff, 1, 4, Color("#3f7a3f"))
			_rect(img, 15, 4 + yoff, 1, 4, Color("#3f7a3f"))
		_:
			if hid == "orc":
				_rect(img, 10, 8 + yoff, 1, 1, Color("#ffffff"))
				_rect(img, 13, 8 + yoff, 1, 1, Color("#ffffff"))
			else:  # saç
				_rect(img, 9, 3 + yoff, 6, 1, Color("#4a2f1a"))

static func _weapon(img: Image, role: int, hid: String, strike: bool, yoff: int, dark: Color, accent: Color) -> void:
	var steel := Color("#c8ccd4")
	var wood := Color("#6a4a2a")
	if role == 3 or role == 4 or hid == "shaman" or hid == "cleric":
		# Asa + küre
		_rect(img, 18, 6 + yoff, 2, 19, wood)
		if strike:
			_rect(img, 17, 2 + yoff, 4, 4, accent)
			_rect(img, 16, 3 + yoff, 1, 1, Color("#ffffff"))
		else:
			_rect(img, 17, 3 + yoff, 3, 3, accent)
	elif role == 2:
		# Yay + ok (atinca ok ucar)
		_rect(img, 18, 8 + yoff, 2, 14, wood)
		_rect(img, 17, 8 + yoff, 1, 1, wood)
		_rect(img, 17, 21 + yoff, 1, 1, wood)
		_rect(img, 18, 14 + yoff, 1, 1, Color("#e8e2d0"))
		if strike:
			_rect(img, 19, 14 + yoff, 6, 1, Color("#e8b98a"))
			_rect(img, 25, 14 + yoff, 2, 1, steel)
	else:
		# Kılıç / hançer
		var tall := 10 if hid == "goblin" else 12
		if strike:
			_rect(img, 18, 11 + yoff, 8, 2, steel)
			_rect(img, 17, 10 + yoff, 1, 4, wood)
			_rect(img, 25, 11 + yoff, 1, 2, Color("#ffffff"))
		else:
			_rect(img, 18, 8 + yoff, 2, tall, steel)
			_rect(img, 17, 18 + yoff, 4, 1, wood)
			_rect(img, 18, 19 + yoff, 2, 2, wood)

static func _fallen(pal: Dictionary) -> Image:
	var img := _blank(W, H)
	var skin: Color = pal.get("skin", Color("#e8b98a"))
	var cloth: Color = pal.get("cloth", Color("#b0724f"))
	var dark: Color = pal.get("dark", Color("#4a3020"))
	# Yerde yatan: bacaklar + gövde + kafa + silah yanında
	_rect(img, 2, 20, 6, 3, pal.get("pants", dark))
	_rect(img, 2, 24, 12, 6, cloth)
	_rect(img, 14, 23, 6, 6, skin)
	_rect(img, 15, 25, 1, 1, dark)
	_rect(img, 17, 25, 1, 1, dark)  # X gözler
	_rect(img, 15, 24, 1, 1, dark)
	_rect(img, 17, 26, 1, 1, dark)
	_rect(img, 21, 26, 2, 1, Color("#c8ccd4"))
	return img

# ---------------------------------------------------------------- canavar + ejderha

static func _beast(pal: Dictionary, legs: String, yoff: int, strike: bool) -> Image:
	var img := _blank(W, H)
	var fur: Color = pal["fur"]
	var dark: Color = pal["dark"]
	var lunge := 2 if strike else 0
	# Kuyruk + gövde + kafa
	_rect(img, 2, 17 + yoff, 3, 2, dark)
	_rect(img, 5, 16 + yoff, 14, 8, fur)
	_rect(img, 5, 22 + yoff, 14, 1, dark)
	_rect(img, 17 + lunge, 11 + yoff, 6, 7, fur)
	_rect(img, 18 + lunge, 10 + yoff, 2, 2, fur)
	_rect(img, 21 + lunge, 10 + yoff, 2, 2, fur)
	_rect(img, 19 + lunge, 13 + yoff, 1, 1, dark)  # göz
	_rect(img, 22 + lunge, 15 + yoff, 1, 2, dark)  # ağız
	# Bacaklar (yürümede alternatif)
	var offs := [0, 0, 0, 0]
	if legs == "walk_a":
		offs = [-1, 1, 1, -1]
	elif legs == "walk_b":
		offs = [1, -1, -1, 1]
	var xs := [6, 10, 14, 18]
	for i in 4:
		_rect(img, xs[i], 24 + (offs[i] as int) + yoff, 2, 5, dark)
	return img

static func _beast_fallen(pal: Dictionary) -> Image:
	var img := _blank(W, H)
	var fur: Color = pal["fur"]
	var dark: Color = pal["dark"]
	_rect(img, 4, 24, 16, 5, fur)
	_rect(img, 20, 22, 5, 5, fur)
	_rect(img, 21, 24, 2, 1, dark)
	_rect(img, 8, 20, 2, 4, dark)
	_rect(img, 14, 20, 2, 4, dark)
	return img

static func _dragon(yoff: int, strike: bool) -> Image:
	var img := _blank(40, 32)
	var red := Color("#b03030")
	var dark := Color("#5a1414")
	var belly := Color("#d06048")
	var bone := Color("#e8e2d0")
	var lunge := 3 if strike else 0
	# Kuyruk + gövde + karın
	_rect(img, 1, 22 + yoff, 9, 3, dark)
	_rect(img, 9, 18 + yoff, 19, 10, red)
	_rect(img, 11, 25 + yoff, 15, 3, belly)
	_rect(img, 11, 19 + yoff, 15, 1, dark)  # sırt dikeni
	_rect(img, 14, 18 + yoff, 1, 1, dark)
	_rect(img, 19, 18 + yoff, 1, 1, dark)
	_rect(img, 24, 18 + yoff, 1, 1, dark)
	# Bacaklar
	_rect(img, 12, 28 + yoff, 3, 3, dark)
	_rect(img, 22, 28 + yoff, 3, 3, dark)
	# Kanatlar (üçgen katmanlar)
	for r in 7:
		_rect(img, 8 - r, 10 + r + yoff, 4 + r, 1, dark)
		_rect(img, 26 + r - 2, 10 + r + yoff, 4 + r, 1, dark)
	_rect(img, 2, 16 + yoff, 12, 1, red)
	_rect(img, 24, 16 + yoff, 12, 1, red)
	# Boyun + kafa + boynuz + göz
	_rect(img, 27 + lunge, 12 + yoff, 4, 7, red)
	_rect(img, 30 + lunge, 9 + yoff, 7, 7, red)
	_rect(img, 36 + lunge, 12 + yoff, 3, 3, red)  # burun
	_rect(img, 31 + lunge, 7 + yoff, 2, 2, bone)  # boynuz
	_rect(img, 34 + lunge, 7 + yoff, 2, 2, bone)
	_rect(img, 32 + lunge, 11 + yoff, 2, 2, Color("#ffe040"))  # göz
	if strike:
		_rect(img, 36 + lunge, 14 + yoff, 3, 2, dark)  # açık ağız
	return img

static func _dragon_fallen() -> Image:
	var img := _blank(40, 32)
	var red := Color("#7a2020")
	var dark := Color("#3a0d0d")
	_rect(img, 4, 24, 24, 6, red)
	_rect(img, 28, 22, 9, 7, red)
	_rect(img, 30, 24, 2, 1, dark)
	_rect(img, 34, 24, 2, 1, dark)  # X gözler
	_rect(img, 30, 23, 1, 1, dark)
	_rect(img, 34, 25, 1, 1, dark)
	_rect(img, 6, 20, 14, 2, dark)  # düşük kanat
	return img

# ---------------------------------------------------------------- montaj

static func _add_anim(sf: SpriteFrames, anim_name: String, frames: Array, speed: float, loop: bool) -> void:
	if not sf.has_animation(anim_name):
		sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, speed)
	sf.set_animation_loop(anim_name, loop)
	for f in frames:
		sf.add_frame(anim_name, f)

static func _build_frames(data: HeroData) -> SpriteFrames:
	var pal := _palette(data)
	var sf := SpriteFrames.new()
	if bool(pal.get("dragon", false)):
		var b0 := _tex(_dragon(0, false))
		var b1 := _tex(_dragon(1, false))
		var bs := _tex(_dragon(0, true))
		_add_anim(sf, "idle", [b0, b1], 4.0, true)
		_add_anim(sf, "move", [b0, b1], 8.0, true)
		_add_anim(sf, "attack", [b0, bs], 12.0, false)
		_add_anim(sf, "hit", [b0], 6.0, false)
		_add_anim(sf, "death", [_tex(_dragon_fallen())], 3.0, false)
	elif bool(pal.get("beast", false)):
		var w0 := _tex(_beast(pal, "stand", 0, false))
		var w1 := _tex(_beast(pal, "stand", 1, false))
		var wa := _tex(_beast(pal, "walk_a", 0, false))
		var wb := _tex(_beast(pal, "walk_b", 0, false))
		var ws := _tex(_beast(pal, "stand", 0, true))
		_add_anim(sf, "idle", [w0, w1], 4.0, true)
		_add_anim(sf, "move", [wa, wb], 8.0, true)
		_add_anim(sf, "attack", [w0, ws], 12.0, false)
		_add_anim(sf, "hit", [w0], 6.0, false)
		_add_anim(sf, "death", [_tex(_beast_fallen(pal))], 3.0, false)
	else:
		var i0 := _tex(_humanoid(pal, "stand", 0, false))
		var i1 := _tex(_humanoid(pal, "stand", 1, false))
		var wa := _tex(_humanoid(pal, "walk_a", 0, false))
		var wb := _tex(_humanoid(pal, "walk_b", 0, false))
		var st := _tex(_humanoid(pal, "stand", 0, true))
		_add_anim(sf, "idle", [i0, i1], 4.0, true)
		_add_anim(sf, "move", [wa, wb], 8.0, true)
		_add_anim(sf, "attack", [i0, st], 12.0, false)
		_add_anim(sf, "hit", [i0], 6.0, false)
		_add_anim(sf, "death", [_tex(_fallen(pal))], 3.0, false)
	sf.remove_animation("default")
	return sf

# ---------------------------------------------------------------- portre

static func _build_portrait(data: HeroData) -> Texture2D:
	var pal := _palette(data)
	var img := _blank(40, 40)
	var hid := str(pal.get("hid", ""))
	if hid == "dragon":
		_rect(img, 0, 0, 40, 40, Color("#3a0d0d"))
		_rect(img, 8, 12, 24, 18, Color("#b03030"))
		_rect(img, 10, 8, 4, 5, Color("#e8e2d0"))
		_rect(img, 26, 8, 4, 5, Color("#e8e2d0"))
		_rect(img, 14, 17, 4, 4, Color("#ffe040"))
		_rect(img, 24, 17, 2, 4, Color("#5a1414"))
		_rect(img, 8, 30, 24, 10, Color("#5a1414"))
		return _tex(img)
	if bool(pal.get("beast", false)):
		var fur: Color = pal["fur"]
		var dark: Color = pal["dark"]
		_rect(img, 0, 0, 40, 40, Color("#23232c"))
		_rect(img, 8, 10, 24, 22, fur)
		_rect(img, 10, 6, 5, 6, fur)
		_rect(img, 25, 6, 5, 6, fur)
		_rect(img, 14, 16, 3, 4, dark)
		_rect(img, 23, 16, 3, 4, dark)
		_rect(img, 17, 24, 6, 3, dark)
		return _tex(img)
	var skin: Color = pal["skin"]
	var cloth: Color = pal["cloth"]
	var dark: Color = pal["dark"]
	var accent: Color = pal["accent"]
	var role := int(pal.get("role", 1))
	_rect(img, 0, 0, 40, 40, dark.darkened(0.55))
	_rect(img, 8, 28, 24, 12, cloth)  # omuzlar
	_rect(img, 17, 24, 6, 5, skin)  # boyun
	_rect(img, 12, 10, 16, 14, skin)  # yüz
	_rect(img, 16, 15, 2, 3, dark)  # gözler
	_rect(img, 22, 15, 2, 3, dark)
	_rect(img, 18, 21, 4, 1, dark.darkened(0.3))  # ağız
	match role:
		0:
			_rect(img, 10, 8, 20, 4, Color("#9aa4b0"))
			_rect(img, 18, 4, 4, 4, accent)
		3:
			_rect(img, 18, 2, 4, 2, dark)
			_rect(img, 16, 4, 8, 2, dark)
			_rect(img, 13, 6, 14, 3, dark)
			_rect(img, 10, 9, 20, 2, dark)
		4:
			_rect(img, 12, 9, 16, 2, accent)
		2:
			_rect(img, 10, 8, 20, 3, Color("#3f7a3f"))
			_rect(img, 10, 11, 2, 6, Color("#3f7a3f"))
			_rect(img, 28, 11, 2, 6, Color("#3f7a3f"))
		_:
			_rect(img, 12, 8, 16, 3, Color("#4a2f1a"))
	if bool(pal.get("enemy", false)):
		_rect(img, 8, 14, 4, 5, skin)
		_rect(img, 28, 14, 4, 5, skin)
	return _tex(img)
