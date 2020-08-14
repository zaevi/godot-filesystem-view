# FileSystemView

![icon](images/icon.png)

A Godot tool similar to FileSystem dock, allows you to customize filters(views) to work with project resources.

![demo1](https://user-images.githubusercontent.com/12966814/90251893-1f898b80-de71-11ea-9a03-49f3c1dce84f.gif)

## Install

1. Install via AssetLib. Or download this repo and put `FileSystemView` folder into `YOUR_PROJECT/addons/`.
2. Activate it at `Project -> Project Settings -> Plugins`. Now you can see a `View` dock on the left-bottom side.

## Usage

1. In the option button above you can switch views. There are some preset views. Click the button on the right to configure views.

2. File Tree usage is similar to FileSystem dock (double-click to open, right-click to popup menu, drag file to scene).

Note:

- Some features are implemented by hooking FileSystemDock control, so FileSystemDock would be influenced (like file selection).

- Favorites folder won't shown in this plugin.

- Multi-file selection, searching and drag-to-move-files are not yet supported.

### Configure Views

View configs are saved in `views.cfg`. If it doesn't exists, the plugin will load configs from `default_views.cfg`.

![demo3](https://user-images.githubusercontent.com/12966814/86586164-0f50d780-bfba-11ea-8deb-a3ece305281b.png)

- `Icon` comes from `EditorIcons` of editor theme. You can preview icons by plugins such as [Editor Theme Explorer](https://godotengine.org/asset-library/asset/557) and [Editor Icons Previewer](https://godotengine.org/asset-library/asset/374)

- The filter does expression match by `*` and `?` (same as `String.matchn` method), and expressions are separated by `;` .

- `Exclude` can exclude some results. You may want to exclude some specific folders here.

- Folders with no available files in current view can be hidden.

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
