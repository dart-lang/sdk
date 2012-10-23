// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing default factories defined across libraries

#library("test");
#import("default_factory_library.dart", prefix:"lib");

class B implements lib.A {
  int methodA() { return 1; }
  int methodB() { return 2; }
}

class C {
  // References an interface in another library
  factory lib.A () { return new B(); }
}

main() {
  var val = new lib.A();
  Expect.equals(true, (val is B));
  Expect.equals(1, val.methodA());
  Expect.equals(2, val.methodB());
}
