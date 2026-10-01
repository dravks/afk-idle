extends RefCounted
class_name FactionSynergyCalculator
## Formasyon auralari: 5 kahramanin fraksiyon dagilimina gore bonus.
## Celestial jokerdir (her fraksiyondan sayilir); Hypogean basina +%5 DEF
## carpan + %3 kritik (toplamsal) verir. Donus her zaman ayni anahtarlarla.

static func calculate_synergy(heroes: Array[HeroData]) -> Dictionary:
	var out := {"hp_mult": 1.0, "atk_mult": 1.0, "def_mult": 1.0,
		"crit_add": 0.0, "description": "Sinerji yok"}
	var counts := {0: 0, 1: 0, 2: 0, 3: 0}
	var celestials := 0
	var hypogeans := 0
	for h in heroes:
		if h == null:
			continue
		var f := int(h.faction)
		if f == GlobalEnums.Faction.CELESTIAL:
			celestials += 1
		elif f == GlobalEnums.Faction.HYPOGEAN:
			hypogeans += 1
		elif f >= 0 and f <= 3:
			counts[f] = int(counts[f]) + 1
	if hypogeans > 0:
		out["def_mult"] = pow(1.05, hypogeans)
		out["crit_add"] = 0.03 * hypogeans
	# En iyi temel fraksiyon (jokerler eklenmis).
	var best_f := -1
	var best_n := 0
	for f in [0, 1, 2, 3]:
		var n := int(counts[f]) + celestials
		if n > best_n:
			best_n = n
			best_f = f
	if best_n >= 5:
		out["hp_mult"] = 1.25
		out["atk_mult"] = 1.25
	elif best_n == 4:
		out["hp_mult"] = 1.15
		out["atk_mult"] = 1.20
	elif best_n == 3:
		if _has_pair(counts, best_f, celestials):
			out["hp_mult"] = 1.15
			out["atk_mult"] = 1.15
		else:
			out["hp_mult"] = 1.10
			out["atk_mult"] = 1.10
	else:
		return out
	out["description"] = _describe(best_f, best_n, float(out["hp_mult"]), float(out["atk_mult"]))
	return out

## 3'lu disinda kalan 2'si ayni fraksiyonsa 3+2 olur (jokerler zaten sayili).
static func _has_pair(counts: Dictionary, best_f: int, celestials: int) -> bool:
	var rest: Array = []
	for f in [0, 1, 2, 3]:
		if f == best_f:
			continue
		for i in int(counts[f]):
			rest.append(f)
	# Jokerler en iyi fraksiyona yazildigi icin burada saf disi sayilir.
	if rest.size() != 2:
		return false
	return int(rest[0]) == int(rest[1])

static func _describe(best_f: int, best_n: int, hp: float, atk: float) -> String:
	var fname := "Bilinmeyen"
	match best_f:
		0:
			fname = "Lightbearer"
		1:
			fname = "Mauler"
		2:
			fname = "Wilder"
		3:
			fname = "Graveborn"
	return "AURA: %dx %s (+%%%d HP, +%%%d ATK)" % [best_n, fname,
		int(round((hp - 1.0) * 100.0)), int(round((atk - 1.0) * 100.0))]
