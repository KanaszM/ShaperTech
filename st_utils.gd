@icon("resources/icons/st_utils.svg")
@tool
class_name STUtils extends RefCounted

#region Static Methods
static func has_container_ancestor(origin: Node) -> bool:
	var ancestor: Node = origin.get_parent()
	
	while ancestor != null:
		if ancestor is STContainer:
			return true
		
		ancestor = ancestor.get_parent()
	
	return false


static func get_container_height_offset(origin: Node) -> float:
	var height_offset: float = 0.0
	var ancestor: Node = origin.get_parent()
	
	while ancestor != null:
		if ancestor is STContainer:
			height_offset += (ancestor as STContainer).height_offset
		
		ancestor = ancestor.get_parent()
	
	return height_offset


static func get_parent_origin(
	origin: Node2D,
	parent: Node,
	sync_position: bool,
	geometry_scale: float,
	) -> Vector2:
		if not sync_position:
			return origin.global_position
		
		if parent is Control:
			return (parent as Control).global_position
		
		if parent is Node2D:
			return (parent as Node2D).global_position
		
		if parent is Node3D and geometry_scale > 0.0:
			var parent_position: Vector3 = (parent as Node3D).global_position
			
			return (
				origin.global_position
				+ Vector2(parent_position.x, parent_position.z)
				/ geometry_scale
				)
		
		return origin.global_position


static func add_generated_node(
	origin: Node,
	parent: Node,
	save_in_editor: bool,
	deferred: bool,
	) -> void:
		if deferred:
			add_generated_node.call_deferred(origin, parent, save_in_editor, false)
			return
		
		if (
			not is_instance_valid(origin) or not is_instance_valid(parent)
			or origin.is_queued_for_deletion() or parent.is_queued_for_deletion()
			):
				return
		
		parent.add_child(origin)
		
		if save_in_editor and Engine.is_editor_hint():
			origin.owner = parent.get_tree().edited_scene_root


static func update_collision(
	origin: MeshInstance3D,
	enabled: bool,
	layer_value: int,
	mask_value: int
	) -> void:
		if not is_instance_valid(origin):
			return
		
		for child: Node in origin.get_children():
			if child is StaticBody3D:
				origin.remove_child(child)
				child.queue_free()
		
		if not enabled or origin.mesh == null or origin.mesh.get_surface_count() == 0:
			return
		
		var collision_body: StaticBody3D = StaticBody3D.new()
		var collision_shape: CollisionShape3D = CollisionShape3D.new()
		
		collision_body.collision_layer = layer_value
		collision_body.collision_mask = mask_value
		collision_shape.shape = origin.mesh.create_trimesh_shape()
		origin.add_child(collision_body)
		collision_body.add_child(collision_shape)


static func update_mesh_node(
	origin: Node2D,
	parent: Node,
	mesh: STMesh,
	save_in_editor: bool,
	deferred: bool,
	) -> STMesh:
		if not is_instance_valid(mesh):
			for child: Node in parent.get_children():
				if child is STMesh and (child as STMesh).shaper == origin:
					mesh = child as STMesh
					break
		
		if not is_instance_valid(mesh):
			mesh = STMesh.new()
			mesh.shaper = origin
			add_generated_node(mesh, parent, save_in_editor, deferred)
		
		else:
			mesh.mesh = null
		
		return mesh


static func update_timer_node(
	origin: Node2D,
	parent: Node,
	timer: STTimer,
	build_mode: ShaperTech.BuildMode,
	interval: float,
	save_in_editor: bool,
	deferred: bool,
	) -> STTimer:
		if not is_instance_valid(timer):
			for child: Node in parent.get_children():
				if (
					child is STTimer
					and (child as STTimer).shaper == origin
					and not child.is_queued_for_deletion()
					):
						timer = child as STTimer
						break
		
		var is_enabled: bool = (
			build_mode == ShaperTech.BuildMode.AUTOMATIC_ALWAYS
			or (
				build_mode == ShaperTech.BuildMode.AUTOMATIC_EDITOR_ONLY
				and Engine.is_editor_hint()
				)
			)
		
		if not is_enabled:
			if is_instance_valid(timer):
				timer.stop()
				timer.queue_free()
			
			return null
		
		if not is_instance_valid(timer):
			timer = STTimer.new()
			timer.shaper = origin
			timer.timeout.connect(Callable(origin, ShaperTech.METHOD_BUILD))
			add_generated_node(timer, parent, save_in_editor, deferred)
		
		timer.wait_time = maxf(ShaperTech.MIN_TIMER_INTERVAL, interval)
		
		if timer.is_inside_tree():
			timer.start()
		
		else:
			timer.start.call_deferred()
		
		return timer


static func get_material(type: ShaperTech.MaterialType, material: Material) -> Material:
	match type:
		ShaperTech.MaterialType.SOLID:
			return ShaperTech.DEFAULT_MATERIAL_SOLID if material == null else material
		
		ShaperTech.MaterialType.TRANSPARENT:
			return ShaperTech.DEFAULT_MATERIAL_TRANSPARENT
	
	return null


static func get_reverse_faces(mode: ShaperTech.MaterialReverseFacesMode) -> bool:
	return mode == ShaperTech.MaterialReverseFacesMode.ENABLED


static func get_polygon_reverse_faces(
	mode: ShaperTech.MaterialReverseFacesMode,
	points: PackedVector2Array,
	indices: PackedInt32Array,
	) -> bool:
		if mode != ShaperTech.MaterialReverseFacesMode.AUTOMATIC:
			return get_reverse_faces(mode)
		
		if indices.size() < 3:
			return false
		
		var p0: Vector2 = points[indices[0]]
		var p1: Vector2 = points[indices[1]]
		var p2: Vector2 = points[indices[2]]
		
		return (p1 - p0).cross(p2 - p0) < 0.0


static func get_uv(
	point: Vector2,
	origin: Vector2,
	width_value: float,
	height_value: float,
	tile_horizontal: bool,
	tile_vertical: bool,
	texture_direction: Vector2,
	) -> Vector2:
		var direction: Vector2 = texture_direction
		
		if direction.length_squared() < ShaperTech.MIN_DIRECTION_LENGTH:
			direction = Vector2.RIGHT
		
		direction = direction.normalized()
		
		var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
		var local_point: Vector2 = point - origin
		var result: Vector2 = Vector2(local_point.dot(direction), local_point.dot(perpendicular))
		
		if not tile_horizontal:
			var projected_width: float = (
				absf(width_value * direction.x) + absf(height_value * direction.y)
				)
			
			result.x = result.x / projected_width if not is_zero_approx(projected_width) else 0.0
		
		if not tile_vertical:
			var projected_height: float = (
				absf(width_value * perpendicular.x) + absf(height_value * perpendicular.y)
				)
			
			result.y = result.y / projected_height if not is_zero_approx(projected_height) else 0.0
		
		return result


static func get_rotated_uv(
	point: Vector2,
	origin: Vector2,
	width_value: float,
	height_value: float,
	tile_horizontal: bool,
	tile_vertical: bool,
	texture_direction: Vector2,
	rotation_degrees: float,
	) -> Vector2:
		var uv: Vector2 = get_uv(
			point,
			origin,
			width_value,
			height_value,
			tile_horizontal,
			tile_vertical,
			texture_direction
			)
		
		return rotate_uv(uv, rotation_degrees)


static func rotate_uv(uv_coord: Vector2, angle_degrees: float) -> Vector2:
	return uv_coord.rotated(deg_to_rad(angle_degrees))


static func add_triangle(
	st: SurfaceTool,
	uv0: Vector2, v0: Vector3,
	uv1: Vector2, v1: Vector3,
	uv2: Vector2, v2: Vector3,
	reverse_faces: bool,
	) -> void:
		if (v1 - v0).cross(v2 - v0).length_squared() == 0.0:
			return
		
		if reverse_faces:
			st.set_uv(uv2); st.add_vertex(v2)
			st.set_uv(uv1); st.add_vertex(v1)
			st.set_uv(uv0); st.add_vertex(v0)
		
		else:
			st.set_uv(uv0); st.add_vertex(v0)
			st.set_uv(uv1); st.add_vertex(v1)
			st.set_uv(uv2); st.add_vertex(v2)


static func finish_surface(surface_tool: SurfaceTool, array_mesh: ArrayMesh) -> void:
	var surface_arrays: Array = surface_tool.commit_to_arrays()
	
	if surface_arrays.is_empty() or surface_arrays[Mesh.ARRAY_VERTEX] == null:
		return
	
	if surface_arrays[Mesh.ARRAY_VERTEX].is_empty():
		return
	
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	surface_tool.commit(array_mesh)


static func add_quad(
	surface_tool: SurfaceTool,
	uv0: Vector2, v0: Vector3,
	uv1: Vector2, v1: Vector3,
	uv2: Vector2, v2: Vector3,
	uv3: Vector2, v3: Vector3,
	reverse_faces: bool,
	) -> void:
		add_triangle(surface_tool, uv0, v0, uv1, v1, uv2, v2, reverse_faces)
		add_triangle(surface_tool, uv0, v0, uv2, v2, uv3, v3, reverse_faces)


static func get_triangle_area(p0: Vector2, p1: Vector2, p2: Vector2) -> float:
	return absf((p2 - p0).cross(p1 - p0)) / 2.0


static func get_triangle_point(p0: Vector2, p1: Vector2, p2: Vector2) -> Vector2:
	return p0 + sqrt(randf()) * (-p0 + p1 + randf() * (p2 - p1))


static func get_random_polygon_point(points: PackedVector2Array) -> Vector2:
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(points)
	var areas: PackedFloat64Array
	var total_area: float = 0.0
	
	for triangle_idx: int in range(0, indices.size(), 3):
		total_area += get_triangle_area(
			points[indices[triangle_idx]],
			points[indices[triangle_idx + 1]],
			points[indices[triangle_idx + 2]]
			)
		areas.append(total_area)
	
	if total_area <= 0.0:
		return Vector2.ZERO
	
	var triangle: int = mini(areas.bsearch(randf() * total_area), areas.size() - 1) * 3
	
	return get_triangle_point(
		points[indices[triangle]],
		points[indices[triangle + 1]],
		points[indices[triangle + 2]]
		)


static func get_offsetted_polygon(
	points: PackedVector2Array,
	expand: bool,
	distance: float,
	join_type: Geometry2D.PolyJoinType,
	) -> PackedVector2Array:
		if points.is_empty():
			return PackedVector2Array()
		
		var results: Array[PackedVector2Array] = Geometry2D.offset_polygon(
			points, absf(distance) if expand else -absf(distance), join_type
			)
		
		return PackedVector2Array() if results.is_empty() else results[0]


static func get_flipped_polygon(
	points: PackedVector2Array,
	horizontally: bool,
	) -> PackedVector2Array:
		if points.is_empty():
			return PackedVector2Array()
		
		var result: PackedVector2Array = points.duplicate()
		var min_vertex: float = result[0].x if horizontally else result[0].y
		var max_vertex: float = min_vertex
		
		for point: Vector2 in result:
			min_vertex = minf(min_vertex, point.x if horizontally else point.y)
			max_vertex = maxf(max_vertex, point.x if horizontally else point.y)
		
		for point_idx: int in result.size():
			if horizontally:
				result[point_idx].x = min_vertex + max_vertex - result[point_idx].x
			
			else:
				result[point_idx].y = min_vertex + max_vertex - result[point_idx].y
		
		return result


static func get_circle_points(
	center: Vector2,
	radius: float,
	angle_to: float,
	angle_from: float,
	detail: int,
	) -> PackedVector2Array:
		var points: PackedVector2Array
		
		if radius <= 0.0 or detail < 3:
			return points
		
		if angle_to != TAU:
			points.append(center)
		
		var start: float = angle_from - (PI / 2.0)
		var end: float = (angle_to - angle_from) / float(detail)
		
		for detail_idx: int in range(detail + 1):
			var angle_point: float = start + float(detail_idx) * end
			var point: Vector2 = center + Vector2(cos(angle_point), sin(angle_point)) * radius
			
			if point.distance_to(center) > ShaperTech.MIN_DISTANCE_LENGTH:
				points.push_back(point)
		
		return points


static func get_rectangle_points(
	center: Vector2,
	size: Vector2,
	corner_radius: float,
	corner_segments: int,
	) -> PackedVector2Array:
		var points: PackedVector2Array
		
		if size.x <= 0.0 or size.y <= 0.0:
			return points
		
		var half_size: Vector2 = size / 2.0
		
		if corner_radius > 0.0:
			corner_segments = maxi(1, corner_segments)
			
			var corner_limit: float = clampf(corner_radius, 0.0, minf(half_size.x, half_size.y))
			var corner_centers: PackedVector2Array = PackedVector2Array([
				Vector2(-half_size.x + corner_limit, -half_size.y + corner_limit),
				Vector2(half_size.x - corner_limit, -half_size.y + corner_limit),
				Vector2(half_size.x - corner_limit, half_size.y - corner_limit),
				Vector2(-half_size.x + corner_limit, half_size.y - corner_limit),
				])
			var corner_ranges_start: PackedFloat32Array = PackedFloat32Array([
				PI, PI * 1.5, 0.0, PI / 2.0,
				])
			var corner_ranges_end: PackedFloat32Array = PackedFloat32Array([
				PI * 1.5, PI * 2.0, PI / 2.0, PI,
				])
			
			for corner_idx: int in 4:
				var corner_range: Vector2 = Vector2(
					corner_ranges_start[corner_idx],
					corner_ranges_end[corner_idx]
					)
				var corner_center: Vector2 = corner_centers[corner_idx]
				
				for segment_idx: int in range(corner_segments + 1):
					var x: float = float(segment_idx) / float(corner_segments)
					var y: float = lerpf(corner_range.x, corner_range.y, x)
					var z: Vector2 = corner_center + Vector2(cos(y), sin(y)) * corner_limit
					
					points.append(center + z)
		
		else:
			points.append_array([
				center + Vector2(-half_size.x, -half_size.y),
				center + Vector2(half_size.x, -half_size.y),
				center + Vector2(half_size.x, half_size.y),
				center + Vector2(-half_size.x, half_size.y),
				])
		
		return points


static func get_torus_points(
	center: Vector2,
	radius: float,
	thickness: float,
	detail: int,
	) -> PackedVector2Array:
		var points: PackedVector2Array
		
		if radius <= 0.0 or thickness <= 0.0 or detail < 3:
			return points
		
		var outer_radius: float = radius + thickness
		var inner_radius: float = radius - thickness
		
		if inner_radius <= 0.0:
			return points
		
		for detail_idx: int in range(detail + 1):
			var x: float = float(detail_idx) / float(detail)
			var angle: float = x * TAU - (PI / 2.0)
			
			points.append(center + Vector2(cos(angle), sin(angle)) * outer_radius)
		
		for detail_idx: int in range(detail, -1, -1):
			var x: float = float(detail_idx) / float(detail)
			var angle: float = x * TAU - (PI / 2.0)
			
			points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)
		
		return points
#endregion
