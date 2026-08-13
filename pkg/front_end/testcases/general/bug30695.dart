// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  var foo = 42;
}

class B extends A {
  // Note: illegal override.
  foo() => 42;
}

main() {}
