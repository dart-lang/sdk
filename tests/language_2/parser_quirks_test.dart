// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a Dart implementation doesn't turn dynamic errors into
// compilation errors.

f(x) {}

class MyClass {
  MyClass(x, y);

  foo() {
    var z;
    // Neither y nor x are defined. So they are simply dynamic
    // (getter) sends to this, not compile-time errors.
    if (false) f(new MyClass(z, y[x.y.z]));
    if (false) print(y[x.y.z]);
  }
}

main() {
  var x;
  // We know the concrete type of f (a function closure) does not
  // support the index operator. However, this is a dynamic error, so
  // this program should compile.
  if (false) print(f[x.y.z]);
  new MyClass(0, 0).foo();
}
