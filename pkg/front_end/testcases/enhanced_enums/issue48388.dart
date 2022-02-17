// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M1 on Enum {
  final int values = 42; // Error.
}

mixin M2 on Enum {
  static final int values = 42; // Ok.
}

mixin M3 on Enum {
  void set values(String x) {} // Error.
}

mixin M4 on Enum {
  static void set values(String x) {} // Ok.
}

mixin M5 on Enum {
  num get values => 0; // Error.
  void set values(num x) {} // Error.
}

abstract class E1 extends Enum {
  int values() => 42; // Error.
}

abstract class E2 extends Enum {
  static int values() => 42; // Ok.
}

abstract class E3 extends Enum {
  void set values(num x) {} // Error.
}

abstract class E4 extends Enum {
  static void set values(num x) {} // Ok.
}

abstract class E5 extends Enum {
  num get values => 0; // Error.
  void set values(num x) {} // Error.
}

main() {}
