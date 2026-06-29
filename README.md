# Claude Code on Nix

Pins the native Claude Code binary to an exact version and wraps it with
`DISABLE_AUTOUPDATER=1`. The Nix store is read-only, so updates go through git.

## Outputs

| Output | Description |
| --- | --- |
| `packages.<system>.claude-code` | Native `claude` binary, autoupdater off |
| `packages.<system>.default` | Alias for `claude-code` |
| `overlays.default` | Adds `claude-code` to nixpkgs |
| `apps.update` | Rewrites the pin in `package.nix` |

Systems: `aarch64-darwin`, `x86_64-darwin`. Unfree, so requires `allowUnfree`.

## Run

```sh
nix run .#claude-code -- --version
nix build .#claude-code            # binary at ./result/bin/claude
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
