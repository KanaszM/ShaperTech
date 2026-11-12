@icon("resources/icons/st_container.svg")
@tool
class_name STContainer extends Node

#region Exports
@export_tool_button("Build", "MeshInstance3D") var tool_call_build: Callable = build
@export var height_offset: float
@export var build_on_ready: bool = true
#endregion

#region Public Methods
func build() -> void:
	_build_children(self)
#endregion

#region Private Methods
func _ready() -> void:
	if build_on_ready and not STUtils.has_container_ancestor(self):
		build()


func _build_children(origin: Node) -> void:
	for child: Node in origin.get_children():
		if child is STContainer:
			(child as STContainer).build()
			continue
		
		if child is STPolygon:
			(child as STPolygon).build()
		
		elif child is STSlope:
			(child as STSlope).build()
		
		elif child is STWall:
			(child as STWall).build()
		
		elif child is STFloor:
			(child as STFloor).build()
		
		_build_children(child)
#endregion
