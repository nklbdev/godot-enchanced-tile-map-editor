# godot-enchanced-tile-map-editor

Hello everyone Godot users! I'm developing an alternative tile editor for the Godot engine v3.5+.

It is a very early alpha version. I will be glad to your wishes and suggestions for its improvement!

## Features:
- Rectangular selection, continuous selection, combination of selections.
- Integrated powerful tile palette
- Drawing with patterns
- Undo-Redo support
- Saving patterns to the bottom panel, tileset metadata (not yet), or copying to plain text
- Rotation and flipping patterns at all possible angles with tiles in their cells and without them (and powerful set of keyboard shortcuts for it)
- 3 auto-tilers: Classic, Improved and Terrain (their algorithms are implemented, but not integrated yet)

![image](https://user-images.githubusercontent.com/7024016/214442952-e9899aba-8ec7-47c7-b1bc-ef5e82edfd3b.png)

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/HuihzLfFYgU/0.jpg)](https://www.youtube.com/watch?v=HuihzLfFYgU)

when you select a `TileMap` instance in the scene tree, the bottom panel "Tile Map" appears, which contains tools and sub-palettes.

## Tools

### Selection

- __Rectangular Selection__ - everyone's favorite rectangular selection))
- __Continous Selection__ (Magic Wand) - so far not a very useful tool. But smart pattern selection will be added later

You can combine selections by `Shift` (union), `Ctrl+Shift` (intersection) and `Alt+Shift` (subtraction)

Also you can copy selection to clipboard as serialized pattern. In this case, the pattern will be immediately ready for drawing in all tools.

You can draw it on your `TileMap`, or paste it into "Patterns" subpalette or or in any other place as JSON text.

### Drawing

- __Pattern Brush__ - just a brush. But it switches to the Line when `Ctrl` is pressed and the Rectangle when `Ctrl+Shift` is pressed.
- __Pattern Line__ - draws line. Behaves differently for a single tile and a complex pattern on offsetted maps. A single tile forms a continuous line, as in Godot 4
- __Pattern Rectangle__ - well known rectangle)
- __Pattern bucket fill__ - allow continous filling and offset pattern origin by moving mouse with holding LMB
- __Tile Picker__ (not implemented yet)
- __Eraser__ - just an eraser
- __Random Tiles__ modifier with Scattering option (not implemented yet)
- __Rotate pattern__ menu - allows rotate pattern at all possible angles for current `cell_half_offset`
- __Flip pattern__ menu - same as "Rotate" but for pattern mirroring

[![image](https://user-images.githubusercontent.com/7024016/217090210-f9170f2e-1625-4e13-9b8f-bebbd558bbbd.png)](https://user-images.githubusercontent.com/7024016/217090041-5444e3dc-3f4c-4e2d-8a44-24cceaf9a180.png)

## "By Texture" tiles subpalette

Provides tiles layout on textures, how they are marked up in `TileSet`. Best choice to select patterns for rectangular maps.

[![image](https://user-images.githubusercontent.com/7024016/217073166-04fc2a0f-c896-442a-b447-3986f08d5f5d.png)](https://user-images.githubusercontent.com/7024016/217072418-1fdb6831-ec6c-46d0-9bde-0da393dd6bc3.png)

## "Individual" tiles subpalette

Provides tiles layout on `TileMap` which have similar `mode` or `custom_cell_transform` and `cell_half_offset` as in current `TileMap`. It is convenient to choose patterns for non-rectangular maps on it.

[![image](https://user-images.githubusercontent.com/7024016/217073330-8d163be1-1293-4eb6-ad51-cf7137e7aa9b.png)](https://user-images.githubusercontent.com/7024016/217072531-8d6554ff-9ed8-4c65-b1b8-c7bde9a86b30.png)

## "Patterns" subpalette

This palette is for saving patterns copied from the map. It is already working, but visually it is not yet ready. Patterns can be pasted here using `Ctrl+V` shortcut.
Patterns can be pasted not only here, but anywhere as a regular JSON-text. You can exchange them immediately through any messenger!

[![image](https://user-images.githubusercontent.com/7024016/217073422-4d66b631-4746-4b0d-9e53-764ce1f2a227.png)](https://user-images.githubusercontent.com/7024016/217072621-2d50adce-b4f2-400b-b3af-9386b7400637.png)

## Autotiles

(algorithms are implemented, but not integrated yet)

## Personalization

[![image](https://user-images.githubusercontent.com/7024016/217080889-944b65f5-33ac-4b5f-ad3f-56565712898b.png)](https://user-images.githubusercontent.com/7024016/217080797-db6bf9c0-51ea-4386-a181-0927f8a656fd.png)

You can choose drawing limits, grid and cells colors and grid fragments sizes.

## Installation

Simply download or clone this repository and copy the contents of the
`addons` folder to your own project's `addons` folder.

Then enable the plugin on the Project Settings.
