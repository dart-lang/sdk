// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test to ensure that incremental_perf.dart is running without errors.

import 'dart:io';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'incremental_perf.dart' as m show main;

main() async {
  var sdkOutline = computePlatformBinariesLocation(forceBuildDir: true).resolve(
      // TODO(sigmund): switch to `vm_outline.dill` (issue #29881).
      "vm_platform_strong.dill");

  final ikgBenchmarks = Platform.script.resolve('../benchmarks/ikg/');
  final helloEntry = ikgBenchmarks.resolve('hello.dart');
  final helloEdits = ikgBenchmarks.resolve('hello.edits.json');
  await m.main([
    '--no-loop',
    '--sdk-summary',
    '$sdkOutline',
    '$helloEntry',
    '$helloEdits'
  ]);
  await m.main([
    '--no-loop',
    '--sdk-summary',
    '$sdkOutline',
    '$helloEntry',
    '$helloEdits'
  ]);
  await m.main([
    '--no-loop',
    '--sdk-summary',
    '$sdkOutline',
    '--implementation=minimal',
    '$helloEntry',
    '$helloEdits'
  ]);

  final dart2jsEntry = ikgBenchmarks.resolve('dart2js.dart');
  final dart2jsEdits = ikgBenchmarks.resolve('dart2js.edits.json');
  await m.main([
    '--no-loop',
    '--sdk-summary',
    '$sdkOutline',
    '$dart2jsEntry',
    '$dart2jsEdits'
  ]);
  await m.main([
    '--no-loop',
    '--sdk-summary',
    '$sdkOutline',
    '--implementation=default',
    '$dart2jsEntry',
    '$dart2jsEdits'
  ]);
  await m.main([
    '--no-loop',
    '--sdk-summary',
    '$sdkOutline',
    '--implementation=minimal',
    '$dart2jsEntry',
    '$dart2jsEdits'
  ]);
}
