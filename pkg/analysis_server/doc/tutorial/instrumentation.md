# Instrumentation

This document explains how to gather instrumentation logs, session logs, and
other diagnostic information from a running Dart Analysis Server (DAS) process.

## Collect an instrumentation log

To collect an instrumentation log, DAS needs to be launched with the
`--instrumentation-log-file` option, specifying a path for the log file. Since
the IDE launches DAS, the steps are different for each IDE.

### IntelliJ IDEA and Android Studio

1. In IntelliJ IDEA, click **Help** &gt; **Find Action**, type "Registry" and
   open the "Registry..." item.
2. Scroll down to the `dart.server.additional.arguments` property, and set it's
   value to `--instrumentation-log-file=/some/file.txt`. If there are other
   arguments listed, which you wish to keep, add this new argument to the
   existing value, separated by whitespace.
3. In the **Dart Analysis** panel, click the
   <img src="restart-das-icon-light.png#gh-light-mode-only"
   style="width:16px" /><img src="restart-das-icon.png#gh-dark-mode-only"
   style="width:16px" /> **Restart Dart Analysis Server** button.

After doing those steps, DAS will write an instrumentation log to the specified
file (`/some/file.txt` above).

### VS Code

See the steps outlined at the [Dart Code
documentation](https://dartcode.org/docs/logging/#analyzer-instrumentation).

## Collect a session communications log

A session communications log records all communications between the IDE and the
analysis server. It is useful for capturing an exact sequence of editor
interactions to reproduce bugs or evaluate performance.

For detailed steps on recording a session log (interactively via the Analyzer
Insights page or at startup via `--session-log`), see
[Recording a session communications log](session_log.md).

## Open the analyzer insights (diagnostics) pages

DAS serves a variety of "insights pages" (previously known as the "diagnostics
pages") as a website on `localhost`. Since the IDE launches DAS, the method of
opening this website is different for each IDE.

### IntelliJ IDEA and Android Studio

1. In the **Dart Analysis** panel, click the
   <img src="gear-icon-light.png#gh-light-mode-only" style="width:16px" /><img
   src="gear-icon.png#gh-dark-mode-only" style="width:16px" /> **Analyzer
   Settings** button on the left with the gear icon. Note, this is different
   from the "Show Options Menu" button at the top, which also has a gear icon.
2. Click the **View analyzer diagnostics** link. The analyzer insights website
   should open in an external browser.

### VS Code

1. Open the command palette (Ctrl+Shift+P) and type "Dart: Open Analyzer
   Diagnostics / Insights". The analyzer insights website should open in an
   external browser.

## Using the analyzer insights pages

### Status

The first of the analyzer insights pages is the **Status** page. This page
shows general information about the DAS process, including version information.

### Analysis performance log

### Code Completion

TODO

### Communications

TODO

### Contexts

TODO

### Environment Variables

This page shows all system environment variables as seen from DAS.

### Exceptions

TODO

### Legacy plugins

This page displays information about each _legacy_ analyzer plugin which is
configured for the current workspace.

### LSP Capabilities

This page is available when DAS is launched as an LSP server, and shows the
current Client and Server LSP Capabilities.

### Memory and CPU Usage

This page shows current memory and CPU usage of DAS.

### Plugins

This page displays information about each "new" analyzer plugin (which uses the
plugin system introduced in Dart 3.10) which is configured for the current
workspace.

### Session communications log

This page allows recording communications between the analysis server and the
IDE (or other client process) without restarting the server. It is useful for
capturing a sequence of events to reproduce a bug or investigate unexpected
server behavior.

The server automatically maintains an in-memory cache of essential startup
entries (initialization requests, workspace configurations, and open document
notifications). When you click **Start capturing entries**, subsequent
messages are captured into a buffer.

To record a session from this page:

1. Open the analyzer insights pages (see
   [Open the analyzer insights pages](#open-the-analyzer-insights-diagnostics-pages)).
2. Select **Session communications log** from the left navigation menu.
3. When ready, click **Start capturing entries**.
4. In your IDE, perform the actions you want to capture (e.g., triggering code
   completion, editing a file, or renaming a symbol).
5. Return to this page and click **Stop capturing entries**.
6. Click **Copy to Clipboard** and save the captured JSON entries into a file.

For more details and alternative command-line options, see
[Recording a session communications log](session_log.md).

### Timing

TODO
