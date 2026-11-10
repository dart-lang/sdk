# Analysis Server Log Player and Replay Tools

This directory contains tools for normalizing and replaying recorded analysis
server session logs. Replaying logs allows developers to reproduce issues, step
through client-server communications interactively, and validate performance or
bug fixes across different environments.

For instructions on recording a session log, see
[Recording a session communications log](../../doc/tutorial/session_log.md).

## Step 1: Normalize the log

Raw session logs contain absolute paths specific to the machine where they were
recorded. Before replaying a log on another machine or running it in automated
scenarios, run `normalize.dart` to make it portable:

```bash
dart pkg/analysis_server/tool/log_player/normalize.dart \
  -i /path/to/raw_session.json \
  -o /path/to/normalized_session.json \
  -r /path/to/project/root \
  [-p /path/to/.dart_tool/package_config.json]
```

### Options:

* `-i`, `--input`: (Required) path to the raw recorded log file.
* `-o`, `--output`: (Required) path to write the normalized log output.
* `-r`, `--root-dir`: (Required) path to the project root directory where the
  recording was made.
* `-p`, `--package-config`: path to `package_config.json` if not located at the
  standard `.dart_tool/package_config.json` under `--root-dir`.
* `-h`, `--help`: displays option descriptions.

## Step 2: Replaying the log

There are two primary ways to replay a normalized log:

### A. Interactive replay (`server_driver_main.dart`)

`server_driver_main.dart` is ideal for manual debugging and stepping through a
reproduction trace.

1. Navigate to the root directory of the project matching the recorded session:

   ```bash
   cd /path/to/project/root
   ```

2. Run `server_driver_main.dart` with the path to the normalized log:

   ```bash
   dart <sdk-root>/pkg/analysis_server/tool/log_player/server_driver_main.dart \
       path/to/normalized_session.json
   ```

   > [!TIP]
   > **Replaying with a locally compiled SDK**: `ServerDriver` launches DAS
   > using `Platform.resolvedExecutable` (the `dart` binary running the script).
   > To test against changes made in the Dart SDK repo, recompile DAS and invoke
   > `server_driver_main.dart` using the built binary.
   >
   > If running from an external directory where package resolution fails,
   > specify `--packages=<sdk-root>/.dart_tool/package_config.json`.

3. The tool starts a new analysis server process in LSP mode, mapping
   `{{workspaceFolder-0}}`, `{{rootPath}}`, and `{{rootUri}}` to your current
   working directory.
4. Press **Enter** to step through the log. Each press sends the next client
   message (`>>>`) to the server and displays incoming messages from the server
   (`<<<`).

#### Manual stdin mode

Running `server_driver_main.dart` without arguments allows you to type or paste
individual JSON-RPC messages line-by-line to test server reactions directly:

```bash
dart pkg/analysis_server/tool/log_player/server_driver_main.dart
```

### B. Automated scenario replay (`LogPlayer` and performance scenarios)

The `LogPlayer` class in `log_player.dart` provides fully automated playback:

1. spawns the analysis server with the exact command-line arguments recorded in
   the log.
2. automatically responds to server-initiated requests (e.g.,
   `workspace/configuration`, work progress creation).
3. verifies that server responses match recorded expectations, ignoring
   non-deterministic notifications like `textDocument/publishDiagnostics`.

Automated performance scenarios leverage `LogPlayer` to run reproducible
benchmarks. For instructions on defining project configurations and running
saved scenarios, see
[pkg/analysis_server/tool/performance/README.md](../performance/README.md).

---

## Cold-start queueing vs. warm request latency

When replaying a session or inspecting request durations in recorded logs:

1. **Initial workspace analysis (cold start)**:
   Immediately after the client sends `initialize` and `initialized`, the
   analysis server indexes and analyzes the workspace files in the background.
   This process is tracked by `$/progress` notifications
   (`"title": "Analyzing..."`).

2. **Queueing of early requests**:
   Any requests sent by the client while the server is still analyzing files
   (e.g., early `textDocument/documentColor` or `textDocument/codeAction`
   requests) will wait in the server's task queue behind background analysis. As
   a result, the observed duration between the request and response lines
   (`response.time - request.time`) will reflect queue waiting time rather than
   actual handler computation.

3. **Measuring handler execution time (warm server)**:
   To evaluate the true computational latency of a request handler:
   * In recorded logs, inspect requests that occur **after** initial analysis
     has completed (after the `$/progress` end notification).
   * In interactive replay, wait for background analysis notifications to finish
     before pressing Enter to send the target request.

## End-to-end developer workflow

A typical cycle for diagnosing and validating fixes with these tools:

1. **Record the session log**: Follow
   [Recording a session communications log](../../doc/tutorial/session_log.md)
   to capture the issue.

2. **Inspect the log**: Identify the failing response or slow request by
   matching request/response IDs. Compute `response.time - request.time`.

3. **Normalize the log**:
   ```bash
   dart pkg/analysis_server/tool/log_player/normalize.dart \
     -i raw_log.json -o normalized_log.json -r /path/to/project/root
   ```

4. **Reproduce the issue**:
   Replay the log against the baseline server using `server_driver_main.dart` or
   a custom replay script. Verify the error occurs or measure baseline execution
   time.

5. **Implement the fix**: Make the required modifications in
   `pkg/analysis_server` or `pkg/analyzer`.

6. **Rebuild the SDK**:

   ```bash
   python3 tools/build.py -mrelease create_sdk
   ```

7. **Replay to validate**:
   Run the replay tool again using the newly compiled SDK binary. Verify that
   the issue is resolved or that latency has improved.
