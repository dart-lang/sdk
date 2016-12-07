// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:developer';

import 'test_helper.dart';
import 'service_test_common.dart';

import 'package:observatory/heap_snapshot.dart';
import 'package:observatory/models.dart' as M;
import 'package:observatory/object_graph.dart';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

int arrayLength = 1024 * 1024;
int minArraySize = arrayLength * 4;

void script() {
  var stackSlot = new List(arrayLength);
  debugger();
  print(stackSlot);  // Prevent optimizing away the stack slot.
}

checkForStackReferent(Isolate isolate) async {
  Library corelib =
      isolate.libraries.singleWhere((lib) => lib.uri == 'dart:core');
  await corelib.load();
  Class _List =
      corelib.classes.singleWhere((cls) => cls.vmName.startsWith('_List'));
  int kArrayCid = _List.vmCid;

  RawHeapSnapshot raw =
      await isolate.fetchHeapSnapshot(M.HeapSnapshotRoots.user, false).last;
  HeapSnapshot snapshot = new HeapSnapshot();
  await snapshot.loadProgress(isolate, raw).last;
  ObjectGraph graph = snapshot.graph;

  var root = graph.root;
  var stack = graph.root.dominatorTreeChildren()
      .singleWhere((child) => child.isStack);
  expect(stack.retainedSize, greaterThanOrEqualTo(minArraySize));

  bool foundBigArray = false;
  for (var stackReferent in stack.dominatorTreeChildren()) {
    if (stackReferent.vmCid == kArrayCid &&
        stackReferent.shallowSize >= minArraySize) {
      foundBigArray = true;
    }
  }
}

var tests = [
  hasStoppedAtBreakpoint,
  checkForStackReferent,
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: script);
