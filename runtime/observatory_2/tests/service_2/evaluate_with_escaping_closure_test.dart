// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

dynamic escapedClosure;

testeeMain() {}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load();

    Instance result = await lib.evaluate("escapedClosure = (x, y) => x + y");
    print(result);
    expect(result.clazz.name, startsWith('_Closure'));

    for (var i = 0; i < 100; i++) {
      result = await lib.evaluate("escapedClosure(3, 4)");
      print(result);
      expect(result.valueAsString, equals('7'));
    }
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: testeeMain);
