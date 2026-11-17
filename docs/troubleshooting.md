# Troubleshooting

[Documentation home](../README.md)

## Nothing appears in 3D

Check the input and trigger before changing materials:

| Check | Expected |
| --- | --- |
| Polygon/Floor points | At least three valid, nondegenerate outline points |
| Slope points | Exactly two distinct points |
| Wall points | Two or more, without unintended zero-length segments |
| Geometry scale | Greater than zero |
| Polygon height | Positive if you expect a block; default is zero |
| Material types | At least one relevant group is not DISABLED |
| Slope flags | Exterior or inward-face flags enabled for the desired group |
| Build trigger | Press Build, enable an appropriate startup policy, or start a timer with an initial build |
| Runtime view | A camera that sees the generated location and suitable lighting |

An invalid build resets cached geometry and can clear previous visible output;
it does not preserve the previous successful shape as a fallback.

## Visible in the editor, missing when running

Editor-generated mesh nodes are not owned/saved by default.
Enable runtime building through an outer container, or through `ALWAYS` on a
standalone shaper. `EDITOR_ONLY` does not build at runtime.

If a container exists above a shaper, that shaper's startup setting is ignored.
Check the **outermost** container's `build_on_ready`. If it is false, no
descendant startup builds are requested by these classes.

## Automatic rebuilding never starts

Selecting a build mode does not create its timer immediately. Perform an initial
build. Automatic editor-only mode is inactive in a running game. To stop or
change a timer, change its settings and build again.

Container `build_on_ready` is not a pause switch for existing timers.

## A surface vanishes from one side

Check culling and triangle winding. Polygon/Floor groups support automatic
winding handling. Reverse the appropriate group if needed. Slope inward-face
flags explicitly emit reversed triangles. Wall Front and Back are separate
surface groups, and a floor's top and bottom have opposite winding.

Changing UV rotation will not fix face culling.

## The shape is offset, too small, or rotated unexpectedly

At scale `32`, drawing-space offsets of `32` move horizontally by one unit, while
height values are already in 3D units. Verify that geometry offset X/Z and Y have
not been treated as identical units.

Check `parent_custom_node`, `parent_sync_position`, ancestor container offsets,
and inherited output-parent transforms. Start with identity transforms. Do not
assume Node2D rotation/scale are converted as a complete transform.

The [coordinate guide](coordinates-and-building.md) documents the exact origin
branches, including the Node3D-parent scale behavior.

## Textures stretch, restart, or do not repeat

Use `*_tile_horizontal` and `*_tile_vertical` on the correct material group, then
rebuild. Overrides can replace those group values. Direction is normalized; it
does not control density. Rotation occurs after projection.

The wall restarts its UV origin per segment. Polygon sides normalize against the
whole perimeter. A slope uses separate left/right arc lengths. These mappings
are intentionally not one universal unwrap. Ensure your material/shader sampler
supports repeating UVs when tiling.

## A transparent material looks completely invisible

The `TRANSPARENT` enum selects the bundled zero-alpha material. For visible
translucency, use `SOLID` with your own transparent Godot material.
Use `DISABLED` to remove triangles entirely, including their contribution to
generated collision.

## A corner ramp has an open end

The normal-mode front closure uses Sides settings. The far end uses Back, which
defaults to disabled. The flat face uses Bottom, also disabled by default.
Enable the required groups; an override does not replace these enable flags.

For flipped ramps, the flat face is at the high level. This is not the same
volume as a normal ramp with its points reversed. Negative curve values can also
overshoot nominal height. Review the [slope guide](slope.md).

## Flickering or seams

Avoid overlapping flat floors and duplicate geometry at the same elevation.
A flipped slope with both corner factors `1` collapses its volume; slope and
flat faces can coincide. A zero-height polygon likewise has coincident caps.

Nonzero wall Y skew applies per segment and can create different heights where
segments meet. Slope corners can create twisted quads, whose triangulation
diagonal is visible under some lighting. These are geometry properties, not
texture-filtering problems.

## Collision is absent or persists

Enable `collision_enabled`, and enable `collision_enabled_in_editor` when checking
inside the editor. Rebuild after changing either setting.
Generated collision uses the emitted surfaces and a static concave mesh; it is
not a dynamic/convex solid.

Generated `StaticBody3D`/`CollisionShape3D` nodes now follow the same ownership
rule as the generated mesh/timer nodes: they are only given scene ownership
(so they show up and survive a scene save/reload) when `build_nodes_in_editor`
is also enabled on the shaper, same as the mesh node. With both
`collision_enabled_in_editor` and `build_nodes_in_editor` on, rebuild once and
the collision nodes should appear in the Scene tree and persist across reloads.
With `build_nodes_in_editor` off, collision (like the mesh/timer nodes) is
still generated and works in the running editor/game, but is not saved.
Rebuilding with collision disabled removes generated direct static bodies.
Hiding a mesh does not disable physics.

### The editor freezes while saving a scene with editor collision

If the editor becomes unresponsive while saving a scene that has many shapers
with `collision_enabled_in_editor` and `build_nodes_in_editor` on, it is likely
because each enabled shaper now owns its own concave trimesh collision shape,
and saving must serialize/process all of that geometry at once. Before saving:

- Stop any `AUTOMATIC_EDITOR_ONLY`/`AUTOMATIC_ALWAYS` rebuild timers (switch to
  `MANUAL`) so collision is not being rebuilt while the save is in progress.
- Turn off `collision_enabled_in_editor` on shapers where editor-time collision
  isn't actually needed, keeping it enabled only where you are actively testing
  physics in the editor.
- Reduce curve/preset detail or shape count while iterating, and only enable
  broad editor collision right before you need it.

This is a known cost of owned, saved editor collision, not a sign of corrupted
data; reducing the amount of simultaneously-owned collision geometry avoids it.

## One edit changes several shapes

Check whether nodes share the same Data or Materials resource. Make it unique
or duplicate it before modifying values that should vary independently.
Containers add offsets without modifying those resources.

## Generated nodes appear late, accumulate, or stay in an old branch

Deferred output-node addition is enabled by default. Allow deferred work to
finish before inspecting children. Match nodes by `STMesh.shaper` rather than
assuming the first child mesh belongs to a particular shaper.

Changing the custom parent is not an automatic move/cleanup operation. Generated
nodes are cached and reused; recreate/clean up the affected generated nodes
deliberately if changing destinations. Nodes placed under a separate custom
parent are not children of the authoring shaper and do not automatically share
its lifetime. When deleting such a shaper, clean up its external generated mesh
and timer too.

## Large scenes rebuild slowly

Use `MANUAL` during batch editing, then build the container once. Avoid very
short automatic intervals on many shapers. Reduce curve segments/preset detail
when the added geometry is not needed. Disable unused surface groups and inward
faces, and avoid generating editor collision unless useful.

Every build regenerates surfaces and replaces collision; it is not an
incremental vertex update or a background geometry job. Owned editor collision
(`build_nodes_in_editor` + `collision_enabled_in_editor` both on) adds scene
save/serialization cost on top of the rebuild cost, scaling with how many
shapers have it enabled at once; see "The editor freezes while saving a scene
with editor collision" above.

## Imports, UIDs, or custom icons are missing

Keep the resource folder and `.uid` sidecars when copying the library. Let Godot
complete its filesystem scan and imports. If the folder was relocated, check
explicit resource paths as well as UID resolution. Do not copy only the scripts
and expect their preloaded default resources to exist.
