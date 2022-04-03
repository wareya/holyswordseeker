extends Node2D

var intro_text = [
"""You awaken in a hut. Try as you might, you can't remember how you got here, only why.""",
"""[color=yellow]"All who value the Light, young and old, weak and strong, shall seek the holy sword."[/color]""",
"""Like many Seekers before you, you heard the prophet's call and came to the Dust-tainted Tower of Light.""",
#"""Perhaps [color=#4FF]you[/color] will be the one to return with the holy sword and resurrect the Hero.""",
"""Thinking back to stories of a world before Dust, you clench your fists and get moving.""",
]

# dying as non-sword-holding seeker
var failure_ending = [
"""The reaper came for you early, it seems.""",
"""Do not lose heart! There is certainly another Seeker out there eager to take your place.""",
"""As the world fades away, you dream of another life. It is a beautiful dream.""",
"""Eventually, your thoughts cease, and the Dust takes you.""",
]

# dying as hero or as a sword-holding seeker
var failure_sword_ending = [
"""Even carrying the holy sword was not enough to keep the reaper at bay, it seems.""",
"""Do not lose heart! There is certainly another Seeker out there eager to take your place.""",
"""As the world fades away, you dream of another life. It is a beautiful dream.""",
"""A perfect, tranquil paradise, devoid of any discomfort. And yet, something is wrong.""",
"""Nothing ever changes. No one ever dies. Relationships never change.""",
"""Only the everturning sun and moon and everchanging seasons tell you that time passes.""",
"""The fields do not grow infertile. The forests do not grow or rot.""",
"""From where does the soil's richness come from? When did the trees first sprout, and when will they die?""",
"""Eventually, your thoughts cease, and the Dust takes you.""",
]

# leaving early as a seeker
var bad_ending = [
"""You leave the Tower of Light behind with neither holy sword nor accomplishment.""",
"""The saddest way for a Seeker's journey to end, not even going down as a fallen warrior.""",
"""But life goes on. Perhaps one day another Seeker will rescue the holy sword, and the Hero will rise again.""",
"""Hoping so, you return to a quiet life far away from the Tower of Light, somewhere no one knows your name.""",
]

# leaving early as a hero
var hero_bad_ending = [
"""You leave the Tower of Light behind without having fulfilled your holy duty. The people jeer at you.""",
"""How dishonorable. Even dying to a low-level skeleton or slime would have been better.""",
"""But life goes on. You weren't cut out for this 'hero' job anyway. Better if someone else does it.""",
"""Leaving the holy sword behind to choose a new hero, you set off in search of a new home.""",
]

# leaving with the sword as a seeker
var sword_ending = [
"""Holy sword in hand, you return from the Tower of Light, triumphant and brave.""",
"""Your name is known across all the lands, and the people welcome you as not a Seeker but a Savior instead.""",
"""One day, the holy sword will choose a new hero. When it does, the Dust will be confronted again.""",
"""This is a new hope. The world has a way to survive again. A way to outlast the Dust.""",
"""And it is a hope that [color=#4FF]you[/color] are responsible for.""",
"""So rest easy, Savior. [color=#4FF]The hero will rise and confront the Apostle of Dust once more.[/color]""",
"""When that day comes, will [color=#F44]you[/color] be ready?""", # this is red and implies that 'you' is the player
]

# defeating the apostle of dust as a hero
var hero_ending = [
"""A shockwave of sparkling magical energy, visible to the naked eye, surges through the area, but soon ceases.""",
"""The Apostle of Dust is no more!""",
"""At long last, the Dust will stop changing and corrupting the land, and it can be tranquil and pure once more.""",
"""Something about this victory feels... empty, but you can't place your finger on it.""",
"""You take a deep breath and look around you. The tower is starting to twist and turn.""",
"""The Dust must be receding, and the Tower of Light returning to what it once was long ago.""",
"""It's time to go home, before you're taken by the chaos.""",
"""You live out the rest of your days as the ruler of a small holy kingdom, as beautiful as the most tranquil dream.""",
]

# defeating the apostle of dust as a seeker WITH the holy sword
var normie_ending = [
"""The Apostle of Dust looks at you shocked and appalled.""",
"""It finally noticed that you are no hero, just an ordinary seeker. Terror fills its eyes.""",
"""The holy sword glows, and the apostle explodes in a shockwave of visibly-magical energy.""",
"""You're knocked back, but uninjured. Looking where you once stood, the Apostle of Dust is gone.""",
"""Is it dead? Is this... a victory?""",
"""The walls start to move. Ah. Victory seems to be right. Why else would the Dust be receding?""",
"""You take out your [color=#4FF]Homeward Amulet[/color] and return from the tower.""",
"""The people of the world are stunned. The order of the holy sword dissolves in confusion.""",
"""How could a non-hero take up the holy sword against the Apostle of Dust?""",
"""Were the past hundred cycles of the hero system in vain?""",
"""But such problems mean nothing to you. All you wanted was to live in a world without Dust.""",
"""You retire to a quiet town, where the people treat you like royalty, and you know no discomfort.""",
]

# if you take down the apostle of dust as a seeker WITHOUT the holy sword
var swordless_ending = [
"""The Apostle of Dust collapses, defeated.""",
"""You stand over it and prepare to deal the finishing blow.""",
"""And yet, when you go to do so, the apostle begins to laugh.""",
"""Why? What's so funny?""",
"""[color=yellow]"To think that the Dust would be bested by a mere Seeker! And what's more, one without the power to banish me!"[/color]""",
"""The laughter ceases, and the apostle stands and extends a hand.""",
"""What...?""",
"""[color=yellow]"You are no Seeker or Hero. No, you are something more. Only one who seeks a [color=white]Better Way[/color] would dare fight me without the blade of banishment."[/color]""",
"""Blade of banishment...?""",
"""[color=yellow]"The world is decaying, devouring its own past and future to maintain a meager existence."[/color]""",
"""[color=yellow]"But with as much power as [color=white]you[/color] have, there might be a [color=white]Better Way[/color]. Come join the Dust. It is your destiny."[/color]""",
"""You don't understand the Apostle's words. Yet, a strange force fills you, and you are compelled to grab the apostle's hand.""",
"""[color=yellow]"It is a deal. Now come!"[/color]""",
"""The world around you disappears in a whirlwind of sparkling black dust, and you find yourself losing all material form, traveling through a void.""",
"""What the future holds for you, you do not know. Whether your future even has [color=#4FF]you[/color] in it, you do not know.""",
"""But the future [color=#4FF]will come[/color]. That much is certain.""",
]

# if you get to floor 100 as a seeker WITHOUT the holy sword
# TODO
var the_true_word_ending = [

]

# (holy sword is at floor 20)
# (apostle spawns at floor 40, then every 5 floors)
# (unless you're a hero, at which case the apostle starts spawning at floor 10 and you already have the holy sword)


func _ready():
    Manager.play_bgm(preload("res://bgm/musmus/MusMus-BGM-070.mp3"))
    Manager.do_fade_anim(false, false, 0)
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    Manager.wipe_fade_in()
    if Manager.fading:
        yield(Manager, "fade_completed")
    var player = Scheduler.find_player()
    TextBubble.build(player.global_position + Vector2(0, -32), intro_text)
