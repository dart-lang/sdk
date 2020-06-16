// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class M0 {
  factory M0(a, b, c) => throw "uncalled";
  factory M0.named() => throw "uncalled";
}

class M1 {
  M1();
}

class M2 {
  M2.named();
}

class C0 = Object with M0;







class D0 extends Object with M0 {}







main() {
  new C0();







  new D0();











}
