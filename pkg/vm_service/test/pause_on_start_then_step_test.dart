// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 21;

void testMain() {
  print('Hello');
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
];

void main([args = const <String>[]]) /* LINE_A */ => runIsolateTests(
      args,
      tests,
      'pause_on_start_then_step_test.dart',
      testeeConcurrent: testMain,
      pause_on_start: true,
      pause_on_exit: true,
      verbose_vm: true,
      extraArgs: ['--trace-service', '--trace-service-verbose'],
    );
