// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 26;

var thing1;
var thing2;

testeeMain() {
  thing1 = 3;
  thing2 = 4;
  foo(42, 1984);
}

foo(x, y) {
  var local = x + y;
  debugger();
  return local;
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;
    final rootLib = await service.getObject(
      isolateId,
      rootLibId,
    ) as Library;

    Future<Field> findField(String name) async {
      final fieldRef = await rootLib.variables!.singleWhere(
        (v) => v.name == name,
      );
      return await service.getObject(isolateId, fieldRef.id!) as Field;
    }

    final thing1Field = await findField('thing1');
    final thing1 = thing1Field.staticValue! as InstanceRef;
    print(thing1);

    final thing2Field = await findField('thing2');
    final thing2 = thing2Field.staticValue! as InstanceRef;
    print(thing2);

    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'x + y + a + b',
      '2033',
      scope: {
        'a': thing1.id!,
        'b': thing2.id!,
      },
    );

    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'local + a + b',
      '2033',
      scope: {
        'a': thing1.id!,
        'b': thing2.id!,
      },
    );

    await evaluateInFrameAndExpect(
      service,
      isolateId,
      'x + y',
      '7',
      scope: {
        'x': thing1.id!,
        'y': thing2.id!,
      },
    );

    try {
      await service.evaluate(isolateId, rootLibId, 'x + y', scope: {
        'x': rootLibId,
        'y': rootLibId,
      });
      fail('Evaluated against a VM-internal object');
    } on RPCError catch (e) {
      expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
      expect(
        e.details,
        contains('Cannot evaluate against a VM-internal object'),
      );
    }

    try {
      await service.evaluate(isolateId, rootLibId, 'x + y', scope: {
        'not&an&identifier': thing1.id!,
      });
      fail('Evaluated with an invalid identifier');
    } on RPCError catch (e) {
      expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
      expect(
        e.details,
        contains('invalid \'scope\' parameter'),
      );
    }
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_in_frame_with_scope_test.dart',
      testeeConcurrent: testeeMain,
    );
