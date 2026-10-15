extends RefCounted
class_name DextrousWaiter
## Waits for [Signal]s concurrently.
## This concept almost certainly already exists in Concurrency theory and had a really boring name
## but this one is my invention and I called it [DextrousWaiter] because I thought it was funny

## Emitted when one of the signals has fired
signal advanced

var pending: int = 0

## Create a waiter already watching [param signals].
##
## More can be added later with [method add_signal].
func _init(...signals: Array) -> void:
	for s in signals:
		add_signal(s)

## Add [param sig] to the set being waited on. It must fire once for
## [method wait_until_finished] to return.
func add_signal(sig: Signal) -> void:
	if sig.is_null():
		push_error("DextrousWaiter: cannot wait on a null signal")
		return
	pending += 1
	_wait(sig)

## Suspends until every added signal has fired at least once.
##
## Returns instantly if no signals were added, or if they have all already
## fired. Multiple callers may wait on the same waiter.
func wait_until_finished() -> void:
	while pending > 0:
		await advanced

func _wait(sig: Signal) -> void:
	await sig
	pending -= 1
	advanced.emit()
