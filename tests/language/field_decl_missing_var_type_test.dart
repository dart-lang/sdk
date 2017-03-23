// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Exercises issue 2997, missing var or type on field declarations should
// generate a compile-time error.

class A {
  _this; //                     //# 01: compile-time error
  A(x) : this._this = x; //     //# 01: continued
}

main() {
  new A(0); //                  //# 01: continued
}
