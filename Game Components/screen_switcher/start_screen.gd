extends Screen

## call [method Screen.open_dialogue] and wait for a [method ArcadeCabinet.pop_coin]
func open_dialogue():
	super() #This is a bit of jank concurrency, but if it works...
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		await cab.pop_coin()
		done.emit()
