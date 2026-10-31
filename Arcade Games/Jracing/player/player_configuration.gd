extends Resource
class_name PlayerConfiguration

enum PlayerType {
	LocalInput,
	CPU,
	Remote
}

@export var type: PlayerType
@export var vehicle: VehicleData
