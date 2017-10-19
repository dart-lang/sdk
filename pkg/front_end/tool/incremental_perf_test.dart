// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test to ensure that incremental_perf.dart is running without errors.

import 'dart:async';
import 'dart:io';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'incremental_perf.dart' as m;

main() async {
  var sdkOutline = computePlatformBinariesLocation().resolve(
      // TODO(sigmund): switch to `vm_outline.dill` (issue #29881).
      "vm_platform.dill");

  final ikgBenchmarks = Platform.script.resolve('../benchmarks/ikg/');
  await runExample(sdkOutline, ikgBenchmarks.resolve('hello.dart'),
      ikgBenchmarks.resolve('hello.edits.json'));
  await runExample(sdkOutline, ikgBenchmarks.resolve('dart2js.dart'),
      ikgBenchmarks.resolve('dart2js.edits.json'));
}

Future runExample(Uri sdkOutline, Uri entryUri, Uri jsonUri) async {
  await m.main(['--sdk-summary', '$sdkOutline', '$entryUri', '$jsonUri']);
}
