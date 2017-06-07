// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/src/utilities/profiling.dart';
import 'package:test/test.dart';

main() {
  group('ProcessProfiler', () {
    // Skip on windows.
    if (Platform.isWindows) {
      return;
    }

    test('getProfilerForPlatform', () async {
      expect(ProcessProfiler.getProfilerForPlatform(), isNotNull);
    });

    // TODO: https://github.com/dart-lang/sdk/issues/29815
//    test('getProcessUsage', () async {
//      ProcessProfiler profiler = ProcessProfiler.getProfilerForPlatform();
//      UsageInfo info = await profiler.getProcessUsage(pid);
//
//      expect(info, isNotNull);
//      expect(info.cpuPercentage, greaterThanOrEqualTo(0.0));
//      expect(info.memoryKB, greaterThanOrEqualTo(0));
//    });
  });
}
