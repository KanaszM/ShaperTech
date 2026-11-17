@icon("../resources/icons/st_floor.svg")
@tool
class_name STFloor extends Polygon2D

#region Exports
@export_tool_button("Build", "MeshInstance3D") var tool_call_build: Callable = build
@export var data: STFloorData: set = _set_data
@export var materials: STFloorMaterials: set = _set_materials

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

@export_group("Tools", "tool_")
@export_subgroup("Offset", "tool_offset_")
@export var tool_offset_delta: float
@export var tool_offset_join_type: Geometry2D.PolyJoinType = Geometry2D.PolyJoinType.JOIN_SQUARE
@export_tool_button("Expand", "ZoomMore") var tool_offset_expand: Callable = _execute_tool_offset.bind(true)
@export_tool_button("Shrink", "ZoomLess") var tool_offset_shrink: Callable = _execute_tool_offset.bind(false)

@export_subgroup("Flip", "tool_flip_")
@export_tool_button("Horizontally", "MirrorX") var tool_flip_h: Callable = _execute_tool_flip.bind(true)
@export_tool_button("Vertically", "MirrorY") var tool_flip_v: Callable = _execute_tool_flip.bind(false)

@export_group("Preset", "preset_")
@export_tool_button("Apply", "Reload") var preset_tool_call_apply: Callable = _apply_preset
@export var preset_type: ShaperTech.PresetType
@export var preset_center_point: Vector2

@export_subgroup("Preset/Circle Properties", "preset_circle_")
@export var preset_circle_radius: float
@export var preset_circle_angle_to: float = TAU
@export var preset_circle_angle_from: float
@export_range(3, 128, 1) var preset_circle_detail: int

@export_subgroup("Preset/Rectangle Properties", "preset_rectangle_")
@export var preset_rectangle_size: Vector2
@export var preset_rectangle_corner_radius: float
@export var preset_rectangle_corner_segments: int

@export_subgroup("Preset/Torus Properties", "preset_torus_")
@export var preset_torus_radius: float
@export var preset_torus_thickness: float
@export_range(3, 128, 1) var preset_torus_detail: int
#endregion

#region Private Variables
var _is_editor: bool

var _parent: Node
var _parent_origin: Vector2

var _mesh: STMesh
var _array_mesh: ArrayMesh
var _surface_tool: SurfaceTool
var _update_timer: STTimer

var _points: PackedVector2Array
var _indices: PackedInt32Array

var _points_size: int
var _rotation_offset: float
var _rotation_transform: Transform2D
#endregion

#region Public Methods
func build() -> void:
	#region Reset
	_array_mesh = null
	_surface_tool = null
	
	_points.clear()
	_indices.clear()
	
	_points_size = 0
	_rotation_offset = 0.0
	_rotation_transform = Transform2D.IDENTITY
	#endregion
	
	#region Updates
	_update_resources()
	_update_parent()
	_update_nodes()
	_update_geometry_and_tools()
	_update_top()
	_update_bottom()
	_update_mesh()
	_update_collision()
	#endregion


func get_random_point() -> Vector2:
	return STUtils.get_random_polygon_point(polygon)
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
		data = STFloorData.new()
	
	if materials == null:
		materials = STFloorMaterials.new()


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
	_points_size = polygon.size()
	
	if _points_size < 3:
		return
	
	if data.geometry_scale <= 0.0:
		push_error("STFloor geometry_scale must be greater than zero.")
		return
	
	_rotation_transform = Transform2D(
		deg_to_rad(data.geometry_rotation + _rotation_offset), Vector2.ZERO
		)
	
	var origin: Vector2 = _parent_origin + Vector2(
		data.geometry_position_offset.x, data.geometry_position_offset.z
		)
	
	for point: Vector2 in polygon:
		_points.append((origin + _rotation_transform * point) / data.geometry_scale)
	
	_indices = Geometry2D.triangulate_polygon(_points)
	
	if _indices.is_empty() or _indices.size() % 3 != 0:
		return
	
	_array_mesh = ArrayMesh.new()
	_surface_tool = SurfaceTool.new()


func _update_top() -> void:
	if _points.is_empty() or _surface_tool == null:
		return
	
	var top_material: Material = materials.get_top_material()
	
	if top_material == null:
		return
	
	var top_rotation: float = materials.get_top_rotation()
	var top_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode = (
		materials.get_top_reverse_faces_mode()
		)
	var top_is_reversed: bool = STUtils.get_polygon_reverse_faces(
		top_reverse_faces_mode, _points, _indices
		)
	var top_tile_horizontal: bool = materials.get_top_tile_horizontal()
	var top_tile_vertical: bool = materials.get_top_tile_vertical()
	var top_texture_direction: Vector2 = materials.get_top_texture_direction()
	var min_point: Vector2 = _points[0]
	var max_point: Vector2 = _points[0]
	
	for point: Vector2 in _points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	
	var points_size: Vector2 = max_point - min_point
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(top_material)
	
	for point_idx: int in range(0, _indices.size(), 3):
		var i0: int = _indices[point_idx]
		var i1: int = _indices[point_idx + 1]
		var i2: int = _indices[point_idx + 2]
		
		var p0: Vector2 = STUtils.get_uv(
			_points[i0],
			min_point,
			points_size.x,
			points_size.y,
			top_tile_horizontal,
			top_tile_vertical,
			top_texture_direction
			)
		var p1: Vector2 = STUtils.get_uv(
			_points[i1],
			min_point,
			points_size.x,
			points_size.y,
			top_tile_horizontal,
			top_tile_vertical,
			top_texture_direction
			)
		var p2: Vector2 = STUtils.get_uv(
			_points[i2],
			min_point,
			points_size.x,
			points_size.y,
			top_tile_horizontal,
			top_tile_vertical,
			top_texture_direction
			)
		
		var u0: Vector2 = STUtils.rotate_uv(p0, top_rotation)
		var u1: Vector2 = STUtils.rotate_uv(p1, top_rotation)
		var u2: Vector2 = STUtils.rotate_uv(p2, top_rotation)
		
		var v0: Vector3 = Vector3(
			_points[i0].x,
			0.0,
			_points[i0].y
			)
		var v1: Vector3 = Vector3(
			_points[i1].x,
			0.0,
			_points[i1].y
			)
		var v2: Vector3 = Vector3(
			_points[i2].x,
			0.0,
			_points[i2].y
			)
		
		if top_is_reversed:
			_surface_tool.set_uv(u2); _surface_tool.add_vertex(v2)
			_surface_tool.set_uv(u1); _surface_tool.add_vertex(v1)
			_surface_tool.set_uv(u0); _surface_tool.add_vertex(v0)
		
		else:
			_surface_tool.set_uv(u0); _surface_tool.add_vertex(v0)
			_surface_tool.set_uv(u1); _surface_tool.add_vertex(v1)
			_surface_tool.set_uv(u2); _surface_tool.add_vertex(v2)
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _update_bottom() -> void:
	if _points.is_empty() or _surface_tool == null:
		return
	
	var bottom_material: Material = materials.get_bottom_material()
	
	if bottom_material == null:
		return
	
	var bottom_rotation: float = materials.get_bottom_rotation()
	var bottom_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode = (
		materials.get_bottom_reverse_faces_mode()
		)
	var bottom_is_reversed: bool = STUtils.get_polygon_reverse_faces(
		bottom_reverse_faces_mode, _points, _indices
		)
	var bottom_tile_horizontal: bool = materials.get_bottom_tile_horizontal()
	var bottom_tile_vertical: bool = materials.get_bottom_tile_vertical()
	var bottom_texture_direction: Vector2 = materials.get_bottom_texture_direction()
	var min_point: Vector2 = _points[0]
	var max_point: Vector2 = _points[0]
	
	for point: Vector2 in _points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	
	var points_size: Vector2 = max_point - min_point
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(bottom_material)

	for point_idx: int in range(0, _indices.size(), 3):
		var i0: int = _indices[point_idx]
		var i1: int = _indices[point_idx + 1]
		var i2: int = _indices[point_idx + 2]
		
		var p0: Vector2 = STUtils.get_uv(
			_points[i2],
			min_point,
			points_size.x,
			points_size.y,
			bottom_tile_horizontal,
			bottom_tile_vertical,
			bottom_texture_direction
			)
		var p1: Vector2 = STUtils.get_uv(
			_points[i1],
			min_point,
			points_size.x,
			points_size.y,
			bottom_tile_horizontal,
			bottom_tile_vertical,
			bottom_texture_direction
			)
		var p2: Vector2 = STUtils.get_uv(
			_points[i0],
			min_point,
			points_size.x,
			points_size.y,
			bottom_tile_horizontal,
			bottom_tile_vertical,
			bottom_texture_direction
			)
		
		var u0: Vector2 = STUtils.rotate_uv(p0, bottom_rotation)
		var u1: Vector2 = STUtils.rotate_uv(p1, bottom_rotation)
		var u2: Vector2 = STUtils.rotate_uv(p2, bottom_rotation)
		
		var v0: Vector3 = Vector3(
			_points[i2].x,
			0.0,
			_points[i2].y
			)
		var v1: Vector3 = Vector3(
			_points[i1].x,
			0.0,
			_points[i1].y
			)
		var v2: Vector3 = Vector3(
			_points[i0].x,
			0.0,
			_points[i0].y
			)
		
		if bottom_is_reversed:
			_surface_tool.set_uv(u2); _surface_tool.add_vertex(v2)
			_surface_tool.set_uv(u1); _surface_tool.add_vertex(v1)
			_surface_tool.set_uv(u0); _surface_tool.add_vertex(v0)
		
		else:
			_surface_tool.set_uv(u0); _surface_tool.add_vertex(v0)
			_surface_tool.set_uv(u1); _surface_tool.add_vertex(v1)
			_surface_tool.set_uv(u2); _surface_tool.add_vertex(v2)
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _update_mesh() -> void:
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


func _execute_tool_offset(mode: bool) -> void:
	polygon = STUtils.get_offsetted_polygon(polygon, mode, tool_offset_delta, tool_offset_join_type)


func _execute_tool_flip(mode: bool) -> void:
	polygon = STUtils.get_flipped_polygon(polygon, mode)


func _apply_preset() -> void:
	var points: PackedVector2Array
	
	match preset_type:
		ShaperTech.PresetType.CIRCLE:
			points = STUtils.get_circle_points(
				preset_center_point,
				preset_circle_radius,
				preset_circle_angle_to,
				preset_circle_angle_from,
				preset_circle_detail
				)
		ShaperTech.PresetType.RECTANGLE:
			points = STUtils.get_rectangle_points(
				preset_center_point,
				preset_rectangle_size,
				preset_rectangle_corner_radius,
				preset_rectangle_corner_segments
				)
		ShaperTech.PresetType.TORUS:
			points = STUtils.get_torus_points(
				preset_center_point,
				preset_torus_radius,
				preset_torus_thickness, 
				preset_torus_detail
				)
	
	if points.size() > 2:
		polygon = points


func _set_data(arg: STFloorData) -> void:
	data = STFloorData.new() if arg == null else arg


func _set_materials(arg: STFloorMaterials) -> void:
	materials = STFloorMaterials.new() if arg == null else arg
#endregion
