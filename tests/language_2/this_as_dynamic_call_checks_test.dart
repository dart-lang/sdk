// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--no-background-compilation --enable-inlining-annotations --optimization-counter-threshold=10

import "package:expect/expect.dart";

const NeverInline = "NeverInline";

class A<T> {
  @NeverInline
  void doSet(T x) {}

  void doIt({bool violateType: false}) {
    dynamic x = this;
    x.doSet(violateType ? 10 : "10");
  }
}

@NeverInline
void loop(A<String> obj, {bool violateType: false}) {
  for (var i = 0; i < 100; i++) obj.doIt(violateType: violateType);
}

void main() {
  final obj = A<String>();
  loop(obj, violateType: false);
  loop(obj, violateType: false);
  Expect.throwsTypeError(() => loop(obj, violateType: true));
}
