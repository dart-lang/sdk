// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

void testMain() {
  print('1');
  while (true) {}
}

final tests = <IsolateTest>[
  // Kill the app.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await service.kill(isolateId);
  }
];

void main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'kill_running_test.dart',
      testeeConcurrent: testMain,
    );
