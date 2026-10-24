extends AnimationPlayer

var remaining_tickets = 0
var dispensed_tickets = 0
var anim_length: float = 3.333333333
var vend_speed: float = 3.0
@onready
var ticket_stack = $"../TicketStack"
@onready
var scale_pivot = $"../DispenserPivot"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	dispense(70) #test call
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_playing():
		return
	else:
		if remaining_tickets > 0:
			dispenseLoop()
		#else:
		#	takeTickets()
	pass

func dispense(number_of_tickets: int):
	if dispensed_tickets > 0:
		remaining_tickets += number_of_tickets
		#dispenseLoop() #the logic in _process handles this actually. Left here as a reminder if that changes.
	else:
		if number_of_tickets < 20:
			play_section("Take 001", -1, anim_length/20 * number_of_tickets, -1, vend_speed)
		else:
			remaining_tickets = number_of_tickets - 20
			dispensed_tickets = 20
			play_section("Take 001", anim_length/2, -1, -1, vend_speed)
	pass

func dispenseLoop():
	vend_speed = lerpf(1.0, 4.0, clampf((remaining_tickets/200.0), 0, 1.0))
	ticket_stack.scale = Vector3(1.0, dispensed_tickets / 100.0, 1.0)
	scale_pivot.scale = Vector3(1.0, 1.0 - (dispensed_tickets/2500.0), 1.0)
	if remaining_tickets < 10:
		play_section("Take 001", anim_length/2, anim_length/20 * (10 + remaining_tickets), -1, vend_speed)
		remaining_tickets = 0
	else:
		remaining_tickets -= 10
		dispensed_tickets += 10
		play_section("Take 001", anim_length/2, -1, -1, vend_speed)
	pass

func takeTickets():
	ticket_stack.scale = Vector3(0.01, 0.01, 0.01)
	scale_pivot.scale = Vector3(1.0, 1.0, 1.0)
	remaining_tickets = 0
	dispensed_tickets = 0
	play("Take 001")#couldn't find a better way to get back to the start frame
	stop()
	get_section_end_time()
	pass
