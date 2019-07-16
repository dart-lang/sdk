// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10

import "package:expect/expect.dart";

const NeverInline = "NeverInline";

class A<T> {
  T field;

  @NeverInline
  set property(T v) {}

  @NeverInline
  void method(T x) {}

  @NeverInline
  void testMethod({bool violateType: false}) {
    dynamic x = this;
    x.method(violateType ? 10 : "10");
  }

  @NeverInline
  void testSetter({bool violateType: false}) {
    dynamic x = this;
    x.property = violateType ? 10 : "10";
  }

  @NeverInline
  void testField({bool violateType: false}) {
    dynamic x = this;
    x.field = violateType ? 10 : "10";
  }
}

@NeverInline
void loop(A<String> obj, {bool violateType: false}) {
  for (var i = 0; i < 100; i++) {
    obj.testMethod(violateType: violateType);
    obj.testSetter(violateType: violateType);
    obj.testField(violateType: violateType);
  }
}

void main() {
  final obj = A<String>();
  loop(obj, violateType: false);
  loop(obj, violateType: false);
  Expect.throwsTypeError(() => obj.testMethod(violateType: true));
  Expect.throwsTypeError(() => obj.testSetter(violateType: true));
  Expect.throwsTypeError(() => obj.testField(violateType: true));
}
