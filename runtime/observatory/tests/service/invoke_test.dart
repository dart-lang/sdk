// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

libraryFunction() => "foobar1";

class Klass {
  static classFunction(x) => "foobar2" + x;
  instanceFunction(x, y) => "foobar3" + x + y;
}

var instance;

var apple;
var banana;

void testFunction() {
  instance = new Klass();
  apple = "apple";
  banana = "banana";
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    Library lib = isolate.rootLibrary;
    await lib.load();
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
    await expectError(() => isolate.invokeRpc("invoke", {
          "targetId": instance.id,
          "selector": "instanceFunction",
          "argumentIds": [apple.id]
        }));

    // No such target.
    await expectError(() => isolate.invokeRpc("invoke", {
          "targetId": instance.id,
          "selector": "functionDoesNotExist",
          "argumentIds": [apple.id]
        }));
  },
  resumeIsolate,
];

expectError(func) async {
  bool gotException = false;
  dynamic result;
  try {
    result = await func();
    expect(result.type, equals('Error')); // dart1 semantics
  } on ServerRpcException catch (e) {
    expect(e.code, equals(ServerRpcException.kExpressionCompilationError));
    gotException = true;
  }
  if (result?.type != 'Error') {
    expect(gotException, true); // dart2 semantics
  }
}

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
