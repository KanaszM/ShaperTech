@icon("../resources/icons/st_polygon_materials.svg")
@tool
class_name STPolygonMaterials extends Resource

#region Exports / Constants (Top)
@export_group("Top", "top_")
@export var top_type: ShaperTech.MaterialType
@export var top_material: Material
@export var top_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var top_tile_horizontal: bool = true
@export var top_tile_vertical: bool = true
@export var top_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var top_rotation: float
#endregion

#region Exports / Constants (Bottom)
@export_group("Bottom", "bottom_")
@export var bottom_type: ShaperTech.MaterialType
@export var bottom_material: Material
@export var bottom_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var bottom_tile_horizontal: bool = true
@export var bottom_tile_vertical: bool = true
@export var bottom_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var bottom_rotation: float
#endregion

#region Exports / Constants (Sides)
@export_group("Sides", "sides_")
@export var sides_type: ShaperTech.MaterialType
@export var sides_material: Material
@export var sides_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var sides_tile_horizontal: bool = true
@export var sides_tile_vertical: bool = true
@export var sides_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var sides_rotation: float
#endregion

#region Exports / Constants (Override)
@export_group("Override", "override_")
@export var override_type: ShaperTech.MaterialType
@export var override_apply_to_top: bool
@export var override_apply_to_bottom: bool
@export var override_apply_to_sides: bool
@export var override_material: Material
@export var override_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var override_tile_horizontal: bool = true
@export var override_tile_vertical: bool = true
@export var override_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var override_rotation: float
#endregion

#region Public Methods (Top)
func get_top_material() -> Material:
	return (
		STUtils.get_material(override_type, override_material)
		if override_apply_to_top
		else STUtils.get_material(top_type, top_material)
		)


func get_top_reverse_faces_mode() -> ShaperTech.MaterialReverseFacesMode:
	return override_reverse_faces_mode if override_apply_to_top else top_reverse_faces_mode


func get_top_rotation() -> float:
	return override_rotation if override_apply_to_top else top_rotation


func get_top_tile_horizontal() -> bool:
	return override_tile_horizontal if override_apply_to_top else top_tile_horizontal


func get_top_tile_vertical() -> bool:
	return override_tile_vertical if override_apply_to_top else top_tile_vertical


func get_top_texture_direction() -> Vector2:
	return override_texture_direction if override_apply_to_top else top_texture_direction
#endregion

#region Public Methods (Bottom)
func get_bottom_material() -> Material:
	return (
		STUtils.get_material(override_type, override_material)
		if override_apply_to_bottom
		else STUtils.get_material(bottom_type, bottom_material)
		)


func get_bottom_reverse_faces_mode() -> ShaperTech.MaterialReverseFacesMode:
	return override_reverse_faces_mode if override_apply_to_bottom else bottom_reverse_faces_mode


func get_bottom_rotation() -> float:
	return override_rotation if override_apply_to_bottom else bottom_rotation


func get_bottom_tile_horizontal() -> bool:
	return override_tile_horizontal if override_apply_to_bottom else bottom_tile_horizontal


func get_bottom_tile_vertical() -> bool:
	return override_tile_vertical if override_apply_to_bottom else bottom_tile_vertical


func get_bottom_texture_direction() -> Vector2:
	return override_texture_direction if override_apply_to_bottom else bottom_texture_direction
#endregion

#region Public Methods (Sides)
func get_sides_material() -> Material:
	return (
		STUtils.get_material(override_type, override_material)
		if override_apply_to_sides
		else STUtils.get_material(sides_type, sides_material)
		)


func get_sides_reverse_faces_mode() -> ShaperTech.MaterialReverseFacesMode:
	return override_reverse_faces_mode if override_apply_to_sides else sides_reverse_faces_mode


func get_sides_rotation() -> float:
	return override_rotation if override_apply_to_sides else sides_rotation


func get_sides_tile_horizontal() -> bool:
	return override_tile_horizontal if override_apply_to_sides else sides_tile_horizontal


func get_sides_tile_vertical() -> bool:
	return override_tile_vertical if override_apply_to_sides else sides_tile_vertical


func get_sides_texture_direction() -> Vector2:
	return override_texture_direction if override_apply_to_sides else sides_texture_direction
#endregion
