// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'dart:mirrors';

const _FailingTest failingTest = const _FailingTest();

class _FailingTest {
  const _FailingTest();
}

class MyTest {
  @failingTest
  void foo() {}
}

class MyTest2 extends Object with MyTest {}

main() {
  ClassMirror classMirror = reflectClass(MyTest2);
  classMirror.instanceMembers
      .forEach((Symbol symbol, MethodMirror memberMirror) {
    if (memberMirror.simpleName == #foo) {
      print(memberMirror);
      print(_hasFailingTestAnnotation(memberMirror));
    }
  });
}

bool _hasFailingTestAnnotation(MethodMirror method) {
  var r = _hasAnnotationInstance(method, failingTest);
  print('[_hasFailingTestAnnotation] $method $r');
  return r;
}

bool _hasAnnotationInstance(DeclarationMirror declaration, instance) =>
    declaration.metadata.any((InstanceMirror annotation) {
      print('annotation: ${annotation.reflectee}');
      return identical(annotation.reflectee, instance);
    });
