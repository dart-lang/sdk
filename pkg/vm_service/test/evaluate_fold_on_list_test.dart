// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testFunction() {
  List<String> x = ["a", "b", "c"];
  int xCombinedLength = x.fold<int>(
      0, (previousValue, element) => previousValue + element.length);
  debugger();
  print("xCombinedLength = $xCombinedLength");
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final result = await service.evaluateInFrame(
      isolateRef.id!,
      0,
      '''
      x.fold<int>(
        0,
        (previousValue, element) => previousValue + element.length
      )
      ''',
    ) as InstanceRef;
    expect(result.valueAsString, equals('3'));
    expect(result.kind, equals(InstanceKind.kInt));
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_fold_on_list_test.dart',
      testeeConcurrent: testFunction,
    );
