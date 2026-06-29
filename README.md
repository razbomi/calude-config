# Claude Code on Nix

Claude Code's native binary, packaged as a Nix flake for macOS. The version is
pinned, so installs are reproducible and every update is a git commit you can
review and roll back. It does this by fixing the version and checksums in
`package.nix` and disabling the bundled autoupdater (`DISABLE_AUTOUPDATER=1`); the
Nix store is read-only, so the binary can't update itself in place.

## Run

```sh
nix run .#claude-code -- --version
nix build .#claude-code
```

## Install (nix-darwin)

```nix
inputs.claude-config.url = "github:razbomi/claude-config";

nixpkgs.overlays = [ inputs.claude-config.overlays.default ];
environment.systemPackages = [ pkgs.claude-code ];
```

If Homebrew's `claude-code` cask is installed, remove it; `/opt/homebrew/bin`
otherwise shadows the Nix binary:

```sh
brew uninstall --cask claude-code
```

The Claude binary is unfree. Allow it broadly, or scope it to just this package.
Pick one:

```nix
# either allow all unfree:
nixpkgs.config.allowUnfree = true;

# or scope to just this package:
nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "claude-code";
```

## Outputs

| Output | Description |
| --- | --- |
| `packages.<system>.claude-code` | Native `claude` binary, autoupdater off |
| `packages.<system>.default` | Alias for `claude-code` |
| `overlays.default` | Adds `claude-code` to nixpkgs |
| `apps.update` | Rewrites the pin in `package.nix` |

Systems: `aarch64-darwin`, `x86_64-darwin`.

## Develop

Build from a working copy instead of the pinned input:

```sh
darwin-rebuild switch --flake . --override-input claude-config path:/path/to/repo
```

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
