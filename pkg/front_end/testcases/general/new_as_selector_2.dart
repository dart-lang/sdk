// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.14

class C {
  int new = 42; // error

  method()  {
    this.new(); // error
  }
}

extension E1 on int {
  external int new; // error

  call<T>() {}
}

extension E2 on int {
  external int new; // error

  call<T>() {}
}
