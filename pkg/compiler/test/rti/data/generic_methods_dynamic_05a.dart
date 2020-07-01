// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Reduced version of generic_methods_dynamic_05a_strong.

import "package:expect/expect.dart";

/*spec.class: A:deps=[C.bar],direct,explicit=[A.T*,A<B*>*,A<bar.T*>*],needsArgs*/
/*prod.class: A:deps=[C.bar],explicit=[A<B*>*],needsArgs*/
class A<T> {
  final T field;

  A(this.field);
}

/*spec.class: B:explicit=[A<B*>*],implicit=[B]*/
/*prod.class: B:explicit=[A<B*>*]*/
class B {}

class C {
  /*spec.member: C.bar:explicit=[A<bar.T*>*],implicit=[bar.T],indirect,needsArgs,selectors=[Selector(call, bar, arity=1, types=1)]*/
  /*prod.member: C.bar:needsArgs,selectors=[Selector(call, bar, arity=1, types=1)]*/
  A<T> bar<T>(A<T> t) => new A<T>(t.field);
}

main() {
  C c = new C();

  dynamic x = c.bar<B>(new A<B>(new B()));
  Expect.isTrue(x is A<B>);
}
