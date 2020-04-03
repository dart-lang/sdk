// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

libraryFunction() => "foobar1";

class Klass {
  static classFunction(x) => "foobar2" + x;
  instanceFunction(x, y) => "foobar3" + x + y;
}

var instance;

var apple;
var banana;

void testFunction() {
  instance = Klass();
  apple = "apple";
  banana = "banana";
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolate = await service.getIsolate(isolateRef.id);
    final Library lib = await service.getObject(isolate.id, isolate.rootLib.id);
    final cls = lib.classes.singleWhere((cls) => cls.name == "Klass");
    FieldRef fieldRef =
        lib.variables.singleWhere((field) => field.name == "instance");
    Field field = await service.getObject(isolate.id, fieldRef.id);
    final instance = await service.getObject(isolate.id, field.staticValue.id);

    fieldRef = lib.variables.singleWhere((field) => field.name == "apple");
    field = await service.getObject(isolate.id, fieldRef.id);
    final apple = await service.getObject(isolate.id, field.staticValue.id);
    fieldRef = lib.variables.singleWhere((field) => field.name == "banana");
    field = await service.getObject(isolate.id, fieldRef.id);
    Instance banana = await service.getObject(isolate.id, field.staticValue.id);

    dynamic result =
        await service.invoke(isolate.id, lib.id, 'libraryFunction', []);
    expect(result.valueAsString, equals('foobar1'));

    result =
        await service.invoke(isolate.id, cls.id, "classFunction", [apple.id]);
    expect(result.valueAsString, equals('foobar2apple'));

    result = await service.invoke(
        isolate.id, instance.id, "instanceFunction", [apple.id, banana.id]);
    expect(result.valueAsString, equals('foobar3applebanana'));

    // Wrong arity.
    await expectError(() => service
        .invoke(isolate.id, instance.id, "instanceFunction", [apple.id]));
    // No such target.
    await expectError(() => service
        .invoke(isolate.id, instance.id, "functionDoesNotExist", [apple.id]));
  },
  resumeIsolate,
];

expectError(func) async {
  dynamic result = await func();
  expect(result.type == 'Error' || result.type == '@Error', isTrue);
}

main([args = const <String>[]]) =>
    runIsolateTests(args, tests, testeeConcurrent: testFunction);
