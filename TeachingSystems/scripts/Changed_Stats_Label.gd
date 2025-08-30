extends Label
## This script is attached to a label object which includes a timer. After appearing
## the timer autostarts which when finishing tells the label to delete itself.
## Currently used to show power up or down announcements during gameplay

## This function is connected to the timer. When the timer counts down to 0
## the object queues free.
func _on_timer_timeout():
	queue_free()
