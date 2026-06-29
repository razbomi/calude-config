# claude-config

A personal Nix flake that packages the **native Claude Code binary** and pins it
to an exact version. The Nix store is read-only, so the package disables Claude
Code's built-in autoupdater — version bumps go through this repo instead.

> Managing the `~/.claude` config (settings, `CLAUDE.md`, skills) from this repo
> is planned but not done yet. Today it's the binary only.

## What it provides

| Output | Description |
| --- | --- |
| `packages.<system>.claude-code` | The native `claude` binary, wrapped with `DISABLE_AUTOUPDATER=1`. |
| `packages.<system>.default` | Alias for `claude-code`. |
| `overlays.default` | Adds `claude-code` to a nixpkgs instance. |
| `apps.update` | Rewrites the pinned version + checksums in `package.nix`. |

Supported systems: `aarch64-darwin`, `x86_64-darwin`.

Claude Code is proprietary, so the package is marked unfree — you need
`allowUnfree` (or an `allowUnfreePredicate` for `claude-code`) to build it.

## Try it

```sh
nix run .#claude-code -- --version      # run without installing
nix build .#claude-code                 # build; result/bin/claude is the binary
```

## Install into nix-darwin

Add this repo as an input and pull the package in. Point the input at GitHub for
reproducibility; override to a local checkout while iterating.

```nix
# flake.nix (your nix-darwin config)
inputs.claude-config.url = "github:<owner>/claude-config";

# in your darwin configuration
nixpkgs.config.allowUnfree = true;                      # or a predicate for claude-code
nixpkgs.overlays = [ inputs.claude-config.overlays.default ];
environment.systemPackages = [ pkgs.claude-code ];      # or home.packages
```

```sh
# fast local loop without committing/pushing:
darwin-rebuild switch --flake . \
  --override-input claude-config path:/path/to/claude-config
```

If Claude Code is also installed via Homebrew, remove it so there's one `claude`
on `PATH` (`/opt/homebrew/bin` is ahead of the Nix profile dirs by default):

```sh
brew uninstall --cask claude-code
```

## Updating the pinned version

The pin lives in `package.nix`: a `version` plus a SHA256 per darwin arch,
copied from the upstream release manifest at `downloads.claude.ai`. The update
app rewrites all three — no binary download, since the manifest carries the
checksums.

```sh
nix run .#update              # bump to latest (default)
nix run .#update -- stable    # track the stable channel
nix run .#update -- 2.1.195   # pin an exact version
git diff package.nix          # review, then commit
```

The update app defaults to `latest`; pass `stable` for Anthropic's conservative
channel. `stable` can trail `latest` by several releases, which is why `latest`
is the default here.

### Automated updates

`.github/workflows/update-claude.yml` runs daily (and on demand via **Run
workflow**). It bumps the pin to `latest`, verifies it with `nix build`, and
**only then** opens and merges a PR — a broken or mismatched build fails the job
instead of merging. It runs on a macOS runner because the package is
darwin-only. Merging only updates this repo's `main`; your machine changes when
you re-lock the input and rebuild.

## Switching or rolling back versions

The pin is just a value in `package.nix` under version control, so moving
between versions is a commit (or a generation rollback).

**Flip to stable, or pin any exact version** — permanent, changes what your
system runs:

```sh
nix run .#update -- stable        # or e.g. 2.1.190
git commit -am "claude: track stable"
nix flake update claude-config && darwin-rebuild switch   # in your nix-darwin repo
```

**Try a version once, then discard it** — no commit:

```sh
nix run .#update -- 2.1.181
nix build .#claude-code && ./result/bin/claude --version
git checkout package.nix          # back to the committed pin
```

**Roll back a bad bump that's already live:**

- In this repo: `git revert <bump-commit>`, then re-lock + rebuild in nix-darwin.
- Or without editing anything: `darwin-rebuild --rollback` reverts the whole
  generation (Claude included), instantly.

Upstream keeps old releases, so any past version is re-fetchable — its hash is in
your git history. After `nix-collect-garbage -d`, an instant rollback instead
re-downloads the ~215 MB binary (still pinned, just no longer cached).

## How the pin works

A Nix fixed-output derivation must know a download's hash up front. `package.nix`
holds that hash (per platform) and the version; `fetchurl` pulls
`downloads.claude.ai/claude-code-releases/<version>/<platform>/claude` and Nix
refuses any download that doesn't match. That's what makes the build
reproducible — and why bumping the version means updating the checksums too.
