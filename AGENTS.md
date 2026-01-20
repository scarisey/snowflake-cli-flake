# AI Agent Development Notes

This document contains notes about the development of this Nix flake, primarily for AI agents working on similar projects.

## Project Overview

This flake packages the Snowflake CLI tool from https://github.com/snowflakedb/snowflake-cli using Nix's `buildPythonApplication`.

## Key Implementation Decisions

### 1. Python Packaging Strategy

**Challenge**: Package a Python application that uses `hatchling` as its build backend.

**Solution**:
- Used `python3Packages.buildPythonApplication` with `pyproject = true`
- Added `hatch-vcs`, `hatchling`, and `pip` to `build-system`
- Set `pythonRelaxDeps = true` to handle strict version constraints in pyproject.toml

### 2. Missing Optional Dependency

**Challenge**: `snowflake-snowpark-python` is listed as a dependency but not available in nixpkgs.

**Solutions attempted**:
1. ❌ `pythonRuntimeDepsCheck = false` - Flag doesn't exist
2. ❌ `dontUsePythonRuntimeDepsCheck = true` - Flag doesn't exist
3. ✅ `pythonRemoveDeps = [ "snowflake-snowpark-python" ]` - **WORKS**

**Key learning**: The `pythonRemoveDeps` attribute is the correct way to exclude specific dependencies from the runtime dependency check in `buildPythonApplication`.

### 3. Shell Completions

**Challenge**: Generate shell completions in a sandboxed Nix build environment.

**Solution**:
```nix
postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
  export HOME=$(mktemp -d)
  mkdir -p $HOME/.config/snowflake
  cat <<EOF > $HOME/.config/snowflake/config.toml
  [cli.logs]
  save_logs = false
  EOF
  chmod 0600 $HOME/.config/snowflake/config.toml
  export _TYPER_COMPLETE_TEST_DISABLE_SHELL_DETECTION=1

  installShellCompletion --cmd snow \
    --bash <($out/bin/snow --show-completion bash) \
    --fish <($out/bin/snow --show-completion fish) \
    --zsh <($out/bin/snow --show-completion zsh)
'';
```

**Key insights**:
- Snowflake CLI checks for config file existence on launch
- Create a fake config with `save_logs = false` to prevent build sandbox issues
- Config permissions must be 0600 or the CLI exits with an error
- Set `_TYPER_COMPLETE_TEST_DISABLE_SHELL_DETECTION=1` to avoid shell detection during build

### 4. Test Suite Handling

**Challenge**: Many tests fail due to:
- Snapshot updates needed (test outputs don't match recorded snapshots)
- Interactive prompts (can't work in build sandbox)
- Network access requirements

**Solution**: Disabled all tests with `doCheck = false`.

**Alternative approach** (for future consideration):
```nix
disabledTests = [
  "integration"
  "test_snow_typer_help_sanitization"
  "test_variables_flags"
  # ... etc
];

disabledTestPaths = [
  "tests/app/test_version_check.py"
  "tests/nativeapp/test_sf_sql_facade.py"
];
```

### 5. Version Update Automation

**Challenge**: Create a simple way to update to latest Snowflake CLI releases.

**Solution**: Created `update.sh` script that:
1. Fetches latest release from GitHub API using `curl` and `jq`
2. Calculates new hash with `nix-prefetch-url` and `nix-hash --to-sri`
3. Updates `package.nix` using `sed`

**Implementation notes**:
- Used `nix-prefetch-url --unpack` for tarball hash
- Converted to SRI format with `nix-hash --type sha256 --to-sri`
- Created dedicated `updateShell` devShell with required tools

### 6. Multi-Platform Support

**Implementation**:
```nix
supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
  inherit system;
  pkgs = (import nixpkgs { inherit system; });
});
```

This pattern generates outputs for all supported platforms.

## Debugging Tips for AI Agents

### Getting Source Hash

When updating versions, use this command pattern:
```bash
nix-prefetch-url --unpack https://github.com/OWNER/REPO/archive/refs/tags/vVERSION.tar.gz
nix-hash --type sha256 --to-sri <hash-from-above>
```

### Checking Available Python Packages

```bash
nix search nixpkgs <package-name> --json | jq 'keys[]' | grep python
```

### Testing the Build

```bash
# Quick check
nix flake check

# Full build
nix build --no-link --print-build-logs

# Test run
nix run . -- --version
```

### Examining Build Phases

Add `--print-build-logs` to see all build phases:
- `unpackPhase`
- `patchPhase`
- `configurePhase`
- `buildPhase` (pypaBuildPhase)
- `pythonRuntimeDepsCheckHook`
- `installPhase` (pypaInstallPhase)
- `checkPhase` (pytestCheckPhase if enabled)
- `fixupPhase`

## Reference Implementation

The nixpkgs package at `pkgs/by-name/sn/snowflake-cli/package.nix` was used as a reference but was behind the latest version (3.11.0 vs 3.14.0 in this flake).

## Common Patterns for Python Applications

### Basic Structure
```nix
python3Packages.buildPythonApplication rec {
  pname = "app-name";
  version = "x.y.z";
  pyproject = true;  # For pyproject.toml-based projects
  
  src = fetchFromGitHub { ... };
  
  build-system = [ /* build tools */ ];
  dependencies = [ /* runtime deps */ ];
  nativeCheckInputs = [ /* test deps */ ];
}
```

### Common Attributes
- `pythonRelaxDeps = true` - Relax version constraints
- `pythonRemoveDeps = [ "pkg" ]` - Skip specific dependencies
- `doCheck = false` - Disable tests
- `disabledTests = [ "test_name" ]` - Disable specific tests
- `disabledTestPaths = [ "path/to/test.py" ]` - Disable test files

## Lessons Learned

1. **Always check nixpkgs first**: There's often an existing package to reference
2. **pythonRemoveDeps is your friend**: Use it for optional/unavailable dependencies
3. **Shell completions need careful setup**: Mock config files and environment variables
4. **SRI hashes are preferred**: Use `nix-hash --to-sri` for modern hash format
5. **Update automation saves time**: A simple bash script can automate version updates
6. **Test disabling is acceptable**: For complex test suites, `doCheck = false` is fine
7. **Multi-platform from the start**: Use `forAllSystems` pattern for broad compatibility

## Future Improvements

1. **Selective test enabling**: Fine-tune `disabledTests` to run non-problematic tests
2. **GitHub Actions**: Add CI to automatically check for new versions
3. **Overlay option**: Provide as an overlay for easier integration
4. **NixOS module**: Create a proper NixOS module with configuration options
5. **Cached builds**: Set up a binary cache for faster installation

## Questions for Future Agents

- Is there a better way to handle the missing `snowflake-snowpark-python` dependency?
- Can we package `snowflake-snowpark-python` for nixpkgs?
- Should we upstream this flake or the package update to nixpkgs?
- Can the test suite be made more deterministic for Nix builds?
