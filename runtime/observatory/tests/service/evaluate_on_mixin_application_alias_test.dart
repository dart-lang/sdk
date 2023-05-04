// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check the VM correctly undoes the layers of mixin application to report the
// evaluation scope the frontend as the original mixin.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

class S {}

class M {
  static String? foo;
  bar() {
    foo = "theExpectedValue";
  }
}

// MA=S&M -> S -> Object
class MA = S with M;

var global;
testeeMain() {
  global = new MA()..bar();
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load() as Library;
    Field field = await lib.variables
        .singleWhere((v) => v.name == "global")
        .load() as Field;
    dynamic instance = field.staticValue!;
    print(instance);

    dynamic result = await instance.evaluate("foo");
    print(result);
    expect(result.valueAsString, equals("theExpectedValue"));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testeeMain);
