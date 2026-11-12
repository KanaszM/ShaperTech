# STContainer

[Documentation home](../README.md)

`STContainer` extends `Node`. It organizes shapers into a recursively built
subtree and adds vertical offsets without modifying their data resources.
It does not generate a mesh of its own.

## Properties and commands

| Member | Default | Purpose |
| --- | --- | --- |
| `height_offset: float` | `0.0` | Adds a 3D-unit vertical offset to all descendant shapers |
| `build_on_ready: bool` | `true` | Whether the outermost container builds its subtree on startup |
| `build() -> void` / Build button | N/A | Immediately requests builds throughout the subtree |

Unlike shaper startup settings, the container's `build_on_ready` is a Boolean.
It does not have separate editor-only/runtime modes.

## Recursive traversal

```text
Level (STContainer, height_offset = 2)
|-- Floor (STFloor, distance = 0)                  -> mesh reference Y = 2
|-- Room (Node)
|   `-- Walls (STWall, distance = 0)               -> mesh reference Y = 2
`-- UpperSection (STContainer, height_offset = 3)
    |-- Landing (STPolygon, distance = 1)          -> mesh reference Y = 6
    `-- Ramp (STSlope, distance = 0)               -> mesh reference Y = 5
```

The traversal passes through ordinary nodes and recognizes Polygon, Floor,
Slope, and Wall shapers. A nested container handles its own descendants.
Shaper children are traversed too, so another shaper nested beneath a shaper is
not excluded.

This follows the actual scene-tree ancestry, not `parent_custom_node`. A shaper
can send its output to a different branch and still receive the offsets of the
containers that contain the authoring node.

## Height arithmetic

For each shaper:

```text
mesh reference Y =
    data.geometry_distance
    + data.geometry_position_offset.y
    + sum(height_offset of every ancestor STContainer)
```

Individual vertex heights are added to that reference. A normal ramp whose
reference Y is `5` and height is `2` has nominal endpoints at `5` and `7`.
Any transforms inherited by the output mesh apply afterward.

Offsets can be positive or negative. They are read from ancestors on **every**
build, including a shaper's own automatic rebuild. A nested container built on
its own still includes its outer containers' offsets. No adjusted height is
written into shared resources.

Editing `height_offset` does not itself trigger a build. Press Build on the
container to update the whole subtree, or allow existing shaper timers to update
their outputs individually.

## Startup precedence

Godot readies child nodes before parents. Every shaper checks for a container
ancestor and skips its own startup build when one exists. Nested containers also
skip their own `_ready()` build when another container is above them.

| Outermost container | Descendant startup settings | Startup outcome |
| --- | --- | --- |
| `build_on_ready = true` | Any | Builds the whole subtree, including nested containers whose flag is false |
| `build_on_ready = false` | Any | No descendant startup builds through these `_ready()` policies |

Calling `build()` manually always builds that subtree, independent of all
`build_on_ready` settings.

The override covers **startup only**. Child `build_mode` and
`build_automatic_interval` still govern their timers once they have been built.
An outer container set to false is not a master pause switch for timers already
running or saved with generated nodes.

## Recommended usage

Use one outer container to control level initialization. Use nested containers
for floors, platforms, or sections that need a common elevation. Keep generated
output under a stable destination rather than moving its authoring nodes or
changing output parents after generation.

Use manual builds while making a large batch of edits, then rebuild the
container once. If automatic editor rebuilding is useful, choose an interval
appropriate to the number and complexity of shapers.
