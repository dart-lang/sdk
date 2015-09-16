// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final x;       /// 01: ok
                 /// 02: compile-time error
  var x;         /// 03: compile-time error
  get x => null; /// 04: compile-time error
  set x(v) {}    /// 05: compile-time error

  const A()
    : x = 'foo'  /// 01: continued
    : x = 'foo'  /// 02: continued
    : x = 'foo'  /// 03: continued
    : x = 'foo'  /// 04: continued
    : x = 'foo'  /// 05: continued
  ;
}

use(x) => x;

A a = const A();

main() {
  use(a);
}
