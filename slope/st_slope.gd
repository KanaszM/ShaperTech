@icon("../resources/icons/st_slope.svg")
@tool
class_name STSlope extends Line2D

#region Exports
@export_tool_button("Build", "MeshInstance3D") var tool_call_build: Callable = build
@export var data: STSlopeData: set = _set_data
@export var materials: STSlopeMaterials: set = _set_materials

@export_group("Build", "build_")
@export var build_on_ready: ShaperTech.BuildOnReadyType
@export var build_mode: ShaperTech.BuildMode
@export_range(
	0.001, 10.0, 0.001, "or_greater"
	) var build_automatic_interval: float = ShaperTech.DEFAULT_BUILD_AUTOMATIC_INTERVAL

@export_subgroup("Nodes", "build_nodes_")
@export var build_nodes_in_editor: bool
@export var build_nodes_deferred: bool = true

@export_group("Parent", "parent_")
@export var parent_custom_node: Node
@export var parent_sync_position: bool = true
#endregion

#region Private Variables
var _is_editor: bool

var _parent: Node
var _parent_origin: Vector2

var _mesh: STMesh
var _array_mesh: ArrayMesh
var _surface_tool: SurfaceTool
var _update_timer: STTimer

var _slope_left: PackedVector3Array
var _slope_right: PackedVector3Array
var _flat_left: PackedVector3Array
var _flat_right: PackedVector3Array
var _slope_distances_left: PackedFloat32Array
var _slope_distances_right: PackedFloat32Array
var _polygon_points: PackedVector2Array
var _polygon_border: PackedVector2Array

var _points_size: int
var _curve_segments: int
var _point_length: float
var _rotation_offset: float
#endregion

#region Public Methods
func build() -> void:
	#region Reset
	_array_mesh = null
	_surface_tool = null
	
	_slope_left.clear()
	_slope_right.clear()
	_flat_left.clear()
	_flat_right.clear()
	_slope_distances_left.clear()
	_slope_distances_right.clear()
	_polygon_points.clear()
	_polygon_border.clear()
	
	_points_size = 0
	_curve_segments = 0
	_point_length = 0.0
	_rotation_offset = 0.0
	#endregion
	
	#region Updates
	_update_resources()
	_update_parent()
	_update_nodes()
	_update_geometry_and_tools()
	_update_slope()
	_update_sides()
	_update_front()
	_update_back()
	_update_bottom()
	_update_mesh()
	_update_collision()
	#endregion


func get_polygon_points() -> PackedVector2Array:
	return _polygon_points


func get_polygon_border() -> PackedVector2Array:
	return _polygon_border
#endregion

#region Private Methods
func _notification(what: int) -> void:
	if not _is_editor or _mesh == null or data == null:
		return
	
	match what:
		NOTIFICATION_VISIBILITY_CHANGED when data.geometry_sync_visibility:
			_mesh.visible = is_visible_in_tree()


func _ready() -> void:
	_is_editor = Engine.is_editor_hint()
	_update_resources()
	
	if STUtils.has_container_ancestor(self):
		return
	
	match build_on_ready:
		ShaperTech.BuildOnReadyType.EDITOR_ONLY when _is_editor: build()
		ShaperTech.BuildOnReadyType.ALWAYS: build()


func _update_resources() -> void:
	if data == null:
		data = STSlopeData.new()
	
	if materials == null:
		materials = STSlopeMaterials.new()


func _update_parent() -> void:
	_parent = self if parent_custom_node == null else parent_custom_node
	_parent_origin = STUtils.get_parent_origin(
		self,
		_parent,
		parent_sync_position,
		data.geometry_scale
		)


func _update_nodes() -> void:
	_mesh = STUtils.update_mesh_node(
		self,
		_parent,
		_mesh,
		build_nodes_in_editor,
		build_nodes_deferred
		)
	_update_timer = STUtils.update_timer_node(
		self,
		_parent,
		_update_timer,
		build_mode,
		build_automatic_interval,
		build_nodes_in_editor,
		build_nodes_deferred
		)


func _update_geometry_and_tools() -> void:
	_points_size = points.size()
	
	if _points_size != 2:
		return
	
	if data.geometry_scale <= 0.0:
		push_error("STSlope geometry_scale must be greater than zero.")
		return
	
	var rotation_transform: Transform2D = Transform2D(
		deg_to_rad(data.geometry_rotation + _rotation_offset), Vector2.ZERO
		)
	
	var point_origin: Vector2 = _parent_origin + Vector2(
		data.geometry_position_offset.x, data.geometry_position_offset.z
		)
	var point_a: Vector2 = points[1] if data.geometry_reverse_points else points[0]
	var point_b: Vector2 = points[0] if data.geometry_reverse_points else points[1]
	var point_0: Vector2 = (point_origin + rotation_transform * point_a) / data.geometry_scale
	var point_1: Vector2 = (point_origin + rotation_transform * point_b) / data.geometry_scale
	var point_difference: Vector2 = point_1 - point_0
	var point_direction: Vector2 = point_difference.normalized()
	
	var half_width: float = data.geometry_width / 2.0
	var perpendicular: Vector2 = Vector2(-point_direction.y, point_direction.x)
	var width_offset: Vector3 = Vector3(perpendicular.x, 0.0, perpendicular.y) * half_width
	var flat_height: float = data.geometry_height if data.geometry_flipped else 0.0
	
	var accumulated_distance_left: float = 0.0
	var accumulated_distance_right: float = 0.0
	
	var corner_left: float = clampf(data.geometry_corner_left, 0.0, 1.0)
	var corner_right: float = clampf(data.geometry_corner_right, 0.0, 1.0)
	
	_point_length = point_difference.length()
	_curve_segments = maxi(1, data.geometry_curve_segments)
	
	for point_idx: int in range(_curve_segments + 1):
		var t: float = float(point_idx) / float(_curve_segments)
		var curve_progress: float = lerpf(
			t, pow(t, data.geometry_curve_strength), data.geometry_curve_value
			)
		var left_height: float = data.geometry_height * lerpf(corner_left, 1.0, curve_progress)
		var right_height: float = data.geometry_height * lerpf(corner_right, 1.0, curve_progress)
		
		if data.geometry_flipped:
			left_height = data.geometry_height * lerpf(1.0, corner_left, curve_progress)
			right_height = data.geometry_height * lerpf(1.0, corner_right, curve_progress)
		
		var position_2d: Vector2 = point_0.lerp(point_1, t)
		var slope_position_left: Vector3 = Vector3(position_2d.x, left_height, position_2d.y)
		var slope_position_right: Vector3 = Vector3(position_2d.x, right_height, position_2d.y)
		var flat_position: Vector3 = Vector3(position_2d.x, flat_height, position_2d.y)
		
		_slope_left.append(slope_position_left - width_offset)
		_slope_right.append(slope_position_right + width_offset)
		_flat_left.append(flat_position - width_offset)
		_flat_right.append(flat_position + width_offset)
		
		if point_idx == 0:
			_slope_distances_left.append(0.0)
			_slope_distances_right.append(0.0)
		
		else:
			accumulated_distance_left += _slope_left[point_idx].distance_to(
				_slope_left[point_idx - 1]
				)
			accumulated_distance_right += _slope_right[point_idx].distance_to(
				_slope_right[point_idx - 1]
				)
			_slope_distances_left.append(accumulated_distance_left)
			_slope_distances_right.append(accumulated_distance_right)
	
	_array_mesh = ArrayMesh.new()
	_surface_tool = SurfaceTool.new()
	
	var origin_direction: Vector2 = (point_b - point_a).normalized()
	var origin_normal: Vector2 = Vector2(
		-origin_direction.y, origin_direction.x
		) * (data.geometry_width * data.geometry_scale / 2.0)
	var polygon_point_1: Vector2 = point_a + origin_normal
	var polygon_point_2: Vector2 = point_b + origin_normal
	var polygon_point_3: Vector2 = point_b - origin_normal
	var polygon_point_4: Vector2 = point_a - origin_normal
	
	_polygon_points = PackedVector2Array([
		polygon_point_1, polygon_point_2, polygon_point_3, polygon_point_4,
		])
	_polygon_border = PackedVector2Array([
		polygon_point_1, polygon_point_2, polygon_point_3, polygon_point_4, polygon_point_1,
		])
	
	queue_redraw()


func _update_slope() -> void:
	if _surface_tool == null:
		return
	
	var slope_material: Material = materials.get_slope_material()
	
	if slope_material == null:
		return
	
	var slope_rotation: float = materials.get_slope_rotation()
	var slope_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode = (
		materials.get_slope_reverse_faces_mode()
		)
	var slope_reverse_faces: bool = STUtils.get_reverse_faces(slope_reverse_faces_mode)
	var slope_tile_horizontal: bool = materials.get_slope_tile_horizontal()
	var slope_tile_vertical: bool = materials.get_slope_tile_vertical()
	var slope_texture_direction: Vector2 = materials.get_slope_texture_direction()
	var slope_length_left: float = _slope_distances_left[-1]
	var slope_length_right: float = _slope_distances_right[-1]
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(slope_material)
	
	for point_idx: int in _curve_segments:
		var uv_0: Vector2 = STUtils.get_rotated_uv(
			Vector2(0.0, _slope_distances_left[point_idx]),
			Vector2.ZERO,
			data.geometry_width,
			slope_length_left,
			slope_tile_horizontal,
			slope_tile_vertical,
			slope_texture_direction,
			slope_rotation
			)
		var uv_1: Vector2 = STUtils.get_rotated_uv(
			Vector2(data.geometry_width, _slope_distances_right[point_idx]),
			Vector2.ZERO,
			data.geometry_width,
			slope_length_right,
			slope_tile_horizontal,
			slope_tile_vertical,
			slope_texture_direction,
			slope_rotation
			)
		var uv_2: Vector2 = STUtils.get_rotated_uv(
			Vector2(data.geometry_width, _slope_distances_right[point_idx + 1]),
			Vector2.ZERO,
			data.geometry_width,
			slope_length_right,
			slope_tile_horizontal,
			slope_tile_vertical,
			slope_texture_direction,
			slope_rotation
			)
		var uv_3: Vector2 = STUtils.get_rotated_uv(
			Vector2(0.0, _slope_distances_left[point_idx + 1]),
			Vector2.ZERO,
			data.geometry_width,
			slope_length_left,
			slope_tile_horizontal,
			slope_tile_vertical,
			slope_texture_direction,
			slope_rotation
			)
		var reverse_faces: bool = slope_reverse_faces != (not data.geometry_flipped)
		
		if materials.slope_top_enabled:
			STUtils.add_quad(
				_surface_tool,
				uv_0, _slope_left[point_idx],
				uv_1, _slope_right[point_idx],
				uv_2, _slope_right[point_idx + 1],
				uv_3, _slope_left[point_idx + 1],
				reverse_faces
				)
		
		if materials.slope_double_sided:
			STUtils.add_quad(
				_surface_tool,
				uv_0, _slope_left[point_idx],
				uv_1, _slope_right[point_idx],
				uv_2, _slope_right[point_idx + 1],
				uv_3, _slope_left[point_idx + 1],
				not reverse_faces
				)
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _update_sides() -> void:
	if _surface_tool == null:
		return
	
	var sides_material: Material = materials.get_sides_material()
	
	if sides_material == null:
		return
	
	var sides_rotation: float = materials.get_sides_rotation()
	var sides_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode = (
		materials.get_sides_reverse_faces_mode()
		)
	var sides_reverse_faces: bool = STUtils.get_reverse_faces(sides_reverse_faces_mode)
	var sides_tile_horizontal: bool = materials.get_sides_tile_horizontal()
	var sides_tile_vertical: bool = materials.get_sides_tile_vertical()
	var sides_texture_direction: Vector2 = materials.get_sides_texture_direction()
	var flat_height: float = data.geometry_height if data.geometry_flipped else 0.0
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(sides_material)
	
	for side_idx: int in 2:
		var slope_points: PackedVector3Array = _slope_left if side_idx == 0 else _slope_right
		var flat_points: PackedVector3Array = _flat_left if side_idx == 0 else _flat_right
		var reverse_faces: bool = sides_reverse_faces != data.geometry_flipped
		
		if side_idx == 1:
			reverse_faces = not reverse_faces
		
		for point_idx: int in _curve_segments:
			var t0: float = float(point_idx) / float(_curve_segments)
			var t1: float = float(point_idx + 1) / float(_curve_segments)
			var uv_0: Vector2 = STUtils.get_rotated_uv(
				Vector2(_point_length * t0, flat_height),
				Vector2.ZERO,
				_point_length,
				data.geometry_height,
				sides_tile_horizontal,
				sides_tile_vertical,
				sides_texture_direction,
				sides_rotation
				)
			var uv_1: Vector2 = STUtils.get_rotated_uv(
				Vector2(_point_length * t1, flat_height),
				Vector2.ZERO,
				_point_length,
				data.geometry_height,
				sides_tile_horizontal,
				sides_tile_vertical,
				sides_texture_direction,
				sides_rotation
				)
			var uv_2: Vector2 = STUtils.get_rotated_uv(
				Vector2(_point_length * t1, slope_points[point_idx + 1].y),
				Vector2.ZERO,
				_point_length,
				data.geometry_height,
				sides_tile_horizontal,
				sides_tile_vertical,
				sides_texture_direction,
				sides_rotation
				)
			var uv_3: Vector2 = STUtils.get_rotated_uv(
				Vector2(_point_length * t0, slope_points[point_idx].y),
				Vector2.ZERO,
				_point_length,
				data.geometry_height,
				sides_tile_horizontal,
				sides_tile_vertical,
				sides_texture_direction,
				sides_rotation
				)
			
			if materials.sides_enabled:
				STUtils.add_quad(
					_surface_tool,
					uv_0, flat_points[point_idx],
					uv_1, flat_points[point_idx + 1],
					uv_2, slope_points[point_idx + 1],
					uv_3, slope_points[point_idx],
					reverse_faces
					)
			
			if materials.sides_double_sided:
				STUtils.add_quad(
					_surface_tool,
					uv_0, flat_points[point_idx],
					uv_1, flat_points[point_idx + 1],
					uv_2, slope_points[point_idx + 1],
					uv_3, slope_points[point_idx],
					not reverse_faces
					)
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _update_front() -> void:
	if _surface_tool == null:
		return
	
	if _slope_left[0].y == _flat_left[0].y and _slope_right[0].y == _flat_right[0].y:
		return
	
	var front_material: Material = materials.get_sides_material()
	
	if front_material == null:
		return
	
	var front_rotation: float = materials.get_sides_rotation()
	var front_tile_horizontal: bool = materials.get_sides_tile_horizontal()
	var front_tile_vertical: bool = materials.get_sides_tile_vertical()
	var front_texture_direction: Vector2 = materials.get_sides_texture_direction()
	
	var reverse_faces: bool = (
		STUtils.get_reverse_faces(materials.get_sides_reverse_faces_mode())
		!= (not data.geometry_flipped)
		)
	
	var uv_0: Vector2 = STUtils.get_rotated_uv(
		Vector2(0.0, _flat_left[0].y),
		Vector2.ZERO,
		data.geometry_width,
		data.geometry_height,
		front_tile_horizontal,
		front_tile_vertical,
		front_texture_direction,
		front_rotation
		)
	var uv_1: Vector2 = STUtils.get_rotated_uv(
		Vector2(data.geometry_width, _flat_right[0].y),
		Vector2.ZERO,
		data.geometry_width,
		data.geometry_height,
		front_tile_horizontal,
		front_tile_vertical,
		front_texture_direction,
		front_rotation
		)
	var uv_2: Vector2 = STUtils.get_rotated_uv(
		Vector2(data.geometry_width, _slope_right[0].y),
		Vector2.ZERO,
		data.geometry_width,
		data.geometry_height,
		front_tile_horizontal,
		front_tile_vertical,
		front_texture_direction,
		front_rotation
		)
	var uv_3: Vector2 = STUtils.get_rotated_uv(
		Vector2(0.0, _slope_left[0].y),
		Vector2.ZERO,
		data.geometry_width,
		data.geometry_height,
		front_tile_horizontal,
		front_tile_vertical,
		front_texture_direction,
		front_rotation
		)
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(front_material)
	
	if materials.sides_enabled:
		STUtils.add_quad(
			_surface_tool,
			uv_0, _flat_left[0],
			uv_1, _flat_right[0],
			uv_2, _slope_right[0],
			uv_3, _slope_left[0],
			reverse_faces
			)
	
	if materials.sides_double_sided:
		STUtils.add_quad(
			_surface_tool,
			uv_0, _flat_left[0],
			uv_1, _flat_right[0],
			uv_2, _slope_right[0],
			uv_3, _slope_left[0],
			not reverse_faces
			)
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _update_back() -> void:
	if _surface_tool == null:
		return
	
	if _slope_left[-1].y == _flat_left[-1].y and _slope_right[-1].y == _flat_right[-1].y:
		return
	
	var back_material: Material = materials.get_back_material()
	
	if back_material == null:
		return
	
	var back_rotation: float = materials.get_back_rotation()
	var back_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode = (
		materials.get_back_reverse_faces_mode()
		)
	var back_reverse_faces: bool = STUtils.get_reverse_faces(back_reverse_faces_mode)
	var back_tile_horizontal: bool = materials.get_back_tile_horizontal()
	var back_tile_vertical: bool = materials.get_back_tile_vertical()
	var back_texture_direction: Vector2 = materials.get_back_texture_direction()
	
	var uv_0: Vector2 = STUtils.get_rotated_uv(
		Vector2(0.0, _flat_left[-1].y),
		Vector2.ZERO,
		data.geometry_width,
		data.geometry_height,
		back_tile_horizontal,
		back_tile_vertical,
		back_texture_direction,
		back_rotation
		)
	var uv_1: Vector2 = STUtils.get_rotated_uv(
		Vector2(data.geometry_width, _flat_right[-1].y),
		Vector2.ZERO,
		data.geometry_width,
		data.geometry_height,
		back_tile_horizontal,
		back_tile_vertical,
		back_texture_direction,
		back_rotation
		)
	var uv_2: Vector2 = STUtils.get_rotated_uv(
		Vector2(data.geometry_width, _slope_right[-1].y),
		Vector2.ZERO,
		data.geometry_width,
		data.geometry_height,
		back_tile_horizontal,
		back_tile_vertical,
		back_texture_direction,
		back_rotation
		)
	var uv_3: Vector2 = STUtils.get_rotated_uv(
		Vector2(0.0, _slope_left[-1].y), Vector2.ZERO, data.geometry_width, data.geometry_height,
		back_tile_horizontal, back_tile_vertical, back_texture_direction, back_rotation
		)
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(back_material)
	
	var reverse_faces: bool = back_reverse_faces != data.geometry_flipped
	
	if materials.back_enabled:
		STUtils.add_quad(
			_surface_tool,
			uv_0, _flat_left[-1],
			uv_1, _flat_right[-1],
			uv_2, _slope_right[-1],
			uv_3, _slope_left[-1],
			reverse_faces
			)
	
	if materials.back_double_sided:
		STUtils.add_quad(
			_surface_tool,
			uv_0, _flat_left[-1],
			uv_1, _flat_right[-1],
			uv_2, _slope_right[-1],
			uv_3, _slope_left[-1],
			not reverse_faces
			)
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _update_bottom() -> void:
	if _surface_tool == null:
		return
	
	var bottom_material: Material = materials.get_bottom_material()
	
	if bottom_material == null:
		return
	
	var bottom_rotation: float = materials.get_bottom_rotation()
	var bottom_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode = (
		materials.get_bottom_reverse_faces_mode()
		)
	var bottom_reverse_faces: bool = STUtils.get_reverse_faces(bottom_reverse_faces_mode)
	var bottom_tile_horizontal: bool = materials.get_bottom_tile_horizontal()
	var bottom_tile_vertical: bool = materials.get_bottom_tile_vertical()
	var bottom_texture_direction: Vector2 = materials.get_bottom_texture_direction()
	
	var uv_0: Vector2 = STUtils.get_rotated_uv(
		Vector2.ZERO,
		Vector2.ZERO,
		data.geometry_width,
		_point_length,
		bottom_tile_horizontal,
		bottom_tile_vertical,
		bottom_texture_direction,
		bottom_rotation
		)
	var uv_1: Vector2 = STUtils.get_rotated_uv(
		Vector2(data.geometry_width, 0.0),
		Vector2.ZERO,
		data.geometry_width,
		_point_length,
		bottom_tile_horizontal,
		bottom_tile_vertical,
		bottom_texture_direction,
		bottom_rotation
		)
	var uv_2: Vector2 = STUtils.get_rotated_uv(
		Vector2(data.geometry_width, _point_length),
		Vector2.ZERO,
		data.geometry_width,
		_point_length,
		bottom_tile_horizontal,
		bottom_tile_vertical,
		bottom_texture_direction,
		bottom_rotation
		)
	var uv_3: Vector2 = STUtils.get_rotated_uv(
		Vector2(0.0, _point_length),
		Vector2.ZERO,
		data.geometry_width,
		_point_length,
		bottom_tile_horizontal,
		bottom_tile_vertical,
		bottom_texture_direction,
		bottom_rotation
		)
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(bottom_material)
	
	if data.geometry_flipped:
		if materials.bottom_enabled:
			STUtils.add_triangle(
				_surface_tool,
				uv_0, _flat_left[0],
				uv_2, _flat_right[-1],
				uv_1, _flat_right[0],
				bottom_reverse_faces
				)
			STUtils.add_triangle(
				_surface_tool,
				uv_0, _flat_left[0],
				uv_3, _flat_left[-1],
				uv_2, _flat_right[-1],
				bottom_reverse_faces
				)
		
		if materials.bottom_double_sided:
			STUtils.add_triangle(
				_surface_tool,
				uv_0, _flat_left[0],
				uv_2, _flat_right[-1],
				uv_1, _flat_right[0],
				not bottom_reverse_faces
				)
			STUtils.add_triangle(
				_surface_tool,
				uv_0, _flat_left[0],
				uv_3, _flat_left[-1],
				uv_2, _flat_right[-1],
				not bottom_reverse_faces
				)
	
	else:
		if materials.bottom_enabled:
			STUtils.add_triangle(
				_surface_tool,
				uv_0, _flat_left[0],
				uv_1, _flat_right[0],
				uv_2, _flat_right[-1],
				bottom_reverse_faces
				)
			STUtils.add_triangle(
				_surface_tool,
				uv_0, _flat_left[0],
				uv_2, _flat_right[-1],
				uv_3, _flat_left[-1],
				bottom_reverse_faces
				)
		
		if materials.bottom_double_sided:
			STUtils.add_triangle(
				_surface_tool,
				uv_0, _flat_left[0],
				uv_1, _flat_right[0],
				uv_2, _flat_right[-1],
				not bottom_reverse_faces
				)
			STUtils.add_triangle(
				_surface_tool,
				uv_0, _flat_left[0],
				uv_2, _flat_right[-1],
				uv_3, _flat_left[-1],
				not bottom_reverse_faces
				)
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _update_mesh() -> void:
	if _mesh == null:
		return
	
	_mesh.mesh = _array_mesh
	_mesh.position.y = (
		data.geometry_distance
		+ data.geometry_position_offset.y
		+ STUtils.get_container_height_offset(self)
		)
	_mesh.visible = is_visible_in_tree() if data.geometry_sync_visibility else true


func _update_collision() -> void:
	STUtils.update_collision(
		_mesh,
		data.collision_enabled and (not _is_editor or data.collision_enabled_in_editor),
		data.collision_layer,
		data.collision_mask,
		build_nodes_in_editor,
		build_nodes_deferred
		)


func _draw() -> void:
	if not _is_editor or _polygon_points.is_empty():
		return
	
	var polygon_uv: PackedVector2Array = PackedVector2Array([
		Vector2.ZERO, Vector2.RIGHT, Vector2.RIGHT + Vector2.DOWN, Vector2.DOWN,
		])
	var polygon_colors: PackedColorArray = PackedColorArray([
		default_color, default_color, default_color, default_color,
		])
	
	draw_polygon(_polygon_points, polygon_colors, polygon_uv)


func _set_data(arg: STSlopeData) -> void:
	data = STSlopeData.new() if arg == null else arg


func _set_materials(arg: STSlopeMaterials) -> void:
	materials = STSlopeMaterials.new() if arg == null else arg
#endregion
