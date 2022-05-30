// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin M1 {
  int get m => 1;
}

mixin M2 extend M1 {}

mixin M3 extends M1 {}

class C1 {
  int get c => 2;
}

class C2 extend C1 with M2 {}

class C3 on C1 with M3 {}

main() {
  var c2 = new C2();
  c2.m + c2.c;
  var c3 = new C3();
  c3.m + c3.c;
}
