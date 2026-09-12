# Recording a Session Communications Log

This document explains how to record a session communications log from a
running Dart Analysis Server (DAS) process.

## What is a session communications log?

A session communications log records all communications (requests, responses,
and notifications) between a client (such as VS Code or IntelliJ / Android
Studio) and DAS.

These logs are particularly helpful when:

* reporting or diagnosing bugs in the analysis server,
* capturing a sequence of editor actions (e.g. code completion, refactorings,
  diagnostics) for reproduction,
* providing test cases for SDK developers to replay sessions and verify fixes.

There are two ways to record a session communications log:

1. [Interactively via the Analyzer Insights web page](#record-via-the-analyzer-insights-web-page)
   (recommended for capturing specific editor interactions).
2. [At startup via the `--session-log` command-line option](#record-via-the---session-log-command-line-option)
   (captures all communications from the moment the server launches).

## Record via the Analyzer Insights web page

The Analyzer Insights website served by DAS includes a **Session communications
log** page. Even before you click "Start capturing", the server maintains a
small in-memory cache of critical startup messages (initialization requests,
workspace configurations, and opened documents). When you start capturing,
subsequent editor interactions are added to the buffer, ensuring the resulting
log contains the context needed to reproduce the session.

1. Open the Analyzer Insights pages in your browser (see
   [Open the analyzer insights (diagnostics) pages](instrumentation.md#open-the-analyzer-insights-diagnostics-pages)).
2. In the left-hand navigation menu of the insights page, select **Session
   communications log**.
3. When you are ready to perform the actions you wish to record, click the
   **Start capturing entries** button.
4. Switch to your editor and reproduce the issue or perform the workflow (for
   example, triggering code completion, typing code, applying a quick fix, or
   renaming a symbol).
5. Return to the browser page and click **Stop capturing entries**.
6. Click **Copy to Clipboard**.
7. Paste the contents into a text editor and save it as a JSON file (e.g.
   `session_log.json`), or attach it to your issue report.

## Record via the `--session-log` command-line option

If you need to record every communication from server startup (or cannot use the
web UI), you can pass the `--session-log` flag to DAS. The server will stream
log entries line-by-line to the specified file on disk.

### VS Code

1. Open your VS Code settings (`Preferences: Open User Settings (JSON)` or
   `Preferences: Open Workspace Settings (JSON)`).
2. Add the `--session-log` option to `dart.analyzerAdditionalArgs`:

   ```json
   "dart.analyzerAdditionalArgs": [
     "--session-log=/path/to/session_log.json"
   ]
   ```

3. Restart the analysis server by opening the command palette and running
   **Dart: Restart Analysis Server**.
4. Perform the actions you want to capture.
5. When done, remove the argument from your settings and restart the server
   again so the log file stops growing.

### IntelliJ IDEA / Android Studio

1. Click **Help** &gt; **Find Action**, type "Registry" and open **Registry...**.
2. Find the property `dart.server.additional.arguments`.
3. Add `--session-log=/path/to/session_log.json` to the property's value
   (separated from any other arguments by a space).
4. In the **Dart Analysis** window, click the **Restart Dart Analysis Server**
   button.
5. When finished recording, remove the argument from the registry property and
   restart the server.

### Direct server execution

When running the analysis server or language server directly from the command
line:

```bash
dart language-server --protocol=lsp --session-log=/path/to/session_log.json
```

## Log format

The recorded file contains line-delimited JSON (JSON Lines format, often saved
as `.json` or `.txt`). Each line is an independent, self-contained JSON object
representing a single event:

- `time`: Milliseconds since epoch when the event occurred.
- `kind`: The type of event (e.g., `commandLine` or `message`).
- `sender`: The source process (e.g., `ide`, `server`, `watcher`, or `dtd`).
- `receiver`: The destination process.
- `message`: The JSON-RPC payload sent between the processes.

## Inspecting request latencies in the log

You can evaluate the duration of any request/response interaction directly from
the log:

1. Find the client request line (where `"sender": "ide"` and `"receiver": "server"`).
   Note its `"id"` and its timestamp (`"time"` or `"clientRequestTime"` within
   `"message"`).
2. Find the corresponding server response line with the matching `"id"` (where
   `"sender": "server"` and `"receiver": "ide"`).
3. The round-trip duration is the difference:
   `response.time - request.time` (or `response.time - request.message.clientRequestTime`).

> [!NOTE]
> **Cold start vs. warm server**: When an IDE first opens a workspace, the
> server initializes and analyzes files in the background (tracked via
> `$/progress` notifications). Requests sent before initial analysis finishes
> will wait in the server's queue, so their response time includes initial
> workspace analysis. Subsequent requests executed once the server is idle
> reflect actual handler computation time.

## Privacy and path anonymization

Recorded session logs contain file paths on your machine (e.g.
`/Users/$USER/...`) as well as file contents for documents opened or edited
during the session.

If you are sharing a log file publicly (such as on the Dart SDK issue tracker):

1. Review the log file to ensure it does not include sensitive or proprietary
   source code.
2. You can normalize machine-specific paths into generic placeholders
   (`{{workspaceFolder-0}}`, `{{dartSdkRoot}}`, etc.) using `normalize.dart`:

   ```bash
   dart pkg/analysis_server/tool/log_player/normalize.dart \
     -i /path/to/session_log.json \
     -o /path/to/normalized_log.json \
     -r /path/to/workspace/root
   ```

## Next steps

Once you have recorded a log file:

1. Attach the file to your Dart SDK or IDE extension issue report.
2. SDK contributors can normalize, replay, and profile the log using the tools
   in [`pkg/analysis_server/tool/log_player`](../tool/log_player/README.md).
