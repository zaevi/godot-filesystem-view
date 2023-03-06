# FileSystemView

![](https://img.shields.io/badge/version-2.0-blue?style=flat-square)
[![](https://img.shields.io/github/license/zaevi/godot-filesystem-view?style=flat-square)](LICENSE)
![](https://img.shields.io/badge/godot-4.0-blue?style=flat-square)


![icon](images/icon.svg)

FileSystemView is a Godot plugin that uses custom filters to handle your resources.

**Note**: This branch works for Godot 4.x, for 3.x please use [this branch](https://github.com/zaevi/godot-filesystem-view/tree/3.x)

![demo_230306_1524](https://user-images.githubusercontent.com/12966814/223044825-8fe23344-fd55-4342-8481-e9bab2901dfe.gif)

## Installation

1. Install via AssetLib, or download this repo and put the `FileSystemView` folder in `YOUR_PROJECT/addons/`.

2. Activate it in `Project > Project Settings > Plugins`.

## Usage

It's similar to the original FileSystem dock.

> For some "hooking" reason, the original FileSystem dock would be affected when using this plugin.

### Configuring views

View settings are stored in `config.json`. If it doesn't exist, the plugin will load default settings from `defaultConfig.json`.

![fsv_config](https://user-images.githubusercontent.com/12966814/223150168-190e4025-20d3-4ca0-a342-e8fd9ce0c878.png)

- `Icon` is taken from `EditorIcons` of the editor theme. You can preview icons using plugins like [Editor Icons Previewer](https://godotengine.org/asset-library/asset/1664).

- Filters are separated by `;` or `,`, for example: `*.gd, *.cs, *.vs, *.gdns`.

- Folders with no available files can be hidden in the result.

### Additional features

There are functional tweaks to the context menu:

- `Play Scene` to play the selected scene.

- `Copy Paths` of selected files.

## Licence

[MIT](LICENSE)
