// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  A([a]) {
    () => 42;
    if (a != null) throw 'Test failed';
  }
}

class B extends A {
  B();
}

main() {
  new B();
}
