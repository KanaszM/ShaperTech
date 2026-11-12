@icon("../resources/icons/st_floor_data.svg")
@tool
class_name STFloorData extends Resource

#region Exports
@export_group("Geometry", "geometry_")
@export_range(-100.0, 100.0, 0.001, "or_greater", "or_less") var geometry_distance: float
@export_range(-360.0, 360.0, 1.0, "degrees") var geometry_rotation: float
@export var geometry_position_offset: Vector3
@export var geometry_sync_visibility: bool = true
@export_range(
	0.001, 128.0, 0.001, "or_greater"
	) var geometry_scale: float = ShaperTech.DEFAULT_GEOMETRY_SCALE

@export_group("Collision", "collision_")
@export var collision_enabled: bool
@export var collision_enabled_in_editor: bool
@export_flags_3d_physics var collision_layer: int = ShaperTech.DEFAULT_COLLISION_LAYER
@export_flags_3d_physics var collision_mask: int = ShaperTech.DEFAULT_COLLISION_MASK
#endregion

#region Public Methods
func get_top_position() -> float:
	return geometry_distance
#endregion
