# foldtint

foldtint applies color to locked folders on the Desktop to differentiate them from unlocked ones on MacOS. Unlocked folders keep the default macOS folder color.

If daemon/watcher is on, the color changes happen automatically. Persists after shutdown/restart.

The tool watches `~/Desktop` only. The tool does not change nested folders. The tool does not change files, aliases, apps, or packages.

Default color: purple.

## Requirements

- macOS 14 or later
- Swift 6
- Xcode Command Line Tools

The tool does not need network access. The tool does not need root access.

## Build

1. Open a terminal.
2. Go to the project folder.
3. Run this command:

```
swift build -c release
```

The binary is `.build/release/foldtint`.

Alternative command:

```
make release
```

## Install the watcher

The watcher must run as a LaunchAgent. Use the release binary for this procedure.

1. Build the release binary.
2. Run this command:

```
.build/release/foldtint on
```

The LaunchAgent uses the path of that binary. Keep the binary at that path.

## Commands

Show this help:

```
foldtint --help
```

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

Use `scan` after a build or after a repair. You do not need `scan` when the watcher is on.

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

Do this procedure to remove foldtint data:

```
foldtint uninstall
```

The command does this work:

1. Stop the watcher.
2. Remove the LaunchAgent.
3. Remove the `Locked` tag from top-level Desktop folders.
4. Delete the configuration file.

The command does not unlock folders. The command does not delete the binary.

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

## License

MIT. See `LICENSE`.
