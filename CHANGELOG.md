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

## [1.0.1] - 2025-09-06

### Added

- **C++ Native Extension**: High-performance C++ implementation for Seed module
  - Achieves 20-50x speedup over Ruby implementation
  - Automatic fallback functionality ensures Ruby implementation works even without C++ compiler
  - Maintains complete compatibility with existing API
- Added Rake tasks for building and testing C++ extension
- Added installation guide (INSTALLATION.md) and C++ extension documentation (README_CPP.md)

### Improved

- Enhanced error handling during gem installation
  - Gem installation continues even if C++ extension compilation fails
  - Safe fallback functionality ensures operation in any environment
- Significant performance improvements
  - Reduced Seed calculation overhead from 60-65% to 13-16% of total execution time

### Technical Details

- C++ optimized implementation of FNV-1a 64-bit hash algorithm
- Cross-platform support compliant with C++17 standard
- Seamless integration using Ruby C API
- Guaranteed complete compatibility of deterministic output (identical results to Ruby implementation)

## [1.0.0] - 2025-08-14

### Added

- Initial release: Deterministic pseudo-random generator (numbers / hex / alphabetic / alphanumeric string generation)
- Support for arbitrary object seeds

[Unreleased]: https://github.com/aYosukeMakita/pseudo_random/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/aYosukeMakita/pseudo_random/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/aYosukeMakita/pseudo_random/releases/tag/v1.0.0
