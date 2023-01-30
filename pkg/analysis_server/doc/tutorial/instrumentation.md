# Instrumentation

This document explains how to gather instrumentation logs and other diagnostic
information from a running Dart Analysis Server (DAS) process.

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

## Open the analyzer diagnostics pages

DAS serves a variety of "diagnostics pages" as a website on `localhost`. Since
the IDE launches DAS, the method of opening this website is different for each
IDE.

### IntelliJ IDEA and Android Studio

1. In the **Dart Analysis** panel, click the
   <img src="gear-icon-light.png#gh-light-mode-only" style="width:16px" /><img
   src="gear-icon.png#gh-dark-mode-only" style="width:16px" /> **Analyzer
   Settings** button on the left with the gear icon. Note, this is different
   from the "Show Options Menu" button at the top, which also has a gear icon.
2. Click the **View analyzer diagnostics** link. The analyzer diagnostics
   website should open in an external browser.

### VS Code

1. Open the command palette (Ctrl+Shift+P) and type "Dart: Open Analyzer
   Diagnostics". The analyzer diagnostics website should open in an external
   browser.

## Using the analyzer diagnostics pages

### Status

The first of the analyzer diagnostics pages is the **Status** page. This page
shows general information about the DAS process, including version information.

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

### LSP Capabilities

This page is available when DAS is launched as an LSP server, and shows the
current Client and Server LSP Capabilities.

### Memory and CPU Usage

This page shows current memory and CPU usage of DAS.

### Plugins

TODO

### Subscriptions

TODO

### Timing

TODO
