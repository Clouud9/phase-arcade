extends Screen

func open_dialogue():
	super() #This is a bit of jank concurrency, but if it works...
	var cab = ArcadeCabinet.get_cabinet(self)
	if cab:
		await cab.pop_coin()
		done.emit()
