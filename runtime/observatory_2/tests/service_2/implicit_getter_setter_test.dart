// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library implicit_getter_setter_test;

import 'dart:async';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

class A {
  double field = 0.0;
}

script() {
  for (int i = 0; i < 10; i++) {
    new A();
  }
}

Future testGetter(Isolate isolate) async {
  Library rootLibrary = await isolate.rootLibrary.load();
  expect(rootLibrary.classes.length, equals(1));
  Class classA = await rootLibrary.classes[0].load();
  expect(classA.name, equals('A'));
  // Find getter.
  ServiceFunction getterFunc;
  for (ServiceFunction function in classA.functions) {
    if (function.name == 'field') {
      getterFunc = function;
      break;
    }
  }
  expect(getterFunc, isNotNull);
  await getterFunc.load();
  Field field = await getterFunc.field.load();
  expect(field, isNotNull);
  expect(field.name, equals('field'));
  Class classDouble = await field.guardClass.load();
  expect(classDouble.name, equals('_Double'));
}

Future testSetter(Isolate isolate) async {
  Library rootLibrary = await isolate.rootLibrary.load();
  expect(rootLibrary.classes.length, equals(1));
  Class classA = await rootLibrary.classes[0].load();
  expect(classA.name, equals('A'));
  // Find setter.
  ServiceFunction setterFunc;
  for (ServiceFunction function in classA.functions) {
    if (function.name == 'field=') {
      setterFunc = function;
      break;
    }
  }
  expect(setterFunc, isNotNull);
  await setterFunc.load();
  Field field = await setterFunc.field.load();
  expect(field, isNotNull);
  expect(field.name, equals('field'));
  Class classDouble = await field.guardClass.load();
  expect(classDouble.name, equals('_Double'));
}

var tests = <IsolateTest>[testGetter, testSetter];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
