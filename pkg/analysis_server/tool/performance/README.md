# Performance Scenarios

This directory contains tools for managing and executing automated performance
benchmarking scenarios for the Dart Analysis Server (DAS).

Scenarios reproduce realistic developer workflows by replaying recorded and
normalized session logs against specific git commits of projects.

For interactive debugging and stepping through logs without setting up a
permanent scenario, see the [Log Player tools](../log_player/README.md).

## Adding a new scenario

Adding a benchmark scenario involves three steps:

1. **Record a session log**: Capture the workflow from your editor or the
   command line. See
   [Recording a session communications log](../../doc/tutorial/session_log.md)
   for instructions.

2. **Normalize the log file**: Scrub machine-specific paths so the log is
   portable across environments. Use
   [`normalize.dart`](../log_player/normalize.dart) as described in
   [Normalizing the Log](../log_player/README.md#step-1-normalize-the-log).
   Write the output to
   `pkg/analysis_server/tool/performance/scenarios/logs/<scenario-name>.log`:

   ```bash
   dart pkg/analysis_server/tool/log_player/normalize.dart \
     -i /path/to/raw_log.json \
     -o pkg/analysis_server/tool/performance/scenarios/logs/<scenario-name>.log \
     -r /path/to/project/root \
     [-p .dart_tool/package_config.json]
   ```

3. **Configure the scenario**: Add a new `Scenario` entry to `scenarios` in
   [`pkg/analysis_server/tool/performance/scenarios/run_saved_scenarios.dart`](scenarios/run_saved_scenarios.dart).

## Setting up the scenario

Scenarios require a name, a pointer to the normalized log file, and a project
generator.

Projects are either set up by cloning a git repository (typical for external
projects) or by creating a git worktree for a local project (recommended for
Dart SDK scenarios).

Scenarios are defined in the `scenarios` list in
`pkg/analysis_server/tool/performance/scenarios/run_saved_scenarios.dart`.

### Example git clone project (non-SDK git repo)

```dart
Scenario(
  name: 'my_scenario',
  logFile: fileSystem.getFile(
    logsRoot.resolve('my_scenario.log').toFilePath(),
  ),
  project: GitCloneProjectGenerator(
    'https://github.com/my-org/my-repo',
    // The commit, branch, tag etc that the scenario was recorded at.
    'commit-ish',
  ),
)
```

### Example git worktree project (Dart SDK)

```dart
Scenario(
  name: 'my_sdk_scenario',
  logFile: fileSystem.getFile(
    logsRoot.resolve('my_sdk_scenario.log').toFilePath(),
  ),
  project: GitWorktreeProjectGenerator(
    Directory.fromUri(sdkRoot),
    'commit-ish',
    isSdkRepo: true,
    // Restricts analysis to only these dirs; must match the directories open
    // when recording the session.
    openSubdirs: ['pkg/analysis_server'],
  ),
)
```

## Running scenarios

To run scenarios, use the
`pkg/analysis_server/tool/performance/scenarios/run_saved_scenarios.dart` script:

```bash
dart pkg/analysis_server/tool/performance/scenarios/run_saved_scenarios.dart
```

By default this runs all scenarios. You can filter to a specific scenario with
`-s`:

```bash
dart pkg/analysis_server/tool/performance/scenarios/run_saved_scenarios.dart \
    -s <scenario-name>
```

Pass `--help` to view all available scenarios and CLI options (e.g., `-v` for
verbose output, `-t` for timeouts).
