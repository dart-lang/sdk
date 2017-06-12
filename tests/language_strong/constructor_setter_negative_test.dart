// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that setters are not invokable in the initializer list.

class A {
  A() : a = 499; // <==== Error here.

  set a(val) {}
}

main() {
  new A();
}
