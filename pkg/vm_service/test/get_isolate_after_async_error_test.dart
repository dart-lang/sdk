// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

Future<Never> doThrow() async {
  throw 'oh no';
}

final tests = <IsolateTest>[
  hasStoppedAtExit,
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id!);
    expect(isolate.error, isNotNull);
    expect(isolate.error!.message!.contains('oh no'), true);
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_isolate_after_async_error_test.dart',
      pause_on_exit: true,
      testeeConcurrent: doThrow,
    );
