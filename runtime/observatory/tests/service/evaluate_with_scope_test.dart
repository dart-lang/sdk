// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
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
}

var tests = [
  (Isolate isolate) async {
    var lib = await isolate.rootLibrary.load();
    var thing1 =
        (await lib.variables.singleWhere((v) => v.name == "thing1").load())
            .staticValue;
    print(thing1);
    var thing2 =
        (await lib.variables.singleWhere((v) => v.name == "thing2").load())
            .staticValue;
    print(thing2);

    var result = await lib.evaluate("x + y", scope: {"x": thing1, "y": thing2});
    expect(result.valueAsString, equals('7'));

    bool didThrow = false;
    try {
      result = await lib.evaluate("x + y", scope: {"x": lib, "y": lib});
      print(result);
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

main(args) => runIsolateTests(args, tests, testeeBefore: testeeMain);
