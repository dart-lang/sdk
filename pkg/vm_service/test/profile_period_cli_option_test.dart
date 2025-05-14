// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

void testeeMain() {
  final stopwatch = Stopwatch();
  stopwatch.start();
  while (stopwatch.elapsedMilliseconds < 5000) {}
  stopwatch.stop();
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final cpuSamples = await service.getCpuSamples(isolateRef.id!, -1, -1);
    // The default profile period is 1ms, and the testee runs for at least 5000
    // ms. So, we confirm that increasing the profile period using the CLI
    // option worked by confirming that we received significantly fewer than
    // 5000 samples.
    expect(cpuSamples.sampleCount, lessThan(3000));
  }
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'eval_with_resident_compiler_test.dart',
      testeeBefore: testeeMain,
      pauseOnExit: true,
      extraArgs: ['--profile-period=10000'],
    );
