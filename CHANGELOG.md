# Changelog

## [v0.3.0](https://github.com/proofhouse/pre-commit-hooks/compare/v0.2.0..v0.3.0) - 2026-06-14

### Features

- cap commit body lines at 72 columns (#19) - ([e65425a](https://github.com/proofhouse/pre-commit-hooks/commit/e65425a898b1eed195fa60540283eb97725cafa9)) - [@tbhb](https://github.com/tbhb)
- require a Signed-off-by trailer in commit-trailers (#18) - ([2c613d1](https://github.com/proofhouse/pre-commit-hooks/commit/2c613d1712ac5afd510bf1558bfe932ccc8ced22)) - [@tbhb](https://github.com/tbhb)

#### Documentation

- fix the build metadata date comment (#21) - ([731900c](https://github.com/proofhouse/pre-commit-hooks/commit/731900cd706e695624c8ea9067abc2f9d28fc117)) - [@tbhb](https://github.com/tbhb)

#### Continuous Integration

- advance the github-actions pins to v0.2.1 (#20) - ([928d364](https://github.com/proofhouse/pre-commit-hooks/commit/928d36410dd60a728f4c9a325db9bfba78d48f08)) - [@tbhb](https://github.com/tbhb)
- default vale output to the agent template - ([eefb85f](https://github.com/proofhouse/pre-commit-hooks/commit/eefb85fd11afd5d09029a8770355f6b6d3acae78)) - [@tbhb](https://github.com/tbhb)
- adopt the shared proofhouse vale package - ([8c385c1](https://github.com/proofhouse/pre-commit-hooks/commit/8c385c1f7aed466a9f55b9b0d3874e9fe554878d)) - [@tbhb](https://github.com/tbhb)

- - -

## [v0.2.0](https://github.com/proofhouse/pre-commit-hooks/compare/v0.1.0..v0.2.0) - 2026-06-13

### Features

- use the proofhouse agent template in the vale commit gate when available - ([4a75a0c](https://github.com/proofhouse/pre-commit-hooks/commit/4a75a0cef0ce6e9e50ee5d4fb0a6d7507597ac87)) - [@tbhb](https://github.com/tbhb)

#### Continuous Integration

- (**renovate**) use shared presets in this repo config (#13) - ([e8db1bb](https://github.com/proofhouse/pre-commit-hooks/commit/e8db1bb4d36cf7b75789458b6e4f39d6761aad2b)) - [@tbhb](https://github.com/tbhb)
- (**renovate**) track Vale style packages in .vale.ini (#12) - ([fb0c304](https://github.com/proofhouse/pre-commit-hooks/commit/fb0c304d584dcaaa685ffd371e9c9ea41ae8c65c)) - [@tbhb](https://github.com/tbhb)
- call the shared lint-workflows reusable workflow (#9) - ([397bf8c](https://github.com/proofhouse/pre-commit-hooks/commit/397bf8c3faa9c0769b3d50aeb2d5a0b4c57ecf25)) - [@tbhb](https://github.com/tbhb)
- call the shared lint-codeowners reusable workflow (#8) - ([e7b8a3e](https://github.com/proofhouse/pre-commit-hooks/commit/e7b8a3e45f308bd899f949aa0476293dd81024a3)) - [@tbhb](https://github.com/tbhb)
- call the shared Renovate reusable workflows (#4) - ([a3a8f8f](https://github.com/proofhouse/pre-commit-hooks/commit/a3a8f8f32b454a69e84c4f351bbefa0a96c44714)) - [@tbhb](https://github.com/tbhb)
- source the setup-just action from proofhouse/github-actions (#3) - ([c7c97b4](https://github.com/proofhouse/pre-commit-hooks/commit/c7c97b43fe709f90dc33c88f44cd617645cf2208)) - [@tbhb](https://github.com/tbhb)
- scope Changelog rule exclusions to rumdl per-path config - ([a77e6c6](https://github.com/proofhouse/pre-commit-hooks/commit/a77e6c6d5adf815547767af06827d0b8c4539c38)) - [@tbhb](https://github.com/tbhb)

#### Style

- rephrase prose flagged by ai-tells v1.17.1 - ([e2cf980](https://github.com/proofhouse/pre-commit-hooks/commit/e2cf980e5fe986181fbd2e2fb003a69a9711eb7b)) - [@tbhb](https://github.com/tbhb)

- - -

## [v0.1.0](https://github.com/proofhouse/pre-commit-hooks/compare/aef32c94453a4660a972f2b630a9dd55d32181c8..v0.1.0) - 2026-05-31

### Features

- establish shell-based hooks, toolchain, and CI (#1) - ([8a91d3e](https://github.com/proofhouse/pre-commit-hooks/commit/8a91d3e85ceb34cb654ade13b9a83d49ce8390db)) - [@tbhb](https://github.com/tbhb)

#### Continuous Integration

- drop the Go-sidecar renovate plumbing (#2) - ([ae2ed7f](https://github.com/proofhouse/pre-commit-hooks/commit/ae2ed7fdb76bf53e63095498393c553896a5e339)) - [@tbhb](https://github.com/tbhb)
