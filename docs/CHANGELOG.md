# Changelog

[Documentation home](../README.md)

## [Unreleased]

- Fixed generated collision nodes (`StaticBody3D`/`CollisionShape3D`) not
  appearing or persisting in the editor: they now receive scene ownership
  under the same condition as the generated mesh/timer nodes
  (`build_nodes_in_editor` enabled), instead of always staying unowned.
