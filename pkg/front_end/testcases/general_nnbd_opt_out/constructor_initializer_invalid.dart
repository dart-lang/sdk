// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class C1 { int f; C1() : ; }
class C2 { int f; C2() : f; }
class C3 { int f; C3() : f++; }

main() {
  var c1 = new C1();
  c1.toString();
  var c2 = new C2();
  c2.toString();
  var c3 = new C3();
  c3.toString();
}

