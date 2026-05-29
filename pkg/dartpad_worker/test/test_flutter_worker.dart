// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate' show Isolate;

import 'package:test/test.dart';

import 'flutter/all_worker_tests.dart';

import 'in_process_worker.dart';
import 'worker_harness.dart';

void main() {
  createWorker = createInprocessWorker;
  for (final (file, m) in testFiles) {
    group(file, m);
  }

  // Simple test that ensures we've included all the worker tests here.
  test('test_worker.dart includes all worker/ files', () async {
    final libUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:dartpad_worker/'),
    );
    if (libUri == null) {
      fail('Cannot resolve package:dartpad_worker/');
    }

    final files = ['flutter']
        .map((d) => libUri.resolve('../test/$d/worker/'))
        .expand((u) => Directory.fromUri(u).listSync())
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.uri.pathSegments.takeLast(3).join('/'))
        .toSet();

    check(testFiles.map((e) => e.$1).toSet()).unorderedEquals(files);
  }, testOn: 'vm');
}

extension<T> on List<T> {
  Iterable<T> takeLast(int count) => reversed.take(count).toList().reversed;
}
