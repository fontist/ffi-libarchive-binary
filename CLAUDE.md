# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Build
```shell
# Compile binary for current platform
rake compile

# Compile binary for specific host
rake compile[host]

# Build install-time-compiled gem (platform-agnostic)
rake gem:native:any

# Build pre-compiled gem for specific platform
rake gem:native:x64-mingw32
rake gem:native:arm64-darwin
# ... (see Rakefile platforms array for all platforms)
```

### Test
```shell
# Run all tests
rake spec

# Run specific test
rspec path/to/spec.rb
```

### Lint
```shell
# Run RuboCop
rake rubocop

# Auto-fix issues
rubocop -A
```

## Architecture

### Recipe-Based Build System

This gem uses mini_portile2 to build native libarchive binaries. Each dependency has its own recipe class:

- `LibarchiveRecipe` - Main libarchive build
- `Libxml2Recipe` - libxml2 dependency
- `OpensslRecipe` - OpenSSL dependency
- `ZlibRecipe`, `ExpatRecipe`, `XzRecipe` - Additional dependencies

All recipes inherit from `BaseRecipe` which provides common build functionality.

### Platform Configuration

`.github/platforms.json` is the single source of truth for all platform settings. When adding or modifying platforms:

1. Edit `.github/platforms.json`
2. Update the platform arrays (`build_platforms` and `test_platforms`)
3. **Also update the `platforms` array in `Rakefile`** - this is the critical step that's often missed

The Rakefile's `platforms` array defines which rake tasks get created. If a platform is in platforms.json but not in the Rakefile, the build will fail with "Don't know how to build task".

### Gem Compilation Flow

1. **Install-time compilation** (`gem:native:any`): Creates a generic gem that compiles libarchive during `gem install`
2. **Pre-compiled gems** (`gem:native:platform`): Creates platform-specific gems with bundled binaries

Pre-compiled gems include the compiled binaries (.dll/.so/.dylib) and remove the mini_portile2 dependency.

### Binary Placement

Compiled binaries are copied to `lib/ffi-libarchive-binary/` with platform-specific names:
- Windows: `libarchive-13.dll`
- macOS: `libarchive.dylib`
- Linux: `libarchive.so`

The main library file (`lib/ffi-libarchive-binary.rb`) handles path resolution for loading the correct binary.

### Windows ARM64

The `arm64-mingw-ucrt` platform builds for Windows on ARM64 (e.g., Surface Pro X, Windows 11 ARM). It requires GitHub Actions `windows-11-arm` runner.

### OpenSSL Compiler Targets

Windows platforms require explicit compiler targets for OpenSSL because auto-detection is unreliable. See `OpensslRecipe` for the target configuration logic.
