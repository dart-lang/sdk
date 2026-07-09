// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';

Future<void> _testEvaluateInFrameWithScope(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  // [isolate.rootLib] refers to the test entrypoint library, which is a
  // library that imports this file's library. We want a [Library] object that
  // refers to this file's library itself.
  final libId = isolate.libraries!
      .singleWhere(
        (l) => l.uri!.endsWith('evaluate_in_frame_with_scope_lib.dart'),
      )
      .id!;
  final Library lib = (await service.getObject(isolateId, libId)) as Library;

  Future<Field> findField(String name) async {
    final fieldRef = lib.variables!.singleWhere(
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

  final thing3Field = await findField('thing3');
  final thing3 = thing3Field.staticValue! as InstanceRef;
  print(thing3);

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

  // Scope provided shadows the local.
  await evaluateInFrameAndExpect(
    service,
    isolateId,
    'local',
    'hello',
    scope: {
      'local': thing3.id!,
    },
  );

  // Scope provided shadows the local: The shadowed variable has type 'int',
  // but the real variable has type 'Cow' (an extension type with a 'say'
  // method). As the type is now 'int' there should be no 'say' method.
  final result = await service.evaluateInFrame(
    isolateId,
    0,
    'local2.say()',
    scope: {
      'local2': thing2.id!,
    },
  );
  if (result is! ErrorRef) {
    if (result is InstanceRef) {
      fail('Expected an error because of the provided scope '
          'but got instance result "${result.valueAsString}".');
    }
    fail('Expected an error because of the provided scope '
        'but got ${result.runtimeType}.');
  }

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
    await service.evaluate(
      isolateId,
      libId,
      'x + y',
      scope: {
        'x': libId,
        'y': libId,
      },
    );
    fail('Evaluated against a VM-internal object');
  } on RPCError catch (e) {
    expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
    expect(
      e.details,
      contains('Cannot evaluate against a VM-internal object'),
    );
  }

  try {
    await service.evaluate(
      isolateId,
      libId,
      'x + y',
      scope: {
        'not&an&identifier': thing1.id!,
      },
    );
    fail('Evaluated with an invalid identifier');
  } on RPCError catch (e) {
    expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
    expect(
      e.details,
      contains("invalid 'scope' parameter"),
    );
  }
}

IsolateTestHarness createHarness(List<String> args) =>
    IsolateTestHarness('evaluate_in_frame_with_scope_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(_testEvaluateInFrameWithScope);
