// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a non-assignable index, or a non-assignable value assigned through
// `operator []=`, is reported as an argument error in all forms of index
// expression. See https://github.com/dart-lang/sdk/issues/64561.

class C {
  int operator [](int i) => 0;
  void operator []=(int i, int v) {}
}

class X {}

extension E on X {
  int operator [](int i) => 0;
  void operator []=(int i, int v) {}
}

class D extends C {
  void reads(num n, C c, C? nc, X s) {
    super[n]; // Error.
    c[n]; // Error.
    nc?[n]; // Error.
    s[n]; // Error.
    E(s)[n]; // Error.
  }

  void plainAssignmentIndex(num n, C c, C? nc, X s) {
    super[n] = 0; // Error.
    c[n] = 0; // Error.
    nc?[n] = 0; // Error.
    c..[n] = 0; // Error.
    s[n] = 0; // Error.
    E(s)[n] = 0; // Error.
  }

  void plainAssignmentValue(num n, C c, C? nc, X s) {
    super[0] = n; // Error.
    c[0] = n; // Error.
    nc?[0] = n; // Error.
    c..[0] = n; // Error.
    s[0] = n; // Error.
    E(s)[0] = n; // Error.
  }

  void valueContext(num n, C c, X s) {
    var x1 = super[0] = n; // Error.
    var x2 = c[0] = n; // Error.
    var x3 = E(s)[0] = n; // Error.
  }

  void compound(num n, double d, C c, X s) {
    super[n] += 0; // Error.
    c[n] += 0; // Error.
    E(s)[n] += 0; // Error.
    super[0] += d; // Error.
    c[0] += d; // Error.
    E(s)[0] += d; // Error.
    super[n]++; // Error.
    c[n]++; // Error.
    E(s)[n]++; // Error.
  }

  void ifNull(num n, C c, X s) {
    super[n] ??= 0; // Error.
    c[n] ??= 0; // Error.
    E(s)[n] ??= 0; // Error.
    super[0] ??= n; // Error.
    c[0] ??= n; // Error.
    E(s)[0] ??= n; // Error.
  }
}

main() {}
