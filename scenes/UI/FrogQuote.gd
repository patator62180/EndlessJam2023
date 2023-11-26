extends Node2D

@export var bubble = Node2D
var quotes
var quoteindex

func _ready():
    $TimerWait.start()
    bubble.visible = false
    quotes = ["This is very special to me. I can describe it, but I cannot explain it.", "If it were sufficient to push a rock, things would be too easy.", "You know, when you look at it, the world is a foreign and strange place...", "...It is not reasonable, that is all that can be said.", "Sometimes, to understand the world, you have to turn away from it.", "True knowledge is impossible and rationality cannot explain everything.", "We build our life on the hope for tomorrow...", "...Yet tomorrow brings us closer to death and is the ultimate enemy.", "Existence is illusory. Or is it eternal?", "Without frogs, the absurd cannot exist.", "The frog of today works every day in his life at the same tasks. And my fate is no less absurd.", "When you think about it, this is a very tragic situation.", "I guess this task is futile and my fate is set in stone.", "Speaking of stone, my face drudges so close to this rock that it is already stone itself!", "You know what?...This situation is absurd, but I've learned to accept it.", "There is scarcely any passion without struggle.", "There is no greater meaning in life but what we give it.", "All is well. I am happy."]
    quoteindex = 0
    $FrogTalk.stop()
    
func _on_timer_timeouttalk():
    $TimerWait.start()
    bubble.visible = false
    $FrogTalk.stop()

func _on_timer_timeoutwait():
    $TimerTalk.start()
    bubble.visible = true
    $SpeechBubble/MarginContainer/Quote.text = quotes[quoteindex]
    quoteindex = quoteindex+1
    if quoteindex >= quotes.size():
        quoteindex = 0
    $FrogTalk.play()
