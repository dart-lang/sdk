// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:heap_snapshot/analysis.dart';
import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart';

import 'use_flag_test_helper.dart';

void main() async {
  if (buildDir.contains('Product')) return;

  final dir = Directory('.');

  StreamSubscription? current;
  Future<void> iterate() async {
    final temp = dir.watch().listen((event) {});
    await current?.cancel();
    current = dir.watch().listen((event) {});
    await temp.cancel();
  }

  Future<void> finish() async {
    await current?.cancel();
  }

  await withTempDir('ama-test', (String tempDir) async {
    await iterate();

    final before = countInstances(tempDir, '_BroadcastSubscription');
    print('Before = $before');
    for (int i = 0; i < 100; i++) {
      await iterate();
    }
    final after = countInstances(tempDir, '_BroadcastSubscription');
    print('After = $after');

    await finish();

    Expect.equals(0, (after - before));
  });
}

int countInstances(String tempDir, String className) {
  final snapshotFile = path.join(tempDir, 'foo.heapsnapshot');
  NativeRuntime.writeHeapSnapshotToFile(snapshotFile);
  final bytes = File(snapshotFile).readAsBytesSync();
  File(snapshotFile).deleteSync();
  final graph = HeapSnapshotGraph.fromChunks(
      [bytes.buffer.asByteData(bytes.offsetInBytes, bytes.length)]);
  final analysis = Analysis(graph);
  return analysis
      .filterByClassPatterns(analysis.reachableObjects, [className]).length;
}
