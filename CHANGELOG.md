# Changelog

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org/).

Versioning policy (summary):

- MAJOR: Backward-incompatible changes (breaking API changes, method signature changes, or any change that alters the deterministic output sequence for an identical seed / call order without being an explicitly documented bug fix).
- MINOR: Backward-compatible feature additions (new methods, new optional parameters, etc.). Existing deterministic sequences for existing seeds remain stable (except when corrected by a PATCH-level bug fix).
- PATCH: Backward-compatible bug fixes, internal improvements, or documentation-only changes. Public API and existing deterministic output sequences are not modified (unless prior behavior was incorrect per documentation—in such cases the CHANGELOG will call it out explicitly as a fix).
- Pre-release (e.g., 1.1.0-alpha.1): Experimental; output sequence stability is not guaranteed until the final release.

Deterministic output compatibility: the mapping (seed, invocation order) -> value is part of the public API. Changing the underlying algorithm is treated as a MAJOR change unless clearly marked and justified as a bug fix.

Deprecations: A deprecated feature will remain for at least one MINOR release after the deprecation notice before removal in the next MAJOR release.

## [Unreleased]

### 追加

- ここに未リリースの変更を追記してください。

## [1.0.0] - 2025-08-14

### 追加

- 初回リリース: 決定的な擬似乱数ジェネレータ (数値 / hex / alphabetic / alphanumeric 文字列生成)
- 任意オブジェクトシード対応

[Unreleased]: https://github.com/aYosukeMakita/pseudo_random/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/aYosukeMakita/pseudo_random/releases/tag/v1.0.0
