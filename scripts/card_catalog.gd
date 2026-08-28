class_name CardCatalog
extends RefCounted

const CARDS := {
	"Strike": {"cost":1,"damage":15,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 15 damage."},
	"Strike+": {"cost":1,"damage":20,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 20 damage."},
	"Fireball": {"cost":2,"damage":25,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 25 damage."},
	"Fireball+": {"cost":2,"damage":34,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 34 damage."},
	"Guard": {"cost":1,"damage":0,"heal":10,"block":8,"draw":0,"type":"skill","description":"Gain 8 block and heal 10 HP."},
	"Guard+": {"cost":1,"damage":0,"heal":14,"block":12,"draw":0,"type":"skill","description":"Gain 12 block and heal 14 HP."},
	"Heavy Blow": {"cost":3,"damage":40,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 40 damage."},
	"Heavy Blow+": {"cost":2,"damage":45,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 45 damage."},
	"Slash": {"cost":1,"damage":22,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 22 damage."},
	"Slash+": {"cost":1,"damage":29,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 29 damage."},
	"Ice Lance": {"cost":2,"damage":30,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 30 damage."},
	"Ice Lance+": {"cost":2,"damage":40,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 40 damage."},
	"Blood Pact": {"cost":1,"damage":18,"heal":8,"block":0,"draw":0,"type":"skill","description":"Deal 18 damage and heal 8 HP."},
	"Blood Pact+": {"cost":1,"damage":24,"heal":12,"block":0,"draw":0,"type":"skill","description":"Deal 24 damage and heal 12 HP."},
	"Focus": {"cost":1,"damage":0,"heal":0,"block":5,"draw":0,"type":"skill","description":"Gain 5 block."},
	"Focus+": {"cost":1,"damage":0,"heal":0,"block":8,"draw":0,"type":"skill","description":"Gain 8 block."},
	"Expose": {"cost":1,"damage":0,"heal":0,"block":0,"draw":0,"vulnerable":2,"type":"skill","description":"Apply 2 Vulnerable."},
	"Expose+": {"cost":1,"damage":0,"heal":0,"block":0,"draw":0,"vulnerable":3,"type":"skill","description":"Apply 3 Vulnerable."},
	"Hex": {"cost":1,"damage":0,"heal":0,"block":0,"draw":0,"weak":2,"type":"skill","description":"Apply 2 Weak."},
	"Hex+": {"cost":1,"damage":0,"heal":0,"block":0,"draw":0,"weak":3,"type":"skill","description":"Apply 3 Weak."},
	"Toxic Flask": {"cost":1,"damage":0,"heal":0,"block":0,"draw":0,"poison":4,"type":"skill","description":"Apply 4 Poison."},
	"Toxic Flask+": {"cost":1,"damage":0,"heal":0,"block":0,"draw":0,"poison":6,"type":"skill","description":"Apply 6 Poison."},
	"Quick Jab": {"cost":1,"damage":10,"heal":0,"block":0,"draw":1,"type":"attack","description":"Deal 10 damage and draw 1."},
	"Quick Jab+": {"cost":0,"damage":12,"heal":0,"block":0,"draw":1,"type":"attack","description":"Deal 12 damage and draw 1."},
	"Fortify": {"cost":1,"damage":0,"heal":0,"block":14,"draw":0,"type":"skill","description":"Gain 14 block."},
	"Fortify+": {"cost":1,"damage":0,"heal":0,"block":20,"draw":0,"type":"skill","description":"Gain 20 block."},
	"Poison Dart": {"cost":1,"damage":10,"heal":0,"block":0,"draw":0,"poison":4,"type":"skill","description":"Deal 10 damage and apply 4 Poison."},
	"Poison Dart+": {"cost":1,"damage":14,"heal":0,"block":0,"draw":0,"poison":7,"type":"skill","description":"Deal 14 damage and apply 7 Poison."},
	"Cleave": {"cost":2,"damage":28,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 28 damage."},
	"Cleave+": {"cost":2,"damage":38,"heal":0,"block":0,"draw":0,"type":"attack","description":"Deal 38 damage."},
	"Siphon": {"cost":2,"damage":14,"heal":14,"block":0,"draw":0,"type":"skill","description":"Deal 14 damage and heal 14 HP."},
	"Siphon+": {"cost":2,"damage":20,"heal":20,"block":0,"draw":0,"type":"skill","description":"Deal 20 damage and heal 20 HP."},
	"Adrenaline": {"cost":0,"damage":0,"heal":0,"block":0,"draw":2,"type":"power","description":"Draw 2 cards."},
	"Adrenaline+": {"cost":0,"damage":0,"heal":0,"block":0,"draw":3,"type":"power","description":"Draw 3 cards."},
	"Shatter": {"cost":2,"damage":18,"heal":0,"block":0,"draw":0,"vulnerable":2,"type":"attack","description":"Deal 18 damage and apply 2 Vulnerable."},
	"Shatter+": {"cost":2,"damage":24,"heal":0,"block":0,"draw":0,"vulnerable":3,"type":"attack","description":"Deal 24 damage and apply 3 Vulnerable."},
	"Riposte": {"cost":1,"damage":12,"heal":0,"block":6,"draw":0,"type":"skill","description":"Deal 12 damage and gain 6 block."},
	"Riposte+": {"cost":1,"damage":18,"heal":0,"block":10,"draw":0,"type":"skill","description":"Deal 18 damage and gain 10 block."}
}

const upgraded_cards := {
	"Strike":{"name":"Strike+"},"Fireball":{"name":"Fireball+"},"Guard":{"name":"Guard+"},"Heavy Blow":{"name":"Heavy Blow+"},"Slash":{"name":"Slash+"},"Ice Lance":{"name":"Ice Lance+"},"Blood Pact":{"name":"Blood Pact+"},"Focus":{"name":"Focus+"},"Expose":{"name":"Expose+"},"Hex":{"name":"Hex+"},"Toxic Flask":{"name":"Toxic Flask+"},
	"Quick Jab":{"name":"Quick Jab+"},"Fortify":{"name":"Fortify+"},"Poison Dart":{"name":"Poison Dart+"},"Cleave":{"name":"Cleave+"},"Siphon":{"name":"Siphon+"},"Adrenaline":{"name":"Adrenaline+"},"Shatter":{"name":"Shatter+"},"Riposte":{"name":"Riposte+"}
}

static func get_card(name: String) -> Dictionary:
	return CARDS.get(name, {})

static func card_type(name: String) -> String:
	return str(get_card(name).get("type", "skill"))

static func all_names() -> Array:
	return CARDS.keys()
