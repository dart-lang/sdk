// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'profile_period_cli_option_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('profile_period_cli_option_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final cpuSamples = await service.getCpuSamples(isolateRef.id!, -1, -1);
      // The default profile period is 1ms, and the testee runs for at least 5000
      // ms. So, we confirm that increasing the profile period using the CLI
      // option worked by confirming that we received significantly fewer than
      // 5000 samples.
      expect(cpuSamples.sampleCount, lessThan(3000));
    }).run(
      testeeMain: testee_lib.main,
      pauseOnExit: true,
      extraArgs: ['--profile-period=10000'],
    );
