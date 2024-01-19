// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check the VM correctly undoes the layers of mixin application to report the
// evaluation scope the frontend as the original mixin.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

class S {}

mixin class M {
  static String? foo;
  void bar() {
    foo = 'theExpectedValue';
  }
}

// MA -> S&M -> S -> Object
class MA extends S with M {}

late final MA global;
void testeeMain() {
  global = MA()..bar();
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.rootLib!.id!,
    ) as Library;
    final fieldRef = rootLib.variables!.singleWhere((v) => v.name == 'global');
    final field = await service.getObject(isolateId, fieldRef.id!) as Field;
    final instance = field.staticValue! as InstanceRef;
    try {
      await service.evaluate(
        isolateId,
        instance.id!,
        'foo',
      );
    } on RPCError catch (e) {
      expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
      expect(
        e.details,
        contains("The getter 'foo' isn't defined for the class 'MA'"),
      );
    }
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_on_mixin_application_test.dart',
      testeeConcurrent: testeeMain,
    );
