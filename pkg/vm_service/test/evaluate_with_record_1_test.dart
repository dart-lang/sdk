// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testFunction() {
  final listOfRecord = [(42, foo: 42.42, bar: 'fortytwo')];
  debugger();
  print(helper(listOfRecord));
}

bool helper(List<(int, {double foo, String bar})> listOfRecord) {
  final record = listOfRecord.first;
  return record.$1 == 42 && record.foo >= 42.0 && record.bar.length >= 4;
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final result = await service.evaluateInFrame(
      isolateRef.id!,
      0,
      'helper(listOfRecord)',
    ) as InstanceRef;
    expect(result.valueAsString, equals('true'));
    expect(result.kind, equals(InstanceKind.kBool));
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_with_record_1_test.dart',
      testeeConcurrent: testFunction,
    );
