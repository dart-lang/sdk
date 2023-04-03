// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:developer';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'heap_snapshot_test.dart';
import 'use_flag_test_helper.dart';

main() async {
  if (const bool.fromEnvironment('dart.vm.product')) return;

  await withTempDir('heap_snapshot_test', (String dir) async {
    final file = path.join(dir, 'state1.heapsnapshot');
    NativeRuntime.writeHeapSnapshotToFile(file);
    final snapshot = loadHeapSnapshotFromFile(file);
    for (final klass in snapshot.classes) {
      // Ensure field indices are unique, densely numbered from 0.
      final fields = klass.fields.toList()..sort((a, b) => a.index - b.index);
      for (int i = 0; i < fields.length; ++i) {
        Expect.equals(i, fields[i].index);
      }
    }
  });
}
