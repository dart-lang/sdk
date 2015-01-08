// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library allocations_test;

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

class Foo {
}
List<Foo> foos;

void script() {
  foos = [new Foo(), new Foo(), new Foo()];
}

var tests = [

(Isolate isolate) =>
  isolate.rootLib.load().then((Library lib) {
    expect(lib.url.endsWith('allocations_test.dart'), isTrue);
    expect(lib.classes.length, equals(1));
    return lib.classes.first.load().then((Class fooClass) {
      expect(fooClass.name, equals('Foo'));
      expect(fooClass.newSpace.accumulated.instances +
             fooClass.oldSpace.accumulated.instances, equals(3));
    });
}),

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
