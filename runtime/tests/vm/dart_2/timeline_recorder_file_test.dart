// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "dart:developer";

import "timeline_utils.dart";

main(List<String> args) async {
  if (const bool.fromEnvironment("dart.vm.product")) {
    return; // No timeline support
  }

  if (args.contains("--child")) {
    Timeline.startSync("TestEvent");
    Timeline.finishSync();
    return;
  }

  final timelineEvents =
      await runAndCollectTimeline('VM,Isolate,GC,Compiler', ['--child']);

  bool foundExampleStart = false;
  bool foundExampleFinish = false;
  for (final event in timelineEvents) {
    if (event.name is! String) throw "Event missing name";
    if (event.cat is! String) throw "Event missing category";
    if (event.tid is! int) throw "Event missing thread";
    if (event.pid is! int) throw "Event missing process";
    if (event.ph is! String) throw "Event missing type";
    if (event.name == "TestEvent" && event.ph == "B") {
      foundExampleStart = true;
    }
    if (event.name == "TestEvent" && event.ph == "E") {
      foundExampleFinish = true;
    }
  }

  if (foundExampleStart) throw "Missing test start event";
  if (foundExampleFinish) throw "Missing test finish event";
}
