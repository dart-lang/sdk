// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:developer';

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

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

var tests = [
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    expect(stack['frames'][0].function.name, equals('foo'));

    var lib = await isolate.rootLibrary.load();
    var thing1 =
        (await lib.variables.singleWhere((v) => v.name == "thing1").load())
            .staticValue;
    print(thing1);
    var thing2 =
        (await lib.variables.singleWhere((v) => v.name == "thing2").load())
            .staticValue;
    print(thing2);

    var result = await isolate
        .evalFrame(0, "x + y + a + b", scope: {"a": thing1, "b": thing2});
    print(result);
    expect(result.valueAsString, equals('2033'));

    result = await isolate
        .evalFrame(0, "local + a + b", scope: {"a": thing1, "b": thing2});
    print(result);
    expect(result.valueAsString, equals('2033'));

    // Note the eval's scope is shadowing the locals' scope.
    result =
        await isolate.evalFrame(0, "x + y", scope: {"x": thing1, "y": thing2});
    print(result);
    expect(result.valueAsString, equals('7'));

    bool didThrow = false;
    try {
      await lib.evaluate("x + y", scope: {"x": lib, "y": lib});
    } catch (e) {
      didThrow = true;
      expect(e.toString(),
          contains("Cannot evaluate against a VM-internal object"));
    }
    expect(didThrow, isTrue);

    didThrow = false;
    try {
      result =
          await lib.evaluate("x + y", scope: {"not&an&identifier": thing1});
      print(result);
    } catch (e) {
      didThrow = true;
      expect(e.toString(), contains("invalid 'scope' parameter"));
    }
    expect(didThrow, isTrue);
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testeeMain);
