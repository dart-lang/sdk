// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.14

import 'new_as_selector.dart' as prefix1;
import 'new_as_selector.dart' deferred as prefix2 hide E;

int new = 87; // error

C c = C();

class Super {}

class C extends Super {
  int new = 42; // error

  C() : super.new(); // error
  C.named() : this.new(); // error

  method()  {
    this.new; // error
    this.new(); // error
    this.new<int>(); // error
    this.new = 87; // error
  }
}

extension E on int {
  external int new; // error

  call<T>() {}
}

method(dynamic d) => d.new; // error

test() {
  new C().new; // error
  new C().new(); // error
  new C().new = 87; // error
  C c = C();
  c.new; // error
  c.new = 87; // error
  dynamic foo;
  foo.new; // error
  foo.new(); // error
  foo.new<int>(); // error
  foo?.new; // error
  foo?.new(); // error
  foo?.new<int>(); // error
  foo..new; // error
  foo..new(); // error
  foo..new<int>(); // error
  (foo).new; // error
  (foo).new(); // error
  (foo).new<int>(); // error
  prefix1.new; // error
  prefix1.new(); // error
  prefix1.new<int>(); // error
  prefix2.c.new; // error
  prefix2.c.new(); // error
  prefix2.c.new<int>(); // error
  E(0).new; // error
  E(0).new(); // error
  E(0).new<int>(); // error
  unresolved.new; // error
  unresolved.new(); // error
  unresolved.new<int>(); // error
  C.new; // error
  C.new(); // error
}

main() {
}