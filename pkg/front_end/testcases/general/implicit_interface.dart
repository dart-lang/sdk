// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from co19/Language/Classes/Superinterfaces/implicit_interface_t02

abstract class I {
  foo(var x);
}

class S {
  foo() {}
}

class C extends S implements I {}

test() {
  new C();
}

main() {}
