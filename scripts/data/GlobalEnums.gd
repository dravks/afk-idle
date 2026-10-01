extends RefCounted
class_name GlobalEnums
## Global enum referansi (class_name ile her yerden erisilir, autoload gerekmez).
## Tum veri katmani (HeroData, SkillData, BuffData, FactionMatrix) bu tipleri kullanir.

enum Faction {
	LIGHTBEARER,  # 0
	MAULER,       # 1
	WILDER,       # 2
	GRAVEBORN,    # 3
	CELESTIAL,    # 4
	HYPOGEAN,     # 5
	DIMENSIONAL,  # 6
}

enum Role {
	TANK,
	WARRIOR,
	RANGER,
	MAGE,
	SUPPORT,
}

enum DamageType {
	PHYSICAL,
	MAGICAL,
}

enum SkillType {
	BASIC_ATTACK,
	ACTIVE_SKILL,
	ULTIMATE,
	PASSIVE,
}

enum TargetRule {
	NEAREST_ENEMY,
	LOWEST_HP_PERCENT,
	HIGHEST_ATK,
	RANDOM_ENEMY,
	ALL_ENEMIES,
	ALL_ALLIES,
	SELF,
}

enum BuffType {
	ATK_BUFF,
	DEF_BUFF,
	HASTE_BUFF,
	STUN,
	SHIELD,
	DOT,
	HOT,
	INVULNERABLE,
}

enum AscensionTier {
	COMMON,  # 0
	RARE,  # 1
	ELITE,  # 2
	ELITE_PLUS,  # 3
	LEGENDARY,  # 4
	MYTHIC,  # 5
	ASCENDED,  # 6
}

enum EquipSlot {
	WEAPON,  # 0
	ARMOR,  # 1
	HELMET,  # 2
	BOOTS,  # 3
}
