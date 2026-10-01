extends Resource
class_name StageData
## Kampanya bolumu: 5 dusman slotu + seviyeleri + ilk-gecis odulleri.
## Ornek veriler data/stages/ altinda .tres olarak durur.

@export var stage_id: String = "1-1"
@export var stage_number: int = 1
@export var enemy_front_top: HeroData
@export var enemy_front_bot: HeroData
@export var enemy_back_top: HeroData
@export var enemy_back_mid: HeroData
@export var enemy_back_bot: HeroData
@export var enemy_team_level: int = 1
@export var first_clear_gold: int = 500
@export var first_clear_diamonds: int = 100
