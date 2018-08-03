// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for type literals as compile-time constants.

class C<T> {
  void m() {
    const List lst = const [
      T //# 01: compile-time error
    ];
  }
}

main() {
  new C().m();
}
