# foldtint

foldtint applies color to locked folders on the Desktop to differentiate them from unlocked ones on MacOS. Unlocked folders keep the default macOS folder color.

If daemon/watcher is on, the color changes happen automatically. Persists after shutdown/restart.

The tool watches `~/Desktop` only. The tool does not change nested folders. The tool does not change files, aliases, apps, or packages.

Default color: purple.

## Requirements

- macOS 14 or later
- Node.js 18 or later
- npm

The install procedure puts a native binary on the computer. The tool does not need network access after install. The tool does not need root access.

## Install

1. Open a terminal.
2. Run this command:

```
npm install -g foldtint
```

3. Start the watcher:

```
foldtint on
```

The `on` command installs a LaunchAgent. The LaunchAgent uses the installed `foldtint` binary. Keep the npm global install in place while the watcher runs.

Show help:

```
foldtint --help
```

## Commands

### color

Show the current color:

```
foldtint color
```

Set the color for all locked Desktop folders:

```
foldtint color purple
```

Valid color names:

- gray
- green
- purple
- blue
- yellow
- red
- orange

These names are Finder tag colors. Hex values are not valid.

The `color` command writes the configuration. Then the command scans the Desktop.

### scan

Apply or remove the `Locked` tag on top-level Desktop folders now:

```
foldtint scan
```

Use `scan` after a repair. You do not need `scan` when the watcher is on.

### on

Start the watcher:

```
foldtint on
```

Then a lock on a top-level Desktop folder applies the color. An unlock removes the color. You do not need `scan` for that change.

### off

Stop the watcher:

```
foldtint off
```

The command does not remove current tints. The command does not unlock folders.

### status

Show the color, the Desktop path, the watcher state, and the folder counts:

```
foldtint status
```

### daemon

Run the watcher in the current process:

```
foldtint daemon
```

The `on` command starts this process through LaunchAgent. Do not run `daemon` by hand unless you do a test.

### uninstall

Remove foldtint data, then remove the npm package.

1. Run this command:

```
foldtint uninstall
```

The command stops the watcher. The command removes the LaunchAgent. The command removes the `Locked` tag from top-level Desktop folders. The command deletes the configuration file. The command does not unlock folders.

2. Run this command:

```
npm uninstall -g foldtint
```

## Operation

A locked folder is a folder with the Finder Locked checkbox. That flag is the user immutable flag.

When a folder is locked, foldtint adds the Finder tag `Locked` with the configured color. Other tags stay.

When a folder is unlocked, foldtint removes only the `Locked` tag. Other tags stay.

The watcher uses directory events on the Desktop. The watcher does not use per-file events. Memory use stays low.

## Limits

- The tool works on macOS only.
- The tool works on top-level Desktop folders only.
- The tool does not follow symbolic links.
- The tool does not use `/`, `/System`, or `/Applications`.
- The tool does not set custom icons.
- The tool does not use hex colors.

## Build from source

Use this procedure only when you change the code.

1. Install Xcode Command Line Tools.
2. Go to the project folder.
3. Run this command:

```
npm run build
```

The command writes a native binary for this computer.

## License

MIT. See `LICENSE`.
