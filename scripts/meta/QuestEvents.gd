extends Node
## Global gorev olay veri yolu (autoload "QuestEvents", class_name YOK:
## ayni isim cakismasi yapar). Moduller birbirini tanimaz, sinyale konusur.
## Dinleyen tek yer: GameFlowManager cocugu QuestManager.

signal campaign_won(stage_index: int)
signal hero_leveled_up
signal afk_claimed
signal summon_performed(count: int)
signal boss_challenged(damage_dealt: float)
signal labyrinth_battle_won
signal arena_battle_completed(is_victory: bool)
signal tower_floor_cleared(floor_number: int)
