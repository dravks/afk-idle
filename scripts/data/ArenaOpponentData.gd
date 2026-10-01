extends RefCounted
class_name ArenaOpponentData
## Asenkron rakip: isim + puan + guc + 5'li savunma dizilimi.
## formation: slot adi -> {"hero_data": HeroData, "level": int}.

var opponent_name: String = "Gladiator"
var rank_points: int = 1000
var combat_power: int = 5000
var formation: Dictionary = {}
