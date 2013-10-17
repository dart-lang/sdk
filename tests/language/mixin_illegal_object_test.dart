// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C0 extends Object
with Object                       /// 01: compile-time error
{ }

class C1 = Object with Object;  /// 02: compile-time error

main() {
  new C0();
  new C1();                       /// 02: continued
}
