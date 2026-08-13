// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that parameter type checks are not omitted because
// of the incorrect static type due to a removed cast.
//
// Regression test for the 2nd part of
// https://github.com/dart-lang/sdk/issues/53945.

import "package:expect/expect.dart";

class A<T> {
  void foo(List<T> arg) {}
}

class B extends A<double> {
  void foo(List<double> arg) {}
}

void main() {
  List<num> ints = <int>[42];
  B obj = B();
  // Type cast 'obj as A<num>' is redundant, but removing it would
  // incorrectly alter static type of the receiver.
  Expect.throws<TypeError>(() => (obj as A<num>).foo(ints));
}
