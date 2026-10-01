extends RefCounted
class_name FactionMatrix
## Fraksiyon avantaj matrisi (saf fonksiyonlar, durum tutmaz).
## - 4 temel dongu: LIGHTBEARER > MAULER > WILDER > GRAVEBORN > LIGHTBEARER.
## - CELESTIAL ve HYPOGEAN birbirine karsi ustundur (cift yonlu).
## - DIMENSIONAL tamamen notr: kimseye ustunluk saglamaz/yemez.
## - Temel dortlu ile Celestial/Hypogean arasinda iliski yoktur.

const ADVANTAGE_MULTIPLIER := 1.25
const NO_ADVANTAGE := 1.0

static func get_damage_multiplier(
	attacker_faction: GlobalEnums.Faction,
	defender_faction: GlobalEnums.Faction
) -> float:
	var att := int(attacker_faction)
	var dfn := int(defender_faction)
	# Dimensional her durumda notr.
	if att == GlobalEnums.Faction.DIMENSIONAL or dfn == GlobalEnums.Faction.DIMENSIONAL:
		return NO_ADVANTAGE
	# Celestial <-> Hypogean cift yonlu ustunluk.
	var cel := GlobalEnums.Faction.CELESTIAL
	var hyp := GlobalEnums.Faction.HYPOGEAN
	if (att == cel and dfn == hyp) or (att == hyp and dfn == cel):
		return ADVANTAGE_MULTIPLIER
	# 4'lu dongu [LB=0, M=1, W=2, GB=3]: saldiran savunandan tam 1 once ise ustun.
	if att >= 0 and att <= 3 and dfn >= 0 and dfn <= 3:
		if (att - dfn + 4) % 4 == 3:
			return ADVANTAGE_MULTIPLIER
	return NO_ADVANTAGE

static func has_advantage(
	attacker_faction: GlobalEnums.Faction,
	defender_faction: GlobalEnums.Faction
) -> bool:
	return get_damage_multiplier(attacker_faction, defender_faction) > NO_ADVANTAGE
