// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  // Not a valid implementation.
  void extendedMethod1(int i) {}

  // Valid implementation.
  void extendedMethod2(num i) {}

  void overriddenMethod1(int i) {}
  void overriddenMethod2(num n) {}
}

class Class extends Super {
  // Valid override.
  void extendedMethod1(num n);

  // Not a valid override.
  void extendedMethod2(int i);

  // Valid override
  void overriddenMethod1(num n) {}

  // Not a valid override
  void overriddenMethod2(int n) {}
}

main() {}
