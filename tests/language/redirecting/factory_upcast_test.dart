// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A implements B {
  var x;
  A(Object this.x);
}

class B {
  factory B(String s) = A;
}

main() {
  B(42 as dynamic); //# 01: runtime error
}
