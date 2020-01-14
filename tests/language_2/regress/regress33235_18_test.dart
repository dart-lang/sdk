// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for complience with tables at
// https://github.com/dart-lang/sdk/issues/33235#issue-326617285
// Files 01 to 16 should be compile time errors, files 17 to 21 should not.

class A {
  void set n(int i) {}
}

class B extends A {
  int get n {
    return 42;
  }
}

abstract class B2 implements A {
  int get n {
    return 42;
  }
}

class C {
  int get n {
    return 42;
  }

  void set n(int i) {}
}

main() {
  print(C);
  print(B);
  print(B2);
}
