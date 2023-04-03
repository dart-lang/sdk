// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:developer';

import 'package:path/path.dart' as path;

import 'heap_snapshot_test.dart';
import 'use_flag_test_helper.dart';

main() async {
  if (const bool.fromEnvironment('dart.vm.product')) return;
  if (isSimulator) return; // Takes too long on simulators.

  await withTempDir('heap_snapshot_test', (String dir) async {
    final file = path.join(dir, 'state1.heapsnapshot');
    NativeRuntime.writeHeapSnapshotToFile(file);
    final graph = loadHeapSnapshotFromFile(file);
    final reachable = findReachableObjects(graph);

    for (int id = 0; id < graph.objects.length; ++id) {
      final object = graph.objects[id];

      // Ensure all `references` appear in `referrers`.
      for (final rid in object.references) {
        final users = graph.objects[rid].referrers;
        if (!users.contains(id)) {
          throw 'Object $id references $rid, but is not in referrers';
        }
      }

      // Ensure all `referrers` appear in `references`.
      for (final uid in object.referrers) {
        final refs = graph.objects[uid].references;
        if (!refs.contains(id)) {
          throw 'Object $id is referenced by $uid, but is not in references.';
        }
      }
    }
  });
}
