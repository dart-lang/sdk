// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A(int a);
}

class B {
  final a; //    //# 01: compile-time error
  const B(dynamic v) //
      : a = A(v) //# 01: continued
  ;
}

void main() {
  const B("");
}
