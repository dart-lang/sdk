// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "issue41498_lib.dart";

class C {
  static void test() {
    LegacyFoo f;

    f.toString(); // error
  }

  void test2() {
    LegacyFoo f;

    f.toString(); // error
  }
}

test() {
  LegacyFoo f;

  f.toString(); // error

  Function foo = () {
    LegacyFoo f;

    f.toString(); // error
  };
  C.test();
  new C().test2();
}

main() {}
