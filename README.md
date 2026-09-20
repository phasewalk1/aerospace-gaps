# aerospace-gaps

One command to fix your [AeroSpace](https://github.com/nikitabobko/AeroSpace) top gap when you dock or undock your laptop.

If you run a menu bar overlay like [SketchyBar](https://github.com/FelixKratz/SketchyBar), the `outer.top` gap that looks right on an external display is too large on the built-in one — and AeroSpace has no per-monitor gap syntax for it. The usual fix is to open `aerospace.toml`, change a number, and run `aerospace reload-config`, every single time.

```console
$ aerospace-gaps
detected: docked
outer.top 10 -> 40 (config reloaded)
```

## Install

It's a single dependency-free bash script. Drop it anywhere on your `PATH`:

```sh
curl -o ~/.local/bin/aerospace-gaps \
  https://raw.githubusercontent.com/phasewalk1/aerospace-gaps/main/bin/aerospace-gaps
chmod +x ~/.local/bin/aerospace-gaps
```

## Usage

| Command | What it does |
| --- | --- |
| `aerospace-gaps` | Detect the current setup and apply the matching gap |
| `aerospace-gaps docked` | Force the external-display value |
| `aerospace-gaps native` | Force the built-in-display value |
| `aerospace-gaps toggle` | Flip to the other value, no detection |
| `aerospace-gaps status` | Print what it sees and would do, change nothing |

Applying a value that is already set is a no-op — it won't touch the file or reload AeroSpace.

## Configuration

Put your gap values in `aerospace.toml` itself, as comments. AeroSpace ignores them, `aerospace-gaps` reads them, and your settings travel with the dotfile they describe.

```toml
[gaps]
# aerospace-gaps: docked  = 40
# aerospace-gaps: native  = 10
outer.top    = 40
```

One directive per line, anywhere in the file. The value is the rest of the line, so regexes may contain spaces and pipes.

| Directive | Meaning | Default |
| --- | --- | --- |
| `docked` | Gap value when an external display is attached | `40` |
| `native` | Gap value when it is not | `10` |
| `key` | Which gap key to rewrite | `outer.top` |
| `monitor` | Case-insensitive regex naming your external display | *(see below)* |

Values are only ever compared and substituted, never evaluated as shell. `docked` and `native` must be whole numbers.

The same names work as environment variables for a one-off, and override the file:

```console
$ AEROSPACE_GAP_DOCKED=64 aerospace-gaps docked
outer.top 40 -> 64 (config reloaded)
```

A `~/.config/aerospace-gaps/config` file (shell syntax, see [`config.example`](config.example)) is also read, below directives in precedence. It's the only way to point at a non-standard `aerospace.toml`, since that path can't live inside the file it names.

## How docked is detected

AeroSpace 0.20 exposes no monitor geometry — `list-monitors` prints a name but not a width — so detection is by **name**. Any monitor that doesn't look like an Apple panel (`Built-in`, `Color LCD`, `Liquid Retina`, `Sidecar`) counts as external, and one external display is enough to be docked.

If that guesses wrong for your setup, name your display explicitly:

```toml
# aerospace-gaps: monitor = ultragear|dell u2720q
```

`aerospace-gaps status` prints the names AeroSpace reports, which is what you match against. And `toggle` never detects anything, so it works regardless.

## Safety

The rewrite only touches a line matching `^\s*<key> = <number>`, so commented-out variants are left alone. It writes to a temp file, verifies the new value landed, then copies the contents back over the original — preserving the file's inode and permissions, so editors and symlinked dotfiles don't notice.

## Tests

```sh
bash tests/run.sh
```

30 checks against a stubbed CLI and a throwaway config. Never touches your real config or a running AeroSpace.

## License

MIT
