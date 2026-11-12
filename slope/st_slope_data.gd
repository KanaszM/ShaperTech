@icon("../resources/icons/st_slope_data.svg")
@tool
class_name STSlopeData extends Resource

#region Exports
@export_group("Geometry", "geometry_")
@export_range(-100.0, 100.0, 0.001, "or_greater", "or_less") var geometry_distance: float
@export_range(0.0, 100.0, 0.001, "or_greater") var geometry_height: float = 2.0
@export_range(0.0, 100.0, 0.001, "or_greater") var geometry_width: float = 2.0
@export var geometry_reverse_points: bool
@export var geometry_flipped: bool
@export_range(-360.0, 360.0, 1.0, "degrees") var geometry_rotation: float
@export var geometry_position_offset: Vector3
@export var geometry_sync_visibility: bool = true
@export_range(
	0.001, 128.0, 0.001, "or_greater"
	) var geometry_scale: float = ShaperTech.DEFAULT_GEOMETRY_SCALE

@export_subgroup("Curve", "geometry_curve_")
@export_range(-1.0, 1.0, 0.001) var geometry_curve_value: float
@export_range(0.0, 64.0, 1.0, "or_greater") var geometry_curve_segments: int = 16
@export_range(1.0, 8.0, 0.01, "or_greater") var geometry_curve_strength: float = 3.0

@export_subgroup("Corners", "geometry_corner_")
@export_range(0.0, 1.0, 0.001) var geometry_corner_left: float
@export_range(0.0, 1.0, 0.001) var geometry_corner_right: float

@export_group("Collision", "collision_")
@export var collision_enabled: bool
@export var collision_enabled_in_editor: bool
@export_flags_3d_physics var collision_layer: int = ShaperTech.DEFAULT_COLLISION_LAYER
@export_flags_3d_physics var collision_mask: int = ShaperTech.DEFAULT_COLLISION_MASK
#endregion

#region Public Methods
func get_top_position() -> float:
	return geometry_distance + geometry_height
#endregion
