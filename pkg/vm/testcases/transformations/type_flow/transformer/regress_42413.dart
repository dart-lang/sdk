// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/42413.
// Verifies that TFA can infer types in a for-in loop.

class B {
  get x => 0;
}

class A {
  var list;
  A() {
    list = <B>[B()];
  }

  @pragma('vm:never-inline')
  void forIn() {
    for (var e in list) print(e.x);
  }

  @pragma('vm:never-inline')
  void cLoop() {
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      print(e.x);
    }
  }
}

void main() {
  A().forIn();
  A().cLoop();
}
