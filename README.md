# file-actions.yazi

a [Yazi](https://github.com/sxyazi/yazi) plugin for file actions.

> [!NOTE]
> The latest main branch of Yazi is required at the moment.

## Installation
```sh
# Linux/macOS
git clone https://github.com/BBOOXX/file-actions.yazi.git ~/.config/yazi/plugins/file-actions.yazi
```

## Configuration
```toml
# keymap.toml
[manager]
keymap = [
# ...
	{ on = [ "f" ], exec = "plugin file-actions", desc= "Perform actions on selected files"},
# ...
]

```

Place the action script in the 'actions' directory, and the plugin will automatically invoke the 'init.lua' file.

```
~/.config/yazi/
├── init.lua
├── plugins/
│   └── file-actions.yazi/
│       ├── init.lua
│       └── actions/
│           ├── action1/
│           │   ├── init.lua
│           │   └── blabla.sh
│           └── action2/
│               ├── init.lua
│               └── blabla.sh
└── yazi.toml
```


https://github.com/BBOOXX/file-actions.yazi/assets/7044834/6c96c90c-1c1e-4a82-8057-f5bcba1ed984

