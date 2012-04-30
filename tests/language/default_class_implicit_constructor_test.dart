// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An interface with a default class with no declared constructor should 
// use the implicit default constructor

interface A default B {
  A();
}

class B implements A {
}

main() {
  var val = new A();
  Expect.equals(true, val is A);
  Expect.equals(true, val is B);
}
