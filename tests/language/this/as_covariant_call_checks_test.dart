// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--no-background-compilation --optimization-counter-threshold=10

import "package:expect/expect.dart";

class A<T> {
  late T field;

  @pragma('vm:never-inline')
  set property(T v) {}

  @pragma('vm:never-inline')
  void method(T x) {}

  @pragma('vm:never-inline')
  void testMethod(bool violateType) {
    A<dynamic> x = this;
    x.method(violateType ? 10 : "10");
  }

  @pragma('vm:never-inline')
  void testSetter(bool violateType) {
    A<dynamic> x = this;
    x.property = violateType ? 10 : "10";
  }

  @pragma('vm:never-inline')
  void testField(bool violateType) {
    A<dynamic> x = this;
    x.field = violateType ? 10 : "10";
  }
}

@pragma('vm:never-inline')
void loop(A<String> obj, bool violateType) {
  for (var i = 0; i < 100; i++) {
    obj.testMethod(violateType);
    obj.testSetter(violateType);
    obj.testField(violateType);
  }
}

void main() {
  A<num>().field = 10;
  final obj = A<String>();
  loop(obj, false);
  loop(obj, false);
  Expect.throwsTypeError(() => obj.testMethod(true));
  Expect.throwsTypeError(() => obj.testSetter(true));
  Expect.throwsTypeError(() => obj.testField(true));
}
