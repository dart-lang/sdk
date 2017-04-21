// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.a() : this.b();
  A.b()
    : this.a() // //# 01: compile-time error
  ;
  A.c() : this.b();
}

main() {
  new A.a();
  new A.b();
  new A.c();
}
