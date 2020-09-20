// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test non-existing redirecting constructor and
// redirecting to a factory constructor.

class B {
  B() : this.a(); //   //# none: compile-time error
  factory B.a() {} //  //# 01: compile-time error
  B.a(); //            //# 02: ok
}

main() => new B();
