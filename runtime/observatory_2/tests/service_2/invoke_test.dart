// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

libraryFunction() => "foobar1";

class Klass {
  @pragma('vm:entry-point')
  static classFunction(x) => "foobar2" + x;
  @pragma('vm:entry-point')
  instanceFunction(x, y) => "foobar3" + x + y;
}

var instance;

@pragma('vm:entry-point')
var apple;
@pragma('vm:entry-point')
var banana;

void testFunction() {
  instance = new Klass();
  apple = "apple";
  banana = "banana";
  debugger();
}

@pragma('vm:entry-point')
void foo() {
  print('foobar');
}

@pragma('vm:entry-point')
void invokeFunction(Function func) {
  func();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    Library lib = isolate.rootLibrary;
    await lib.load();
    final fooFunc = lib.functions.singleWhere((func) => func.name == "foo");
    Class cls = lib.classes.singleWhere((cls) => cls.name == "Klass");
    Field field =
        lib.variables.singleWhere((field) => field.name == "instance");
    await field.load();
    Instance instance = field.staticValue;
    field = lib.variables.singleWhere((field) => field.name == "apple");
    await field.load();
    Instance apple = field.staticValue;
    field = lib.variables.singleWhere((field) => field.name == "banana");
    await field.load();
    Instance banana = field.staticValue;

    dynamic result = await isolate.invokeRpc("invoke",
        {"targetId": lib.id, "selector": "libraryFunction", "argumentIds": []});
    print(result);
    expect(result.valueAsString, equals('foobar1'));

    result = await isolate.invokeRpc("invoke", {
      "targetId": cls.id,
      "selector": "classFunction",
      "argumentIds": [apple.id]
    });
    print(result);
    expect(result.valueAsString, equals('foobar2apple'));

    result = await isolate.invokeRpc("invoke", {
      "targetId": instance.id,
      "selector": "instanceFunction",
      "argumentIds": [apple.id, banana.id]
    });
    print(result);
    expect(result.valueAsString, equals('foobar3applebanana'));

    // Wrong arity.
    await expectError(
        () => isolate.invokeRpc("invoke", {
              "targetId": instance.id,
              "selector": "instanceFunction",
              "argumentIds": [apple.id]
            }),
        ServerRpcException.kExpressionCompilationError);

    // Non-instance argument.
    await expectError(
        () => isolate.invokeRpc("invoke", {
              "targetId": lib.id,
              "selector": "invokeFunction",
              "argumentIds": [fooFunc.id]
            }),
        ServerRpcException.kInvalidParams);

    // No such target.
    await expectError(
        () => isolate.invokeRpc("invoke", {
              "targetId": instance.id,
              "selector": "functionDoesNotExist",
              "argumentIds": [apple.id]
            }),
        ServerRpcException.kExpressionCompilationError);
  },
  resumeIsolate,
];

expectError(func, code) async {
  bool gotException = false;
  dynamic result;
  try {
    result = await func();
    expect(result.type, equals('Error')); // dart1 semantics
  } on ServerRpcException catch (e) {
    expect(e.code, code);
    gotException = true;
  }
  if (result?.type != 'Error') {
    expect(gotException, true); // dart2 semantics
  }
}

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
