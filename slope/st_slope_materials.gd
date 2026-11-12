@icon("../resources/icons/st_slope_materials.svg")
@tool
class_name STSlopeMaterials extends Resource

#region Exports / Constants (Slope)
@export_group("Slope", "slope_")
@export var slope_top_enabled: bool = true
@export var slope_double_sided: bool
@export var slope_type: ShaperTech.MaterialType
@export var slope_material: Material
@export var slope_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var slope_tile_horizontal: bool = true
@export var slope_tile_vertical: bool = true
@export var slope_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var slope_rotation: float
#endregion

#region Exports / Constants (Sides)
@export_group("Sides", "sides_")
@export var sides_enabled: bool = true
@export var sides_double_sided: bool
@export var sides_type: ShaperTech.MaterialType
@export var sides_material: Material
@export var sides_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var sides_tile_horizontal: bool = true
@export var sides_tile_vertical: bool = true
@export var sides_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var sides_rotation: float
#endregion

#region Exports / Constants (Back)
@export_group("Back", "back_")
@export var back_enabled: bool
@export var back_double_sided: bool
@export var back_type: ShaperTech.MaterialType
@export var back_material: Material
@export var back_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var back_tile_horizontal: bool = true
@export var back_tile_vertical: bool = true
@export var back_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var back_rotation: float
#endregion

#region Exports / Constants (Bottom)
@export_group("Bottom", "bottom_")
@export var bottom_enabled: bool
@export var bottom_double_sided: bool
@export var bottom_type: ShaperTech.MaterialType
@export var bottom_material: Material
@export var bottom_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var bottom_tile_horizontal: bool = true
@export var bottom_tile_vertical: bool = true
@export var bottom_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var bottom_rotation: float
#endregion

#region Exports / Constants (Override)
@export_group("Override", "override_")
@export var override_type: ShaperTech.MaterialType
@export var override_apply_to_slope: bool
@export var override_apply_to_sides: bool
@export var override_apply_to_back: bool
@export var override_apply_to_bottom: bool
@export var override_material: Material
@export var override_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode
@export var override_tile_horizontal: bool = true
@export var override_tile_vertical: bool = true
@export var override_texture_direction: Vector2 = Vector2.RIGHT
@export_range(-360.0, 360.0, 1.0, "degrees") var override_rotation: float
#endregion

#region Public Methods (Slope)
func get_slope_material() -> Material:
	if not slope_top_enabled and not slope_double_sided:
		return null

	return (
		STUtils.get_material(override_type, override_material)
		if override_apply_to_slope
		else STUtils.get_material(slope_type, slope_material)
		)


func get_slope_reverse_faces_mode() -> ShaperTech.MaterialReverseFacesMode:
	return override_reverse_faces_mode if override_apply_to_slope else slope_reverse_faces_mode


func get_slope_rotation() -> float:
	return override_rotation if override_apply_to_slope else slope_rotation


func get_slope_tile_horizontal() -> bool:
	return override_tile_horizontal if override_apply_to_slope else slope_tile_horizontal


func get_slope_tile_vertical() -> bool:
	return override_tile_vertical if override_apply_to_slope else slope_tile_vertical


func get_slope_texture_direction() -> Vector2:
	return override_texture_direction if override_apply_to_slope else slope_texture_direction
#endregion

#region Public Methods (Sides)
func get_sides_material() -> Material:
	if not sides_enabled and not sides_double_sided:
		return null

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

#region Public Methods (Back)
func get_back_material() -> Material:
	if not back_enabled and not back_double_sided:
		return null

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

#region Public Methods (Bottom)
func get_bottom_material() -> Material:
	if not bottom_enabled and not bottom_double_sided:
		return null

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
