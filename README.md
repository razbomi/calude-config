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
