# Profiling the analysis server hosted by VS Code

The steps below show how to use the DevTools CPU profiler against the instance
of the analysis server being hosted by VS Code. This allows profiling a short
window of operations (such as typing in the editor or invoking code completion).

- Open a project in VS Code that can be used to trigger the bad performance
- Run the **Preferences: Open Workspace Settings (JSON)** command from the
  command palette (`F1`) or open the `.vscode/settings.json` file
- Add `"dart.analyzerVmServicePort": 8855` (the exact port number is not important
  but you'll need it further down)
- Save the settings file
- A toast notification should appear in the bottom right warning you that the
  analysis server's VM Service is enabled. This is a reminder that you should
  remove the `dart.analyzerVmServicePort` setting when you are done.
- Wait for initial analysis to complete (No "Analyzing..." or spinners in the
  status bar)
- Open a file and find a location where you can reproduce the bad performance
- Run the **Dart: Open DevTools in Browser** command from the palette (`F1`)
- In DevTools, enter `http://localhost:8855/` (using the port number from above)
  and click **Connect**
- Navigate to the **CPU Profiler** tab
- Click **Enable Profiler**
- In the isolate selector (bottom middle of the page), select the Isolate named
  **main**
- Click the **Start recording** button
- Switch back to VS Code and perform the actions that cause bad performance
- Back in DevTools, click the **Stop recording** button in the CPU Profiler

Profiling information should be displayed automatically and can be exported
using the export button on the top right corner. Exported information may
contain paths and class/member names from your project.

When you are done, don't forget to remove the VM Service port from your
workspace settings:

- Run the **Preferences: Open Workspace Settings (JSON)** command from the
  command palette (`F1`) or open the `.vscode/settings.json` file
- Remove the `"dart.analyzerVmServicePort": 8855` setting
- Save the settings file
