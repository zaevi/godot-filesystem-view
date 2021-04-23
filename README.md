# FileSystemView

![icon](images/icon.png)

A Godot tool similar to FileSystem dock, allows you to customize filters(views) to work with project resources.

![demo1](https://user-images.githubusercontent.com/12966814/90251893-1f898b80-de71-11ea-9a03-49f3c1dce84f.gif)

## Changes in 1.5

1. (Important) Since 1.5, this plugin saves settings with json format, and you may need to update your settings manually.

2. Multi-select and dragging are fully supported. You can now drag files freely.

    Bugs related to `ImportDock` are also fixed.

3. Remade context menu provides useful functions (more in future):

    - Play selected scene

    - Copy paths for multiple files

4. Support for resource thumbnails.

## Install

1. Install via AssetLib, or download this repo and put `FileSystemView` folder into `YOUR_PROJECT/addons/`.

2. Activate it at `Project > Project Settings > Plugins`. A dock named `View` will appear on the left-bottom side.

## Usage

The usage is basically similar to FileSystem dock.

- FileSystem dock would be influenced when using this plugin.

- `Favorites` is not supported.

### Configure Views

View settings are saved in `config.json`. If it doesn't exists, the plugin will load from `defaultConfig.json`.

![demo3](https://user-images.githubusercontent.com/12966814/86586164-0f50d780-bfba-11ea-8deb-a3ece305281b.png)

- `Icon` comes from `EditorIcons` of editor theme. You can preview icons by plugins such as [Editor Theme Explorer](https://godotengine.org/asset-library/asset/557) and [Editor Icons Previewer](https://godotengine.org/asset-library/asset/374)

- Filters are separated by `;`, e.g: `*.gd;*.cs;*.vs;*.gdns`

- Folders with no available files can be hidden.

> These options can be temporary toggled when in use.

## ChangeLog

### 1.1

- Now folder state can keep when switching views.

- Update `folder_empty` icon.

- Fix bugs and typo.

### 1.0

- First release.

## Licence

[MIT](LICENSE)
