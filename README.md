# Claude Code on Nix

Pins the native Claude Code binary to an exact, reproducible version and wraps it
with `DISABLE_AUTOUPDATER=1` — the autoupdater can't write to the read-only Nix
store. Updates land through git: versioned and roll-back-able, unlike the
self-updating brew/npm installs.

## Run

```sh
nix run .#claude-code -- --version
nix build .#claude-code
```

## Install (nix-darwin)

```nix
inputs.claude-config.url = "github:razbomi/calude-config";

nixpkgs.config.allowUnfree = true;
nixpkgs.overlays = [ inputs.claude-config.overlays.default ];
environment.systemPackages = [ pkgs.claude-code ];
```

```sh
brew uninstall --cask claude-code   # /opt/homebrew/bin otherwise shadows Nix
# local dev: build from a working copy instead of the pinned input
darwin-rebuild switch --flake . --override-input claude-config path:/path/to/repo
```

## Outputs

| Output | Description |
| --- | --- |
| `packages.<system>.claude-code` | Native `claude` binary, autoupdater off |
| `packages.<system>.default` | Alias for `claude-code` |
| `overlays.default` | Adds `claude-code` to nixpkgs |
| `apps.update` | Rewrites the pin in `package.nix` |

Systems: `aarch64-darwin`, `x86_64-darwin`. The binary is unfree; the overlay
install needs `allowUnfree` in your config (set in the snippet above). The flake
allows it for its own `packages` outputs, so `nix run`/`nix build` here need no
extra flags.

## Update

```sh
nix run .#update              # latest
nix run .#update -- stable
nix run .#update -- X.Y.Z
```

`.github/workflows/update-claude.yml` runs daily: bump → `nix build` gate → PR + auto-merge.

## Roll back

```sh
git revert <commit>           # then re-lock + rebuild in nix-darwin
darwin-rebuild --rollback     # or roll back the whole generation, no rebuild
```
