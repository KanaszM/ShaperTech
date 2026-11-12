@icon("../resources/icons/st_wall_materials.svg")
@tool
class_name STWallMaterials extends Resource

#region Exports / Constants (Front)
@export_group("Front", "front_")
@export var front_type: ShaperTech.MaterialType
@export var front_material: Material
@export var front_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var front_tile_horizontal: bool = true
@export var front_tile_vertical: bool = true
@export var front_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var front_rotation: float
#endregion

#region Exports / Constants (Back)
@export_group("Back", "back_")
@export var back_type: ShaperTech.MaterialType
@export var back_material: Material
@export var back_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var back_tile_horizontal: bool = true
@export var back_tile_vertical: bool = true
@export var back_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var back_rotation: float
#endregion

#region Exports / Constants (Override)
@export_group("Override", "override_")
@export var override_type: ShaperTech.MaterialType
@export var override_apply_to_front: bool
@export var override_apply_to_back: bool
@export var override_material: Material
@export var override_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var override_tile_horizontal: bool = true
@export var override_tile_vertical: bool = true
@export var override_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var override_rotation: float
#endregion

#region Public Methods (Front)
func get_front_material() -> Material:
	return (
		STUtils.get_material(override_type, override_material)
		if override_apply_to_front
		else STUtils.get_material(front_type, front_material)
		)


func get_front_reverse_faces_mode() -> ShaperTech.MaterialReverseFacesMode:
	return override_reverse_faces_mode if override_apply_to_front else front_reverse_faces_mode


func get_front_rotation() -> float:
	return override_rotation if override_apply_to_front else front_rotation


func get_front_tile_horizontal() -> bool:
	return override_tile_horizontal if override_apply_to_front else front_tile_horizontal


func get_front_tile_vertical() -> bool:
	return override_tile_vertical if override_apply_to_front else front_tile_vertical


func get_front_texture_direction() -> Vector2:
	return override_texture_direction if override_apply_to_front else front_texture_direction
#endregion

#region Public Methods (Back)
func get_back_material() -> Material:
	return (
		STUtils.get_material(override_type, override_material)
		if override_apply_to_back
		else STUtils.get_material(back_type, back_material)
		)


func get_back_reverse_faces_mode() -> ShaperTech.MaterialReverseFacesMode:
	return override_reverse_faces_mode if override_apply_to_back else back_reverse_faces_mode


func get_back_rotation() -> float:
	return override_rotation if override_apply_to_back else back_rotation


func get_back_tile_horizontal() -> bool:
	return override_tile_horizontal if override_apply_to_back else back_tile_horizontal


func get_back_tile_vertical() -> bool:
	return override_tile_vertical if override_apply_to_back else back_tile_vertical


func get_back_texture_direction() -> Vector2:
	return override_texture_direction if override_apply_to_back else back_texture_direction
#endregion
