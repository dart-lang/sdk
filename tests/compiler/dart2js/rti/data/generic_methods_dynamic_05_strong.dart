// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test derived from language_2/generic_methods_dynamic_test/05

/*class: global#JSArray:deps=[EmptyIterable,List,ListIterable,SubListIterable],explicit=[JSArray,List<JSArray.E>],implicit=[JSArray.E],indirect,needsArgs*/
/*class: global#List:deps=[C.bar,EmptyIterable,Iterable,JSArray,ListIterable,makeListFixedLength],explicit=[List,List.E,List<B>,List<JSArray.E>,List<makeListFixedLength.T>],implicit=[List.E],indirect,needsArgs*/

import "package:expect/expect.dart";

class A {}

/*class: B:explicit=[List<B>],implicit=[B]*/
class B {}

class C {
  /*element: C.bar:implicit=[bar.T],indirect,needsArgs,selectors=[Selector(call, bar, arity=1, types=1)]*/
  List<T> bar<T>(Iterable<T> t) => <T>[t.first];
}

main() {
  C c = new C();
  dynamic x = c.bar<B>(<B>[new B()]);
  Expect.isTrue(x is List<B>);
}
