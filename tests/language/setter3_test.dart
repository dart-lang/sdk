// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that setters cannot have defined, non-void return types.
// Note: The language specification specifies the absence of a type means
// it is dynamic, however you cannot specify dynamic.

class A {
  set foo(x) {}
  void set bar(x) {}
  dynamic set baz(x) {} //# 01: static type warning
  bool set bob(x) {} //# 02: static type warning
}

main() {
  new A();
}
