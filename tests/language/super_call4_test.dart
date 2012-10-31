// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that noSuchMethod is resolved in the super class and not in the
// current class.

class C {
  bool noSuchMethod(InvocationMirror im) {
    return true;
  }
}

class D extends C {
  bool noSuchMethod(InvocationMirror im) {
    return false;
  }
  test() {
    return super.foo();
  }
}

main() {
  var d = new D();
  Expect.isTrue(d.test());
}
