// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C<T> {
  C.optional(void func([T x])) {}
  C.named(void func({T x})) {}
}

void optional_toplevel([x = /*@typeArgs=int*/ const [0]]) {}

void named_toplevel({x: /*@typeArgs=int*/ const [0]}) {}

main() {
  void optional_local([/*@type=dynamic*/ x = /*@typeArgs=int*/ const [0]]) {}
  void named_local({/*@type=dynamic*/ x: /*@typeArgs=int*/ const [0]}) {}
  var /*@type=C<dynamic>*/ c_optional_toplevel =
      new /*@typeArgs=dynamic*/ C.optional(optional_toplevel);
  var /*@type=C<dynamic>*/ c_named_toplevel =
      new /*@typeArgs=dynamic*/ C.named(named_toplevel);
  var /*@type=C<dynamic>*/ c_optional_local =
      new /*@typeArgs=dynamic*/ C.optional(optional_local);
  var /*@type=C<dynamic>*/ c_named_local =
      new /*@typeArgs=dynamic*/ C.named(named_local);
  var /*@type=C<dynamic>*/ c_optional_closure =
      new /*@typeArgs=dynamic*/ C.optional(/*@returnType=Null*/ (
          [/*@type=dynamic*/ x = /*@typeArgs=int*/ const [0]]) {});
  var /*@type=C<dynamic>*/ c_named_closure = new /*@typeArgs=dynamic*/ C.named(
      /*@returnType=Null*/ (
          {/*@type=dynamic*/ x: /*@typeArgs=int*/ const [0]}) {});
}
