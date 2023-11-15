// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--deterministic --optimization-counter-threshold=1000

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class X {
  late String _y;

  @pragma('vm:never-inline')
  String get y => _y;
}

Future<void> testeeMain() async {
  final x = X();
  x._y = '';
  for (int i = 0; i < 2000; i++) {
    x.y;
  }

  X().y;
}

final tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'pause_on_exception_from_slow_path_test.dart',
      pauseOnUnhandledExceptions: true,
      testeeConcurrent: testeeMain,
      extraArgs: extraDebuggingArgs,
    );
