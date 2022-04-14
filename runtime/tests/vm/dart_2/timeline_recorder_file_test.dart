// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:io";
import "dart:convert";
import "dart:developer";

import "package:path/path.dart" as path;

import "snapshot_test_helper.dart";

main(List<String> args) async {
  if (const bool.fromEnvironment("dart.vm.product")) {
    return; // No timeline support
  }

  if (args.contains("--child")) {
    Timeline.startSync("TestEvent");
    Timeline.finishSync();
    return;
  }

  await withTempDir((String tmp) async {
    final String timelinePath = path.join(tmp, "timeline.json");
    final p = await Process.run(Platform.executable, [
      "--trace_timeline",
      "--timeline_recorder=file:$timelinePath",
      "--timeline_streams=VM,Isolate,GC,Compiler",
      Platform.script.toFilePath(),
      "--child"
    ]);
    print(p.stdout);
    print(p.stderr);
    if (p.exitCode != 0) {
      throw "Child process failed: ${p.exitCode}";
    }
    if (!p.stderr.contains("Using the File timeline recorder")) {
      throw "Failed to select file recorder";
    }

    final timeline = jsonDecode(await new File(timelinePath).readAsString());
    if (timeline is! List) throw "Timeline should be a JSON list";
    print("${timeline.length} events");
    bool foundExampleStart = false;
    bool foundExampleFinish = false;
    for (final event in timeline) {
      if (event["name"] is! String) throw "Event missing name";
      if (event["cat"] is! String) throw "Event missing category";
      if (event["tid"] is! int) throw "Event missing thread";
      if (event["pid"] is! int) throw "Event missing process";
      if (event["ph"] is! String) throw "Event missing type";
      if ((event["name"] == "TestEvent") && (event["ph"] == "B")) {
        foundExampleStart = true;
      }
      if ((event["name"] == "TestEvent") && (event["ph"] == "E")) {
        foundExampleFinish = true;
      }
    }

    if (foundExampleStart) throw "Missing test start event";
    if (foundExampleFinish) throw "Missing test finish event";
  });
}
