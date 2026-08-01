set unstable
set positional-arguments

# Run [script] recipes under bash; on Linux sh is dash, which lacks the
# [[ ]], <<<, and pipefail constructs those recipes use.

set script-interpreter := ['bash', '-eu']

# Locate a Docker-compatible container runtime. Probe PATH first, then
# well-known install locations so the recipe still works inside agentic
# harnesses or sandboxes that strip /usr/local/bin from PATH. Override by
# setting CONTAINER_RUNTIME in the environment.
#
# The continuation lines of the `for` list below hang under the first
# candidate path rather than on a two-space grid, which is what shell
# style calls for and what `lint-editorconfig` would otherwise reject
# under this file's indent_size = 2. Exempt just that span rather than
# re-indent a block the sibling repos carry verbatim.
# editorconfig-checker-disable
container_runtime := env("CONTAINER_RUNTIME", `bash -c '
    docker_path=$(command -v docker 2>/dev/null || true)
    podman_path=$(command -v podman 2>/dev/null || true)
    for p in "$docker_path" \
             /usr/local/bin/docker \
             /opt/homebrew/bin/docker \
             /Applications/Docker.app/Contents/Resources/bin/docker \
             "$HOME/.orbstack/bin/docker" \
             "$HOME/.rd/bin/docker" \
             "$podman_path" \
             /opt/podman/bin/podman; do
        if [ -n "$p" ] && [ -x "$p" ]; then echo "$p"; exit 0; fi
    done
    echo docker
'`)

# editorconfig-checker-enable

# Shared docker-run prefix. DOCKER_CONFIG points at a fresh empty dir so
# docker skips the osxkeychain helper; PATH prepends the runtime's dir
# for shells where docker isn't already on PATH.

docker_run := 'DOCKER_CONFIG="$(mktemp -d)" PATH="$(dirname ' + container_runtime + '):$PATH" ' + container_runtime + ' run --rm'

# shellcheck, actionlint, bats, and gitleaks run from digest-pinned Docker
# images, and Renovate tracks each version + digest pair via the markers
# below. Every other gate assumes its tool on PATH from the Brewfile:
# shfmt, vale, cspell, rumdl, biome, yamllint, tombi, and
# editorconfig-checker.
# The tombi release this repo's config and committed formatting are
# verified against. tombi is brew-installed, so `check-tombi-version`
# compares the local binary with it: a mismatch means local formatting
# may differ from what the gate expects.

# renovate: datasource=github-releases depName=tombi-toml/tombi

tombi_version := "1.2.5"

# renovate: datasource=docker depName=rhysd/actionlint

actionlint_version := "1.7.12"
actionlint_image := "docker.io/rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667"
actionlint := docker_run + ' -v "$(pwd):/repo:ro" -w /repo ' + actionlint_image

# renovate: datasource=docker depName=koalaman/shellcheck

shellcheck_version := "v0.11.0"
shellcheck_image := "docker.io/koalaman/shellcheck:v0.11.0@sha256:61862eba1fcf09a484ebcc6feea46f1782532571a34ed51fedf90dd25f925a8d"
shellcheck := docker_run + ' -v "$(pwd):/mnt:ro" -w /mnt ' + shellcheck_image

# renovate: datasource=docker depName=bats/bats

bats_version := "1.14.0"
bats_image := "docker.io/bats/bats:1.14.0@sha256:5322b877351fda0cc435de8c6116de7d0a2ec79d7c680132a0ef329a633bc66f"
bats := docker_run + ' -v "$(pwd):/code" -w /code ' + bats_image

# renovate: datasource=docker depName=ghcr.io/gitleaks/gitleaks

gitleaks_version := "v8.28.0"
gitleaks_image := "ghcr.io/gitleaks/gitleaks:v8.28.0@sha256:cdbb7c955abce02001a9f6c9f602fb195b7fadc1e812065883f695d1eeaba854"
gitleaks_scan := docker_run + ' -v "$(pwd):/repo" -w /repo ' + gitleaks_image

# version/commit/date describe the current checkout for `just version` and
# the release-notes recipes; the date is the committer date (UTC).

version := `git describe --tags --abbrev=7 2>/dev/null || git rev-parse --short=7 HEAD 2>/dev/null || echo "DEV"`
commit := `git rev-parse --short=7 HEAD 2>/dev/null || echo ""`
date := `TZ=UTC git log -1 --format=%cd --date=format-local:%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "unknown"`

# Default recipe: lint then test.
default: lint test

# Set up the dev environment (brew deps, Vale styles, git hooks). Idempotent.
setup: install-brew install-tools prek-install

# Install Homebrew dependencies from the Brewfile.
install-brew:
    brew bundle check || brew bundle install

# Refresh non-brew tooling — today, Vale's synced style packages.
install-tools:
    vale sync

# Format shell scripts in place via shfmt (reads .editorconfig).
[script]
format-shell:
    files=$(git ls-files '*.sh')
    if [ -n "$files" ]; then shfmt -w $files; fi

# Format Markdown whitespace, list markers, and code fences via rumdl.
format-markdown *args:
    rumdl fmt {{ if args == "" { "." } else { args } }}

# Format JSON / JS / TS in place via biome.
format-config *args:
    biome format --write {{ if args == "" { "." } else { args } }}

# Rewrites whitespace/style only; key and array order are preserved
# (schema-driven reordering is disabled in tombi.toml). Excludes and
# lockfile skips come from tombi.toml.

# Format TOML in place (tombi 1.2.0), pairing with `lint-toml`'s --check gate.
format-toml:
    tombi format

# `--fmt` is still gated behind --unstable; the `set unstable` at the top
# of this file already lifts that gate, but the flag is spelled out so the
# recipe does not depend on a setting a future edit could narrow.

# Reformat this Justfile in place via just's own formatter.
format-just:
    just --fmt --unstable

# Run every formatter over the tree.
format: format-shell format-markdown format-config format-toml format-just

# Apply rumdl's auto-fixable Markdown rules (complements format-markdown).
fix-markdown *args:
    rumdl check --fix {{ if args == "" { "." } else { args } }}

# Every gate below also runs in CI: this repo ships shell hooks and the
# docs around them, so the prose, spelling, Markdown, config, and YAML
# linters are code gates here rather than local-only conveniences as in
# the Go siblings.

# Run the full lint bar.
lint: lint-shell lint-shell-bats lint-shell-fmt lint-workflows lint-prose lint-spelling lint-markdown lint-config lint-yaml lint-toml lint-just lint-editorconfig

# Lint every tracked *.sh via the pinned shellcheck image (skips *.bats).
[script]
lint-shell:
    files=$(git ls-files '*.sh')
    if [ -n "$files" ]; then {{ shellcheck }} $files; fi

# The suites under test/ are bash, but their `#!/usr/bin/env bats` shebang
# names no dialect shellcheck knows, so they need an explicit --shell=bash
# — which is why they get their own recipe rather than joining the one
# above, where the flag would override the *.sh scripts' own shebangs.
# Nothing else: bats' `@test "name" { ... }` blocks parse as ordinary bash
# command groups, and `run`/`load` as ordinary commands, so the suites
# need no suppressions.

# Lint every tracked *.bats via the pinned shellcheck image.
[script]
lint-shell-bats:
    files=$(git ls-files '*.bats')
    if [ -n "$files" ]; then {{ shellcheck }} --shell=bash $files; fi

# Fail if shfmt would reformat any tracked *.sh (mirrors format-shell).
[script]
lint-shell-fmt:
    files=$(git ls-files '*.sh')
    if [ -n "$files" ]; then shfmt -d $files; fi

# Lint GitHub Actions workflows via the digest-pinned actionlint image.
lint-workflows:
    {{ actionlint }}

# Lint Markdown prose via vale.
lint-prose *args:
    vale --output=proofhouse-agent.tmpl --glob='!{LICENSE,CHANGELOG.md,.vale/*,tmp/*,.claude/worktrees/*,.claude/rules/*,.claude/skills/*,apm_modules/*,COMMIT_AGENTMSG}' {{ if args == "" { "." } else { args } }}

# Spell-check the tree via cspell.
lint-spelling *args:
    cspell --config .cspell.jsonc --no-summary --no-progress --no-must-find-files --exclude COMMIT_AGENTMSG {{ if args == "" { "." } else { args } }}

# Lint Markdown structure via rumdl.
lint-markdown *args:
    rumdl check {{ if args == "" { "." } else { args } }}

# Lint JSON / JS / TS via biome.
lint-config *args:
    biome check --files-ignore-unknown=true {{ if args == "" { "." } else { args } }}

# Lint YAML via yamllint --strict.
lint-yaml *args:
    yamllint --strict {{ if args == "" { "." } else { args } }}

# cog.toml and .rumdl.toml get syntax + style checks (validated offline against embedded
# SchemaStore schemas where one exists). We run the format gate in --check --diff mode
# here as well, so an unformatted TOML file fails the gate without being rewritten
# (`just format-toml` is the in-place fixer). --offline keeps the check hermetic against
# SchemaStore; --error-on-warnings promotes warnings to hard failures (matching the org
# -D-warnings / --max-warnings=0 posture). Scope (include/exclude, lockfile skips,
# schema.strict=false) lives in tombi.toml, so this recipe passes NO path args — tombi
# walks the tree per that config. This deliberately departs from the sibling
# *args-default-`.` idiom because tombi centralizes scoping in tombi.toml rather than on
# the CLI.

# Lint every tracked *.toml via tombi 1.2.0, the org TOML gate.
lint-toml:
    tombi format --check --diff
    tombi lint --offline --error-on-warnings

# Advisory rather than fatal: tombi comes from Homebrew and moves on its
# own schedule, and that is fine so long as it stays visible rather than
# silently reformatting a file the gate then rejects.

# Warn when the locally installed tombi differs from the verified release.
[script]
check-tombi-version:
    local=$(tombi --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ "${local}" != "{{ tombi_version }}" ]]; then
        echo "warning: local tombi ${local} != verified {{ tombi_version }}" >&2
        echo "         formatting may differ from what the gate expects" >&2
    else
        echo "tombi ${local} matches the verified release"
    fi

# Mirrors format-just. It prints a unified diff of what it would change.

# Fail if just's own formatter would rewrite this Justfile.
lint-just:
    just --fmt --check --unstable

# With no file arguments it walks git's index, so the gitignored Vale
# style packages never reach it; .editorconfig-checker.json mirrors the
# prek `exclude:` scope anyway. Indent size is checked tree-wide; the one
# span that cannot satisfy it, the container-runtime probe at the top of
# this file, carries inline disable markers rather than a global opt-out.

# Enforce .editorconfig across tracked files via editorconfig-checker.
lint-editorconfig:
    editorconfig-checker

# Preview the four commit-msg gates against the COMMIT_AGENTMSG draft.
lint-commit-msg:
    scripts/vale-commit-msg.sh COMMIT_AGENTMSG
    scripts/cspell-commit-msg.sh COMMIT_AGENTMSG
    scripts/commitlint.sh COMMIT_AGENTMSG
    scripts/commit-trailers.sh COMMIT_AGENTMSG

# Run the bats test suites under test/ via the pinned bats image.
test *args:
    {{ bats }} {{ if args == "" { "test" } else { args } }}

# Scan the working tree and full history for secrets via the pinned gitleaks image.
gitleaks:
    {{ gitleaks_scan }} git --verbose .

# Security sub-aggregator, so the security workflow invokes one recipe.
security: gitleaks

# Fast quality bar: lint then test.
check: lint test

# Comprehensive bar: check plus the full-history gitleaks scan.
check-all: check gitleaks

# Print version information.
version:
    @echo "Version: {{ version }}"
    @echo "Commit:  {{ commit }}"
    @echo "Date:    {{ date }}"

# Sync Vale styles and dictionaries (after cloning or a Packages change).
vale-sync:
    vale sync

# Run pre-commit hooks on changed files.
prek:
    prek

# Run pre-commit hooks on every file in the tree.
prek-all:
    prek run --all-files

# Install the git hooks for the commit-msg, pre-commit, and pre-push stages.
prek-install:
    prek install -t commit-msg -t pre-commit -t pre-push

# Lint the file in place so the CHANGELOG.md per-file-ignores in
# .rumdl.toml apply (rumdl matches those globs against on-disk paths, not
# stdin).

# Generate CHANGELOG.md from Conventional Commit history via cog.
generate-changelog:
    cog changelog | { echo "# Changelog"; cat; } > CHANGELOG.md
    rumdl check --fix CHANGELOG.md

# Preview the changelog entries since the last tagged release.
preview-changelog:
    cog changelog --at $(git describe --tags)..HEAD -t full_hash | rumdl check -d MD041 --fix --stdin

# MD041 is disabled for the heading-less fragment; without --isolated,
# MD013 stays off via .rumdl.toml so the full commit hashes are never
# wrapped.

# Generate release notes for a version (or HEAD); prints to stdout.
[script]
generate-release-notes version="":
    v=$([[ -n "{{ version }}" ]] && echo "v{{ version }}" || echo "..$(git rev-parse HEAD)")
    cog changelog --at $v -t full_hash | rumdl check -d MD041 --fix --stdin
