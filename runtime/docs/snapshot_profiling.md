# AOT Snapshot Size Profiling

The VM supports profiling the size of AOT snapshots by leveraging the object-graph based file format introduced by V8.

## Recording a profile

To generate a snapshot profile, simply pass the `--write-v8-snapshot-profile-to=<filename>` flag to `gen_snapshot`.
The profile will be written in JSON format to the requested file.
Make sure to use the ".heapsnapshot" extension for the file to open it in Chrome DevTools.

## Examining a profile in Chrome

Open Chrome DevTools, navigate to the "Memory" tab, right-click on the "Profiles" panel, click Load..." and select the snapshot profile file.
See https://developers.google.com/web/tools/chrome-devtools/memory-problems/heap-snapshots for details on how to use the tool.

## Examining a profile programmatically

A Dart library to parse the snapshot profile format is provided in `pkg/vm/lib/v8_snaphsot_profile.dart`.
The `dart2js_info` package has some useful code for calculating retainers and other graph statistics.
