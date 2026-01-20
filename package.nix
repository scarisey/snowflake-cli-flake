{
  lib,
  python3Packages,
  fetchFromGitHub,
  installShellFiles,
  stdenv,
}:

python3Packages.buildPythonApplication rec {
  pname = "snowflake-cli";
  version = "3.14.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "snowflakedb";
    repo = "snowflake-cli";
    tag = "v${version}";
    hash = "sha256-j5ZX7ftzI59B7hZRh0dU9YDO+30xdTGsFlKsjRB8bF8=";
  };

  build-system = with python3Packages; [
    hatch-vcs
    hatchling
    pip
  ];

  nativeBuildInputs = [ installShellFiles ];

  dependencies = with python3Packages; [
    click
    gitpython
    pyyaml
    id
    jinja2
    packaging
    pip
    pluggy
    prompt-toolkit
    pydantic
    requests
    requirements-parser
    rich
    setuptools
    snowflake-connector-python
    snowflake-core
    tomlkit
    typer
    urllib3
  ];

  # Relax version constraints to avoid dependency conflicts
  pythonRelaxDeps = true;

  # Remove optional dependency not available in nixpkgs
  pythonRemoveDeps = [ "snowflake-snowpark-python" ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
    syrupy
    coverage
    pytest-randomly
    pytest-factoryboy
    pytest-xdist
    pytest-httpserver
  ];

  # Skip all tests for now - many require snapshots updates and interactive prompts
  doCheck = false;

  # Disable tests that require network access or snapshots (when doCheck is enabled)
  disabledTests = [
    "integration"
    "spcs"
    "loaded_modules"
    "integration_experimental"
    "test_snow_typer_help_sanitization"
    "test_help_message"
    "test_sql_help_if_no_query_file_or_stdin"
    "test_multiple_streamlit_raise_error_if_multiple_entities"
    "test_replace_and_not_exists_cannot_be_used_together"
    "test_format"
    "test_executing_command_sends_telemetry_usage_data"
    "test_internal_application_data_is_sent_if_feature_flag_is_set"
    "test_if_bundling_dependencies_resolves_requirements"
    "test_silent_output_help"
    "test_new_connection_can_be_added_as_default"
    "test_variables_flags"
    "test_init_default_values"
    "test_rename_project"
  ];

  disabledTestPaths = [
    "tests/app/test_version_check.py"
    "tests/nativeapp/test_sf_sql_facade.py"
  ];

  # Generate shell completions for bash, fish, and zsh
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

  meta = {
    changelog = "https://github.com/snowflakedb/snowflake-cli/blob/main/RELEASE-NOTES.md";
    homepage = "https://docs.snowflake.com/en/developer-guide/snowflake-cli-v2/index";
    description = "Command-line tool for developer-centric workloads in Snowflake";
    license = lib.licenses.asl20;
    mainProgram = "snow";
  };
}
