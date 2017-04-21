// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  m() {
    print("Called m");
  }

  testC() {
    m();
  }
}

class D extends C {
  testD() {
    m();
  }
}

main() {
  new C().testC();
  new D().testD();
}
