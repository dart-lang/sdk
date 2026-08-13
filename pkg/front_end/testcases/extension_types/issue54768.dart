// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET(Object? _) {
  String call() => "ET";
}

Function func(Function callable) => callable;

void main() {
  ET et = ET(null);
  Expect.isTrue(func(et) is Function);
  Expect.isTrue(et.call is Function);
  Expect.equals(func(et)(), et.call());
  Expect.equals(func(et)(), "ET");
}

class Expect {
  static void equals(x, y) {
    if (x != y) {
      throw "Expected two equal values, got '$x' and '$y'.";
    }
  }

  static void isTrue(bool b) {
    if (!b) {
      throw "Expected condition to be true, but got false.";
    }
  }
}
