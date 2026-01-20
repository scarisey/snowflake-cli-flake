# snowflake-cli-flake

A Nix flake for the [Snowflake CLI](https://github.com/snowflakedb/snowflake-cli) - a command-line tool for developer-centric workloads in Snowflake.

## Features

- ✅ **Latest version**: Currently packaging Snowflake CLI v3.14.0
- 🐚 **Shell completions**: Automatic generation of bash, zsh, and fish completions
- 🔄 **Auto-update script**: Easily update to the latest upstream release
- 🏗️ **Multi-platform**: Supports x86_64-linux, aarch64-linux, x86_64-darwin, and aarch64-darwin

## Quick Start

### Using the flake directly

```bash
# Run snowflake-cli without installing
nix run github:scarisey/snowflake-cli-flake -- --version

# Enter a shell with snow command available
nix develop github:scarisey/snowflake-cli-flake

# Install to your profile
nix profile install github:scarisey/snowflake-cli-flake
```

### In your own flake

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    snowflake-cli.url = "github:scarisey/snowflake-cli-flake";
  };

  outputs = { self, nixpkgs, snowflake-cli }: {
    # Use in your devShell
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      packages = [
        snowflake-cli.packages.x86_64-linux.default
      ];
    };
  };
}
```

### In NixOS configuration

```nix
{
  inputs.snowflake-cli.url = "github:scarisey/snowflake-cli-flake";
  
  outputs = { self, nixpkgs, snowflake-cli }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [{
        environment.systemPackages = [
          snowflake-cli.packages.x86_64-linux.default
        ];
      }];
    };
  };
}
```

## Development

### Clone and build locally

```bash
git clone https://github.com/scarisey/snowflake-cli-flake.git
cd snowflake-cli-flake

# Build the package
nix build

# Run the package
nix run . -- --version

# Enter development shell
nix develop
```

### Updating to latest Snowflake CLI version

The repository includes an automated update script:

```bash
# Enter the update environment
nix develop .#updateShell

# Run the update script
./update.sh

# Test the updated package
nix build
```

The script will:
1. Fetch the latest release from GitHub
2. Calculate the new source hash
3. Update `package.nix` with the new version and hash
4. Provide instructions for testing

## Package Details

### Build System

The package uses:
- **Build backend**: `hatchling` with `hatch-vcs` for version management
- **Python version**: ≥ 3.10
- **Entry point**: `snow` command

### Dependencies

Core dependencies included:
- `click`, `typer` - CLI framework
- `rich` - Terminal formatting
- `snowflake-connector-python` - Snowflake connectivity
- `snowflake-core` - Snowflake core libraries
- `pydantic` - Data validation
- `jinja2` - Templating
- `GitPython` - Git operations
- And more...

**Note**: `snowflake-snowpark-python` is an optional dependency not included in nixpkgs and is excluded via `pythonRemoveDeps`.

### Shell Completions

Shell completions are automatically generated during the build process for:
- Bash
- Zsh
- Fish
- PowerShell

## Project Structure

```
.
├── flake.nix          # Nix flake definition
├── package.nix        # Snowflake CLI package derivation
├── update.sh          # Automated version update script
├── README.md          # This file
└── LICENSE            # License file
```

## Resources

- **Upstream repository**: https://github.com/snowflakedb/snowflake-cli
- **Official documentation**: https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index
- **Release notes**: https://github.com/snowflakedb/snowflake-cli/blob/main/RELEASE-NOTES.md

## License

This flake packaging is provided under the same license as the upstream project (Apache 2.0).

The Snowflake CLI itself is licensed under Apache License 2.0.
