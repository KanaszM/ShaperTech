# Getting started

[Documentation home](../README.md)

## Install

Use Godot 4.7.1. Copy the complete ShaperTech folder into your project's root so
the library is located at `res://ShaperTech`.

Preserve the `.gd.uid` files and bundled resources. The global defaults use UID
preloads, and the solid material references a texture at
`res://ShaperTech/resources/st_default_texture.png`. Renaming or moving the folder
requires updating those references; this is not a path-independent addon.

Open the project in Godot and allow the import and script scan to finish. The
`class_name` scripts register the custom types and their SVG icons. There is no
plugin to enable and no autoload to configure. The folder itself is a library,
not a standalone runnable Godot project.

## Suggested first scene

Create this scene using identity transforms initially:

```text
World (Node3D)
|-- Camera3D
|-- DirectionalLight3D
|-- Geometry (Node3D)
`-- Shapers (STContainer)
    `-- Platform (STPolygon / Polygon2D)
```

`Geometry` is an optional destination for generated meshes. Assign it to
`Platform.parent_custom_node` if you want to keep generated 3D nodes separate
from the 2D authoring nodes. Otherwise output is parented to the shaper itself.

Create `Platform` from the custom type, or attach
`res://ShaperTech/polygon/st_polygon.gd` to a `Polygon2D`.
The original Godot polygon-editing tools remain the way to edit its outline.

## Build a platform

1. Select the platform in the 2D workspace. Draw a simple rectangle with corners
   `(0, 0)`, `(128, 0)`, `(128, 64)`, and `(0, 64)`.
2. Assign a new `STPolygonData` to **Data**. Set **Geometry > Height** to `2.0`
   and leave **Scale** at `32.0`. Assign a new `STPolygonMaterials` to
   **Materials**, or let the first build create the missing resources.
3. Keep the surface types at `SOLID`. For outlines whose winding you do not want
   to manage yourself, choose `AUTOMATIC` reverse-face mode for Top, Bottom,
   and Sides.
4. Press the platform's **Build** button, or press **Build** on `Shapers`.
   Inspect the result in the 3D workspace: it is 4 units long, 2 units deep,
   and 2 units tall before any scene-parent transforms.
5. Position the camera to look at the platform and configure lighting. Run the
   scene. The container's default `build_on_ready = true` rebuilds its descendants.

The same polygon would produce a flat 4-by-2 surface with `STFloor`.
For ramps, create `STSlope` on a `Line2D` with exactly two points. For walls,
use `STWall` on a `Line2D` with two or more points.

## Choose when to rebuild

Standalone shapers default to disabled startup building and manual rebuilds.
Pressing **Build** always runs a build regardless of those settings.

For editor iteration, choose an automatic build mode and perform one initial
build to create its timer. Changing geometry, data, or materials does not itself
call `build()`; rebuild manually or wait for an active timer.

For predictable runtime generation, either use an outer `STContainer` with
startup building enabled, or set a standalone shaper's `build_on_ready` to
`ALWAYS`. See [Coordinates and building](coordinates-and-building.md) for all modes.

## Save or regenerate output

`build_nodes_in_editor` determines whether generated mesh and timer nodes receive
scene ownership in the editor. It defaults to `false`: editor output should not
be assumed to be saved with the scene.

For a regenerate-on-start workflow, save the authoring nodes and resources and
enable runtime building. To retain generated mesh nodes in an edited scene, set
`build_nodes_in_editor = true`, build, allow deferred additions to complete, and
save. Collision children do not receive scene ownership from the current builder;
rebuild at runtime when you need generated collision.

## Next steps

Read [Coordinates and building](coordinates-and-building.md) before introducing
custom output parents or nonzero offsets. Use the individual
[polygon](polygon.md), [floor](floor.md), [slope](slope.md), and [wall](wall.md)
guides for shape-specific settings.
