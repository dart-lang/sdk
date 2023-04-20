// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:analysis_server/src/utilities/profiling.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessProfiler', () {
    test('getProfilerForPlatform', () async {
      expect(ProcessProfiler.getProfilerForPlatform(), isNotNull);
    });

    test('getProcessUsage', () async {
      var profiler = ProcessProfiler.getProfilerForPlatform()!;
      var info = (await profiler.getProcessUsage(pid))!;

      if (Platform.isWindows) {
        expect(info.cpuPercentage, isNull);
      } else {
        expect(info.cpuPercentage, greaterThanOrEqualTo(0.0));
      }
      expect(info.memoryKB, greaterThanOrEqualTo(0));

      // Use ~50 MB more memory and ensure that we actually use more memory
      // as reported by the return value.
      Uint8List use50mb = Uint8List(50 * 1024 * 1024);
      for (int i = 0; i < use50mb.length; i++) {
        use50mb[i] = i % 200;
      }
      var info2 = (await profiler.getProcessUsage(pid))!;

      for (var b in use50mb) {
        if (b < 0) throw "This shouldn't happen, but we're using the data!";
      }
      expect(info2.memoryKB, greaterThan(info.memoryKB));
    });
  });
}
