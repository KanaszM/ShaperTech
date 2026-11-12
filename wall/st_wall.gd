@icon("../resources/icons/st_wall.svg")
@tool
class_name STWall extends Line2D

#region Exports
@export_tool_button("Build", "MeshInstance3D") var tool_call_build: Callable = build
@export var data: STWallData: set = _set_data
@export var materials: STWallMaterials: set = _set_materials

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

var _points: PackedVector2Array
var _points_size: int
var _rotation_offset: float
#endregion

#region Public Methods
func build() -> void:
	#region Reset
	_array_mesh = null
	_surface_tool = null
	
	_points.clear()
	
	_points_size = 0
	_rotation_offset = 0.0
	#endregion
	
	#region Updates
	_update_resources()
	_update_parent()
	_update_nodes()
	_update_geometry_and_tools()
	_update_front()
	_update_back()
	_update_mesh()
	_update_collision()
	#endregion


func get_calculated_points() -> PackedVector2Array:
	return _points
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
		data = STWallData.new()
	
	if materials == null:
		materials = STWallMaterials.new()


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
	
	if _points_size < 2:
		return
	
	if data.geometry_scale <= 0.0:
		push_error("STWall geometry_scale must be greater than zero.")
		return
	
	var rotation_transform: Transform2D = Transform2D(
		deg_to_rad(data.geometry_rotation + _rotation_offset), Vector2.ZERO
		)
	var origin: Vector2 = _parent_origin + Vector2(
		data.geometry_position_offset.x, data.geometry_position_offset.z
		)
	
	for point: Vector2 in points:
		_points.append(origin + rotation_transform * point)
	
	_array_mesh = ArrayMesh.new()
	_surface_tool = SurfaceTool.new()


func _update_front() -> void:
	if _points.is_empty() or _surface_tool == null:
		return
	
	var front_material: Material = materials.get_front_material()

	if front_material == null:
		return

	var front_rotation: float = materials.get_front_rotation()
	var front_reverse_faces_mode: ShaperTech.MaterialReverseFacesMode = (
		materials.get_front_reverse_faces_mode()
		)
	var front_reverse_faces: bool = STUtils.get_reverse_faces(front_reverse_faces_mode)
	var front_tile_horizontal: bool = materials.get_front_tile_horizontal()
	var front_tile_vertical: bool = materials.get_front_tile_vertical()
	var front_texture_direction: Vector2 = materials.get_front_texture_direction()
	var accumulated_length: float = 0.0
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(front_material)
	
	for point_idx: int in range(_points_size - 1):
		var point_0: Vector2 = _points[point_idx] / data.geometry_scale
		var point_1: Vector2 = _points[point_idx + 1] / data.geometry_scale
		
		var segment_length: float = point_1.distance_to(point_0)
		
		var bottom_0: Vector3 = _get_bottom_vertex(point_0)
		var bottom_1: Vector3 = _get_bottom_vertex(point_1)
		var top_0: Vector3 = _get_top_vertex(point_1, true)
		var top_1: Vector3 = _get_top_vertex(point_0, false)
		
		var left_height: float = bottom_0.distance_to(top_1)
		var right_height: float = bottom_1.distance_to(top_0)
		
		var uv_0: Vector2 = STUtils.get_rotated_uv(
			Vector2(accumulated_length, left_height),
			Vector2(accumulated_length, 0.0),
			segment_length,
			left_height,
			front_tile_horizontal,
			front_tile_vertical,
			front_texture_direction,
			front_rotation
			)
		var uv_1: Vector2 = STUtils.get_rotated_uv(
			Vector2(accumulated_length + segment_length, right_height),
			Vector2(accumulated_length, 0.0),
			segment_length,
			right_height,
			front_tile_horizontal,
			front_tile_vertical,
			front_texture_direction,
			front_rotation
			)
		var uv_2: Vector2 = STUtils.get_rotated_uv(
			Vector2(accumulated_length + segment_length, 0.0),
			Vector2(accumulated_length, 0.0),
			segment_length,
			right_height,
			front_tile_horizontal,
			front_tile_vertical,
			front_texture_direction,
			front_rotation
			)
		var uv_3: Vector2 = STUtils.get_rotated_uv(
			Vector2(accumulated_length, 0.0),
			Vector2(accumulated_length, 0.0),
			segment_length,
			left_height,
			front_tile_horizontal,
			front_tile_vertical,
			front_texture_direction,
			front_rotation
			)
		
		STUtils.add_triangle(
			_surface_tool,
			uv_0, bottom_0,
			uv_1, bottom_1,
			uv_2, top_0,
			front_reverse_faces
			)
		STUtils.add_triangle(
			_surface_tool,
			uv_0, bottom_0,
			uv_2, top_0,
			uv_3, top_1,
			front_reverse_faces
			)
		accumulated_length += segment_length
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _update_back() -> void:
	if _points.is_empty() or _surface_tool == null:
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
	var accumulated_length: float = 0.0
	
	_surface_tool.clear()
	_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surface_tool.set_material(back_material)
	
	for point_idx: int in range(_points_size - 1):
		var point_0: Vector2 = _points[point_idx] / data.geometry_scale
		var point_1: Vector2 = _points[point_idx + 1] / data.geometry_scale
		
		var segment_length: float = point_1.distance_to(point_0)
		
		var bottom_0: Vector3 = _get_bottom_vertex(point_0)
		var bottom_1: Vector3 = _get_bottom_vertex(point_1)
		
		var top_0: Vector3 = _get_top_vertex(point_1, true)
		var top_1: Vector3 = _get_top_vertex(point_0, false)
		
		var left_height: float = bottom_0.distance_to(top_1)
		var right_height: float = bottom_1.distance_to(top_0)
		
		var uv_0: Vector2 = STUtils.get_rotated_uv(
			Vector2(accumulated_length, left_height),
			Vector2(accumulated_length, 0.0),
			segment_length,
			left_height,
			back_tile_horizontal,
			back_tile_vertical,
			back_texture_direction,
			back_rotation
			)
		var uv_1: Vector2 = STUtils.get_rotated_uv(
			Vector2(accumulated_length + segment_length, right_height),
			Vector2(accumulated_length, 0.0),
			segment_length,
			right_height,
			back_tile_horizontal,
			back_tile_vertical,
			back_texture_direction,
			back_rotation
			)
		var uv_2: Vector2 = STUtils.get_rotated_uv(
			Vector2(accumulated_length + segment_length, 0.0),
			Vector2(accumulated_length, 0.0),
			segment_length,
			right_height,
			back_tile_horizontal,
			back_tile_vertical,
			back_texture_direction,
			back_rotation
			)
		var uv_3: Vector2 = STUtils.get_rotated_uv(
			Vector2(accumulated_length, 0.0),
			Vector2(accumulated_length, 0.0),
			segment_length,
			left_height,
			back_tile_horizontal,
			back_tile_vertical,
			back_texture_direction,
			back_rotation
			)
		
		STUtils.add_triangle(
			_surface_tool,
			uv_3, top_1,
			uv_2, top_0,
			uv_1, bottom_1,
			back_reverse_faces
			)
		STUtils.add_triangle(
			_surface_tool,
			uv_3, top_1,
			uv_1, bottom_1,
			uv_0, bottom_0,
			back_reverse_faces
			)
		accumulated_length += segment_length
	
	STUtils.finish_surface(_surface_tool, _array_mesh)


func _get_bottom_vertex(point: Vector2) -> Vector3:
	return Vector3(
		point.x,
		data.geometry_skew_y if data.geometry_skew_y_reversed else 0.0,
		point.y + data.geometry_skew_z if data.geometry_skew_z_reversed else point.y
		)


func _get_top_vertex(point: Vector2, at_segment_end: bool) -> Vector3:
	var top_height: float = data.geometry_height
	var depth: float = point.y
	
	if data.geometry_skew_y_reversed != at_segment_end:
		top_height += data.geometry_skew_y
	
	if not data.geometry_skew_z_reversed:
		depth -= data.geometry_skew_z
	
	return Vector3(point.x, top_height, depth)


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
		data.collision_mask
		)


func _set_data(arg: STWallData) -> void:
	data = STWallData.new() if arg == null else arg


func _set_materials(arg: STWallMaterials) -> void:
	materials = STWallMaterials.new() if arg == null else arg
#endregion
