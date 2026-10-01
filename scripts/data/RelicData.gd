extends Resource
class_name RelicData
## Labirent kalintisi: savas-sureli pasif sinerji tanimi.
## Tutti-frutti etkiler RelicManager tarafindan savas basinda enjekte edilir.

enum RelicRarity { COMMON, RARE, EPIC }
enum RelicEffectType { STAT_BOOST, LIFE_STEAL, START_ENERGY, COMMANDER_BOOST, POISON_START }

@export var id: String = ""
@export var relic_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var rarity: RelicRarity = RelicRarity.COMMON
@export var effect_type: RelicEffectType = RelicEffectType.STAT_BOOST
@export var effect_value: float = 0.20
