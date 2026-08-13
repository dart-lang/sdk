// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class C<T> {
  C.optional(void func([T x])) {}
  C.named(void func({T x})) {}
}

void optional_toplevel([x = const [0]]) {}

void named_toplevel({x = const [0]}) {}

main() {
  void optional_local([x = const [0]]) {}
  void named_local({x = const [0]}) {}
  var c_optional_toplevel = new C.optional(optional_toplevel);
  var c_named_toplevel = new C.named(named_toplevel);
  var c_optional_local = new C.optional(optional_local);
  var c_named_local = new C.named(named_local);
  var c_optional_closure = new C.optional(([x = const [0]]) {});
  var c_named_closure = new C.named(({x = const [0]}) {});
}
