// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  foo() => _foo();
  _foo() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }

  static _staticFoo() {
    print("_staticFoo");
  }

  static staticFoo() => C._staticFoo();
}

extension ext on C {
  _bar() {
    try {
      throw "producing a stack trace";
    } catch (e, s) {
      print(s);
    }
  }
}
