// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal';
import 'dart:developer';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart';

import 'use_flag_test_helper.dart';

final bool alwaysTrue = int.parse('1') == 1;

@pragma('vm:entry-point') // Prevent name mangling
class Foo {}

var global = null;

main() async {
  if (const bool.fromEnvironment('dart.vm.product')) {
    var exception;
    try {
      await runTest();
    } on UnsupportedError catch (e) {
      exception = e;
    }
    Expect.contains(
        'Heap snapshots are only supported in non-product mode.', '$exception');
    return;
  }

  await runTest();
}

Future runTest() async {
  await withTempDir('heap_snapshot_test', (String dir) async {
    final state1 = path.join(dir, 'state1.heapsnapshot');
    final state2 = path.join(dir, 'state2.heapsnapshot');
    final state3 = path.join(dir, 'state3.heapsnapshot');

    var local;

    NativeRuntime.writeHeapSnapshotToFile(state1);
    if (alwaysTrue) {
      global = Foo();
      local = Foo();
    }
    NativeRuntime.writeHeapSnapshotToFile(state2);
    if (alwaysTrue) {
      global = null;
      local = null;
    }
    NativeRuntime.writeHeapSnapshotToFile(state3);

    final int count1 = countFooInstances(
        findReachableObjects(loadHeapSnapshotFromFile(state1)));
    final int count2 = countFooInstances(
        findReachableObjects(loadHeapSnapshotFromFile(state2)));
    final int count3 = countFooInstances(
        findReachableObjects(loadHeapSnapshotFromFile(state3)));

    Expect.equals(0, count1);
    Expect.equals(2, count2);
    Expect.equals(0, count3);

    reachabilityFence(local);
    reachabilityFence(global);
  });
}

HeapSnapshotGraph loadHeapSnapshotFromFile(String filename) {
  final bytes = File(filename).readAsBytesSync();
  return HeapSnapshotGraph.fromChunks([bytes.buffer.asByteData()]);
}

Set<HeapSnapshotObject> findReachableObjects(HeapSnapshotGraph graph) {
  const int rootObjectIdx = 1;

  final reachableObjects = Set<HeapSnapshotObject>();
  final worklist = <HeapSnapshotObject>[];

  final rootObject = graph.objects[rootObjectIdx];

  reachableObjects.add(rootObject);
  worklist.add(rootObject);

  while (worklist.isNotEmpty) {
    final objectToExpand = worklist.removeLast();

    for (final successor in objectToExpand.successors) {
      if (!reachableObjects.contains(successor)) {
        reachableObjects.add(successor);
        worklist.add(successor);
      }
    }
  }
  return reachableObjects;
}

int countFooInstances(Set<HeapSnapshotObject> reachableObjects) {
  int count = 0;
  for (final object in reachableObjects) {
    if (object.klass.name == 'Foo') count++;
  }
  return count;
}
