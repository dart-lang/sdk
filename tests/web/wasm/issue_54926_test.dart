// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Instantiation closure equality check used to generate virtual call to
// `Object.==` when comparing captured types.
//
// When the program is small, `Object.==` is sometimes not added to the
// dispatch table, which causes a crash.
//
// To avoid making the program larger (which can make `Object.==` available for
// virtual calls and hide the bug), this does not use the `expect` library.

class C {
  void f<T>(T t) {
    print(t);
  }
}

void main() {
  var f = C().f;
  var f1 = f<int>;
  var f2 = f<int>;

  if (identical(f1, f2) || f1 != f2) {
    throw '';
  }
}
