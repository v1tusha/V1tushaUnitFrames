# V1tushaUnitFrames

Custom oUF-based unit frames for World of Warcraft (Retail).

## Install

Download `V1tushaUnitFrames-<version>.zip` from the
[latest release](https://github.com/v1tusha/V1tushaUnitFrames/releases/latest)
and unpack it into:

```
World of Warcraft\_retail_\Interface\AddOns
```

That's it — the zip already contains a correctly named `V1tushaUnitFrames` folder,
so there is nothing to rename. Restart the game or type `/reload`.

Do **not** use the green "Code → Download ZIP" button. GitHub names that archive
`V1tushaUnitFrames-main`, and WoW ignores any addon whose folder name does not match
its `.toc` file.

Everything the addon needs, including oUF and Ace3, ships inside the zip.

## Usage

- `/vuf` — open the configuration window
- `/vuf unlock` — show movers and drag frames with the mouse (also a checkbox in every unit tab)
- `/vuf lock` — hide the movers again
- `/vuf reset` — reset all frame positions to defaults

## Build from source

```
git clone https://github.com/v1tusha/V1tushaUnitFrames.git
```

Cloning gives the folder the right name already, so the clone can live directly in
`Interface\AddOns`.
