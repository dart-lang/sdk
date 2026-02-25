This directory contains tools for recording and replaying a real world
analysis server session, in order to reproduce issues and validate fixes.

This involves 3 steps:

1. Recording a session to a log file.
2. Normalizing the log file so it is portable across machines.
3. Adding the scenario, which includes project setup and a pointer to the
   normalized log file.

## Recording a session from VsCode

In order to record a session, seach for "Open analyzer Diagnostics/Insights"
in the VsCode command pallet (ctrl+shift+p, or cmd+shift+p). This should open
up the web app for analysis server diagnostics.

From here, select "Session communications log" from the left hand menu.

When you are ready to record your session, click "Start capturing entries", and
when you are done click "Stop capturing entries".

Copy the contents of the captured log to a file on your machine somewhere.

## Normalizing the log file

In order to normalize the log file, you will use the script at
`pkg/analysis_server/tool/log_player/normalize.dart`. This script requires
the following arguments:

- `-i <path>` The original log
- `-o <path>` The output path for the normalized log
- `-p <path>` The path to the package config file for the project that you
  recorded from. This file will typically be at `.dart_tool/package_config.json`
  relative to the root of the project.

The normalized log files should be written to
`tools/performance/scenarios/logs/<scenario-name>.log`.

For example, if you are running from the SDK root, and your original log file is
at `log.json`, you could run the following:

```bash
dart pkg/analysis_server/tool/log_player/normalize.dart \
  -i log.json
  -o pkg/analysis_server/tool/performance/scenarios/logs/my_awesome_scenario.log
  -p .dart_tool/package_config.json
```

## Setting up the scenario

Scenarios require a project, a log file, and name.

Projects are either set up by cloning a git repo (typical for external repo
scenarios), or by creating a git worktree for a local project (recommended
for SDK scenarios).

Scenarios are set up in
`pkg/analysis_server/tool/performance/scenarios/run_saved_scenarios.dart`, find
the top level `scenarios` variable in that file, and add a scenario following
the pattern established there by the existing ones, or see the following
examples:

### Example git clone project (non-SDK git repo)

```dart
Scenario(
  name: 'my_scenario',
  logFile: fileSystem.getFile(
    logsRoot.resolve('my_scenario.json').toFilePath(),
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
    logsRoot.resolve('my_sdk_scenario.json').toFilePath(),
  ),
  project: GitWorktreeProjectGenerator(
    Directory.fromUri(sdkRoot),
    'commit-ish',
    isSdkRepo: true,
    // Restricts analysis to only these dirs, must match the directories you had
    // open when recording the session.
    openSubdirs: ['pkg/analysis_server'],
  ),
)
```

## Running scenarios

To run scenarios, use the
`pkg/analysis_server/tool/performance/scenarios/run_saved_scenarios.dart`
script.

By default this will run all scenarios, but you can pass `-s <scenario-name>`
to run just a specific scenario.

**Suggestion**: pass `--help` to see the available scenarios.
