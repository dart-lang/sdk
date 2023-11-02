// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check the VM correctly undoes the layers of mixin application to report the
// evaluation scope the frontend as the original mixin.

import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class S {}

mixin class M {
  static String? foo;
  bar() {
    foo = "theExpectedValue";
  }
}

// MA=S&M -> S -> Object
class MA = S with M;

var global;
testeeMain() {
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
    await evaluateAndExpect(
      service,
      isolateId,
      instance.id!,
      'foo',
      'theExpectedValue',
    );
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'evaluate_on_mixin_application_alias_test.dart',
      testeeConcurrent: testeeMain,
    );
