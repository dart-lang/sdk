// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  noSuchMethod() { //                                   //# 01: compile-time error
    throw new Exception( //                             //# 01: continued
        "Wrong noSuchMethod() should not be called"); //# 01: continued
  } //                                                  //# 01: continued
}

class C extends Object with A {
  test() {
    super.v = 1; //# 01: continued
  }
}

main() {
  C c = new C();
  Expect.throws(() => c.test(), (e) => e is NoSuchMethodError); //# 01: continued
}
