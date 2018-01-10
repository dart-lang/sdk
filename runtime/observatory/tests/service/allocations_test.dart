// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

library allocations_test;

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

class Foo {}

List<Foo> foos;

void script() {
  foos = [new Foo(), new Foo(), new Foo()];
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load();
    expect(lib.uri.endsWith('allocations_test.dart'), isTrue);
    expect(lib.classes.length, equals(1));
    Class fooClass = await lib.classes.first.load();
    expect(fooClass.name, equals('Foo'));
    expect(
        fooClass.newSpace.current.instances +
            fooClass.oldSpace.current.instances,
        equals(3));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
