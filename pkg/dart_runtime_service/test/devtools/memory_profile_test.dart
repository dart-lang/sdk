// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service_io.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('memory_profile_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('MemoryJsonFile is a valid memory profile after every sample', () {
    final profileFile = File(path.join(tempDir.path, 'memory_samples.json'))
      ..writeAsStringSync('stale contents from a previous run');
    final memoryJsonFile = MemoryJsonFile.create(profileFile.path);
    addTearDown(memoryJsonFile.close);

    // `dart devtools --record-memory-profile` is killed rather than shut down,
    // so the file must be complete without calling close().
    final samples = <HeapSample>[];
    expect(
      profileFile.readAsStringSync(),
      SamplesMemoryJson.encodeList(samples),
    );
    for (final timestamp in [1000, 1500]) {
      final sample = HeapSample(
        timestamp,
        1,
        2,
        3,
        4,
        timestamp == 1500,
        null,
        null,
        null,
      );
      memoryJsonFile.writeSample(sample);
      samples.add(sample);
      expect(
        profileFile.readAsStringSync(),
        SamplesMemoryJson.encodeList(samples),
      );
    }
  });
}
