// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'heap_snapshot_test.dart';
import 'use_flag_test_helper.dart';

main() async {
  if (const bool.fromEnvironment('dart.vm.product')) return;

  await withTempDir('heap_snapshot_test', (String dir) async {
    final file = path.join(dir, 'state1.heapsnapshot');
    VMInternalsForTesting.writeHeapSnapshotToFile(file);
    final snapshot = loadHeapSnapshotFromFile(file);
    for (final klass in snapshot.classes) {
      // Ensure field indices are unique.
      final fields = klass.fields.toList()..sort((a, b) => a.index - b.index);
      int lastIndex = -1;
      for (int i = 0; i < fields.length; ++i) {
        Expect.notEquals(lastIndex, fields[i].index);
        lastIndex = fields[i].index;
      }
    }
  });
}
