// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

var thing1;
var thing2;

testeeMain() {
  thing1 = 3;
  thing2 = 4;
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load();
    Field thing1Field =
        await lib.variables.singleWhere((v) => v.name == "thing1").load();
    var thing1 = thing1Field.staticValue;
    print(thing1);
    Field thing2Field =
        await lib.variables.singleWhere((v) => v.name == "thing2").load();
    var thing2 = thing2Field.staticValue;
    print(thing2);

    Instance result = await lib.evaluate("x + y",
        scope: <String, ServiceObject>{"x": thing1, "y": thing2});
    expect(result.valueAsString, equals('7'));

    bool didThrow = false;
    try {
      result = await lib.evaluate("x + y",
          scope: <String, ServiceObject>{"x": lib, "y": lib});
      print(result);
    } catch (e) {
      didThrow = true;
      expect(e.toString(),
          contains("Cannot evaluate against a VM-internal object"));
    }
    expect(didThrow, isTrue);

    didThrow = false;
    try {
      result = await lib.evaluate("x + y",
          scope: <String, ServiceObject>{"not&an&identifier": thing1});
      print(result);
    } catch (e) {
      didThrow = true;
      expect(e.toString(), contains("invalid 'scope' parameter"));
    }
    expect(didThrow, isTrue);
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: testeeMain);
