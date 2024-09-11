// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  final timelineEvents = await runAndCollectTimeline('Dart', ['--child']);

  bool foundExampleStart = false;
  bool foundExampleFinish = false;
  bool foundExampleThreadName = false;
  for (final event in timelineEvents) {
    if (event.name == "TestEvent" && event.ph == "B") {
      foundExampleStart = true;
    }
    if (event.name == "TestEvent" && event.ph == "E") {
      foundExampleFinish = true;
    }
    if (event.name == "thread_name" && event.ph == "M") {
      foundExampleThreadName = true;
    }
  }

  if (!foundExampleStart) throw "Missing test start event";
  if (!foundExampleFinish) throw "Missing test finish event";
  if (!foundExampleThreadName) throw "Missing thread name metadata event";
}
