// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var fisk;
  A() {
    // dart2js's inferrer used to not recognize the following call to
    // be on [this].
    fisk--;
    fisk = 42;
  }
}

abstract class B {
  var a;
  B() {
    hest = 54;
    a = 42;
  }
  set hest(value);
}

class C extends B {
  set hest(value) {
    return a + 42;
  }
}

main() {
  Expect.throwsNoSuchMethodError(() => new A());
  Expect.throwsNoSuchMethodError(() => new C());
}
