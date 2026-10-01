extends Resource
class_name QuestData
## Gorev/basarm tanimi + canli ilerleme. Katalog kodda kurulur
## (QuestManager); ilerleme kayit dilimiyle saklanir.

enum QuestType { DAILY, ACHIEVEMENT }

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var quest_type: QuestType = QuestType.DAILY
@export var target_amount: int = 1
@export var current_amount: int = 0
@export var reward_points: int = 20
@export var reward_diamonds: int = 50
@export var reward_scrolls: int = 0
@export var is_claimed: bool = false

func is_complete() -> bool:
	return current_amount >= target_amount

func progress_text() -> String:
	return "%d/%d" % [mini(current_amount, target_amount), target_amount]
