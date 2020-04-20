// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/utilities/profiling.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessProfiler', () {
    // Skip on windows.
    if (Platform.isWindows) {
      return;
    }

    test('getProfilerForPlatform', () async {
      expect(ProcessProfiler.getProfilerForPlatform(), isNotNull);
    });

    test('getProcessUsage', () async {
      var profiler = ProcessProfiler.getProfilerForPlatform();
      var info = await profiler.getProcessUsage(pid);

      expect(info, isNotNull);
      expect(info.cpuPercentage, greaterThanOrEqualTo(0.0));
      expect(info.memoryKB, greaterThanOrEqualTo(0));
    });
  });
}
