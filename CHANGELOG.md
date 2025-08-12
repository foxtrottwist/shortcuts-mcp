## [2.2.0](https://github.com/foxtrottwist/shortcuts-mcp/compare/v2.1.1...v2.2.0) (2025-08-12)

### Features

* modernize prompts for Claude 4 capabilities ([188dae3](https://github.com/foxtrottwist/shortcuts-mcp/commit/188dae39eac6d8277698d4d535cff3b3f0f1b1b8))

## [2.1.1](https://github.com/foxtrottwist/shortcuts-mcp/compare/v2.1.0...v2.1.1) (2025-08-10)

### Bug Fixes

- handle newline in AppleScript "missing value\n" response ([bf38270](https://github.com/foxtrottwist/shortcuts-mcp/commit/bf382701042bf8f88ecd6bed481f091540cd3f8d))

## [2.1.0](https://github.com/foxtrottwist/shortcuts-mcp/compare/v2.0.0...v2.1.0) (2025-08-10)

### Features

- handle AppleScript "missing value" response for shortcuts with no output ([9e16fa9](https://github.com/foxtrottwist/shortcuts-mcp/commit/9e16fa9b0491e37723f92941ce5e8463e49f3473))

## [2.0.0](https://github.com/foxtrottwist/shortcuts-mcp/compare/v1.3.0...v2.0.0) (2025-08-10)

### ⚠ BREAKING CHANGES

- fix semantic-release to properly handle breaking changes and sync versions
- fix semantic-release to sync manifest.json versions and attach DXT assets

### Features

- fix semantic-release to properly handle breaking changes and sync versions ([7945124](https://github.com/foxtrottwist/shortcuts-mcp/commit/7945124e24fa043832becdd88cae9c5ed9812827))
- fix semantic-release to sync manifest.json versions and attach DXT assets ([5cba874](https://github.com/foxtrottwist/shortcuts-mcp/commit/5cba874217eca240d97de92f7a06b0fbb65efe11))

# [1.3.0](https://github.com/foxtrottwist/shortcuts-mcp/compare/v1.2.1...v1.3.0) (2025-08-09)

### Bug Fixes

- `user_context` update: resources -> result ([4ae7c04](https://github.com/foxtrottwist/shortcuts-mcp/commit/4ae7c04559374b003212d065473cfdc38d1a5d87))
- only request sampling if client capabilities support it ([717bc79](https://github.com/foxtrottwist/shortcuts-mcp/commit/717bc79286f55f8859f459e7180b737d90766a5f))
- redirect Pino logs to stderr and fix test expectations ([db86114](https://github.com/foxtrottwist/shortcuts-mcp/commit/db86114b8615a9145209970ed49d56c74fdc9e52))
- semantic-release version management for manifest.json ([0cebfa1](https://github.com/foxtrottwist/shortcuts-mcp/commit/0cebfa14210a8c0555f6f22d5941aac8cd85c6b9))

### Features

- add dynamic resource selection to run_shortcut tool ([8a63df8](https://github.com/foxtrottwist/shortcuts-mcp/commit/8a63df88ee32f58a72bceef59b70789e8760113f))
- add getVersion helper ([a589c0a](https://github.com/foxtrottwist/shortcuts-mcp/commit/a589c0ac6bbb0011b31aa7f87d3f05563356fb3b))
- add sampling for statistics generation ([816c718](https://github.com/foxtrottwist/shortcuts-mcp/commit/816c718af41038e06df726411f87e29e1e00f5b2))
- add sampling infrastructure and fix time-based tests ([57efb71](https://github.com/foxtrottwist/shortcuts-mcp/commit/57efb71a8dcb37fa20b53d4e9dfe4092b1008e8b))
- complete sampling module with convenience functions ([67ae465](https://github.com/foxtrottwist/shortcuts-mcp/commit/67ae4656ec230c49bb5087f0ceaa6529876e055e))
- integrate sampling for statistics in statistics://generated resource ([fefee6f](https://github.com/foxtrottwist/shortcuts-mcp/commit/fefee6f2cb31dc7ee368824489c1ee6bdd806be0))
- refactor tools for sampling-driven resource selection ([49e7b01](https://github.com/foxtrottwist/shortcuts-mcp/commit/49e7b01ecf0a4d74823742b6f8a4a34e3d19499b))
- remove input/output from execution logs for privacy ([264a825](https://github.com/foxtrottwist/shortcuts-mcp/commit/264a825d74324f8f28901db106e98b74229bd3e0))
