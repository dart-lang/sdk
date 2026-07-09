# Running/Debugging the Analysis Server from Source in VS Code

When working in the `analysis_server` package it's often useful to have VS Code
run the server from your source instead of using a compiled snapshot from the
SDK (which would require a potentially lengthy SDK build).

Server startup will be slower when running from source so it's recommended to
enable this just for specific projects while testing and not generally run the
server from source.

## VS Code Configuration

- Press `F1` to open the VS Code command palette
- Run the **Preferences: Open Workspace Settings (JSON)** command
- Add a `dart.analyzerPath` setting, pointing to the analysis servers's entry
  script:
  ```
  "dart.analyzerPath": "/Users/developer/dart-sdk/sdk/pkg/analysis_server/bin/server.dart"
  ```
- Add `dart.sdkPath` pointing to an SDK that is compatible with the version of
  the source code being run (such as a recent [bleeding edge build][1]):
  ```
  "dart.sdkPath": "/Users/developer/Dart SDKs/bleeding_edge"
  ```
- Press **Save**

Modifying the `dart.analyzerPath` or `dart.sdkPath` settings will automatically
restart the analysis server. The server may take a little longer than usual to
start up when running from source, but all interactions with the server will now
be your local version.

## Capturing Protocol Traffic

There are a number of ways you can capture the traffic between VS Code and the
Dart analysis server. The simplest way if you just need to capture some ad-hoc
traffic is with the **Dart: Capture Analysis Server Logs** command.

- Press `F1` to open the VS Code command palette
- Run the **Dart: Capture Analysis Server Logs** command
- While the logging notification is visible, use the editor to trigger
  communication with the server.
- If you accidentally hide the logging notification with `<escape>` you can get
  it back by clicking the bell icon in the status bar.
- To stop logging and open the log file, click the **Cancel** button on the
  logging notification.

If you want to have traffic always written to files, you can use some workspace
settings:

- Press `F1` to open the VS Code command palette
- Run the **Preferences: Open Workspace Settings (JSON)** command
- Add a `dart.analyzerLogFile` and/or `dart.analyzerInstrumentationLogFile`
  setting with an absolute or relative path for a log file:
  ```
  "dart.analyzerLogFile": "logs/analyzer.txt",
  "dart.analyzerInstrumentationLogFile": "logs/analyzer.instrum.txt",
  ```
- Press **Save**

The `analyzerLogFile` is captured by the VS Code extension (client-side). This
records all traffic between VS Code and the server as well as some header and
startup information (such as how the server is being spawned) and any output to
stderr. Lines in this log are truncated by default based on the
`dart.maxLogLineLength` setting (you may wish to increase this if
troubleshooting large requests).

The `analyzerInstrumentationLogFile` is written by the server. It also includes
all protocol traffic but also some additional info (such as file watcher events)
that the client does not have visibility of.

Which log file is most useful may depend on your needs.

At the time of writing, modifying the `dart.analyzerInstrumentationLogFile`
setting will automatically restart the analysis server but
`dart.analyzerLogFile` will not. You can force the server to restart using the
**Dart: Restart Analysis Server** command in the VS Code command palette (`F1`)
or restart the whole extension host with the **Developer: Reload Window**
command.

## Attaching a Debugger

If the protocol traffic is not enough, you can attach a debugger to a running
analysis server as long as its VM Service is enabled.

- Open two VS Code windows, one with the `analysis_server` code open and the
  other with a test project that will be running the server from source
- In the test project, follow the instructions above in
  [VS Code Configuration][2] but additionally set the
  `dart.analyzerVmServicePort` setting to an available port number.
  > **NOTE:** This setting will enable the VM Service with authentication codes
  > disabled. Be sure to unset this setting once you are done debugging.
  ```
  "dart.analyzerVmServicePort": 8222
  ```
- Click **Save** (the analysis server will be automatically restarted when
  `dart.analyzerVmServicePort` is modified)
- Switch to the other VS Code instance that has the `analysis_server` source
  loaded
- Press `F1` to open the VS Code command palette
- Run the **Debug: Attach to Dart Process** command
- Type the port number used in the `dart.analyzerVmServicePort` setting above
  and press `<enter>`

This should connect the debugger to the server running in the other VS Code
window. If everything has worked you can add breakpoints in the server code and
trigger them by interacting with the server in the test project. To test this is
working, add a breakpoint to the top of `TextDocumentChangeHandler._changeFile`
in `lib/src/lsp/handlers/handler_text_document_changes.dart` and modify a file
in the test project to ensure the breakpoint is hit and you can evaluate
values using the Debug Console, watch window or hovering over a variable.

## Other Useful Notes

### Multi-Root Workspaces

If you need to work on multiple projects (such as `analysis_server`, `analyzer`,
`analyzer_plugin`) you can open this without everything else in the `pkg` folder
by ctrl+clicking folders in the Open dialog, or by using **File -> Add Folder to
Workspace** to add additional folders.

You can then save this workspace with **File -> Save Workspace** which creates
a `.code-workspace` file that can be re-opened for the same folders later.

When using a `.code-workspace` like this, workspace-level settings (found via
**Preferences: Open Workspace Settings (JSON)** command) will be stored in this
file (since there isn't a single `.vscode/settings.json` file to store them in
for a multi-root workspace). Similarly, launch configurations can be added to
this file that apply to the whole workspace.

### Sorting and Organizing On-Save

In the `analysis_server` package, files should have directives and members
sorted. You can configure this to happen on-save by adding the following to the
workspace settings for the analyzer project:

```js
"editor.codeActionsOnSave": {
	"source.organizeImports": true,
	"source.sortMembers": true
},
```

### Rulers

Code and comments are usually wrapped at 80 characters. You can enable a ruler
at this point in Dart files with the following setting (either at workspace or
user level):

```js
"[dart]": {
  "editor.rulers": [80],
}
```

See [here][3] for some other useful/recommended settings.

### Analyzer Diagnostics Pages

Running the **Dart: Open Analyzer Diagnostics** command will start and open a
small web app that provides some additional insight into the running server,
including some timings and exceptions.


[1]: https://gsdview.appspot.com/dart-archive/channels/be/raw/latest/sdk/
[2]: #vs-code-configuration
[3]: https://dartcode.org/docs/recommended-settings/
