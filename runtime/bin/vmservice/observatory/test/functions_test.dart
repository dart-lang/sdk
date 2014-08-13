// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library functions_test;

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

class Foo {
  int a;
}

void script() {
  new Foo().a = 42;
}

var tests = [

(Isolate isolate) =>
  isolate.rootLib.load().then((Library lib) {
    expect(lib.classes.length, equals(1));
    return lib.classes.first.load().then((Class fooClass) {
      expect(fooClass.name, equals('Foo'));
      return fooClass.get('functions/get%3Aa').then((ServiceFunction func) {
        expect(func.name, equals('a'));
        expect(func.kind, equals(FunctionKind.kImplicitGetterFunction));
      });
    });
}),

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
