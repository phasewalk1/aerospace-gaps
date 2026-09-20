# aerospace-gaps

One command to fix your [AeroSpace](https://github.com/nikitabobko/AeroSpace) top gap when you dock or undock your laptop.

If you run a menu bar overlay like [SketchyBar](https://github.com/FelixKratz/SketchyBar), the `outer.top` gap that looks right on an external display is too large on the built-in one — and AeroSpace has no per-monitor gap syntax for it. The usual fix is to open `aerospace.toml`, change a number, and run `aerospace reload-config`, every single time.

```console
$ aerospace-gaps
detected: docked
outer.top 10 -> 40 (config reloaded)
```

## Install

```sh
git clone https://github.com/phasewalk1/aerospace-gaps
cd aerospace-gaps
make install          # -> ~/.local/bin/aerospace-gaps
```

`make install PREFIX=/usr/local` installs system-wide instead. Or just drop `bin/aerospace-gaps` anywhere on your `PATH` — it is a single dependency-free bash script.

## Usage

| Command | What it does |
| --- | --- |
| `aerospace-gaps` | Detect the current setup and apply the matching gap |
| `aerospace-gaps docked` | Force the external-display value |
| `aerospace-gaps native` | Force the built-in-display value |
| `aerospace-gaps toggle` | Flip to the other value, no detection |
| `aerospace-gaps status` | Print what it sees and would do, change nothing |

Applying a value that is already set is a no-op — it will not touch the file or reload AeroSpace.

```console
$ aerospace-gaps status
config:    /Users/you/.config/aerospace/aerospace.toml
outer.top: 40 (docked=40 native=10)
monitors:  LG ULTRAGEAR
detected:  docked
```

## Configuration

Defaults live in `~/.config/aerospace-gaps/config`, which is sourced as shell. Every value can also be overridden per-invocation as an environment variable.

```sh
AEROSPACE_GAP_DOCKED=40          # outer.top with an external display attached
AEROSPACE_GAP_NATIVE=10          # outer.top without one
AEROSPACE_GAP_KEY=outer.top      # the gap key to rewrite
AEROSPACE_CONFIG=~/.config/aerospace/aerospace.toml
AEROSPACE_DOCKED_MONITOR=        # optional regex, see below
```

See [`config.example`](config.example).

## How docked is detected

AeroSpace 0.20 exposes no monitor geometry — `list-monitors` can print a name but not a width — so detection is by **name**. Any monitor whose name does not look like an Apple panel (`Built-in`, `Color LCD`, `Liquid Retina`, `Sidecar`) counts as external, and one external display is enough to be docked.

If that heuristic guesses wrong for your setup, name your display explicitly with a case-insensitive regex:

```sh
AEROSPACE_DOCKED_MONITOR='ultragear|u2720q'
```

`aerospace-gaps status` prints the names AeroSpace reports, which is what you want to match against. And `toggle` never detects anything, so it works regardless.

## Safety

The rewrite only ever touches a line matching `^\s*<key> = <number>`, so commented-out variants are left alone. It writes to a temp file, verifies the new value landed, and only then copies the contents back over the original — preserving the file's inode and permissions, so editors and symlinked dotfiles don't notice.

## Tests

```sh
make test     # 14 checks against a stubbed CLI and a throwaway config
make lint     # shellcheck, if installed
```

The suite never touches your real config or a running AeroSpace.

## License

MIT
