// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test derived from language_2/generic_methods_dynamic_test/05

/*!strong.class: global#JSArray:deps=[EmptyIterable,List,ListIterable,SubListIterable],explicit=[JSArray],needsArgs*/
/*strong.class: global#JSArray:deps=[ArrayIterator,EmptyIterable,List,ListIterable,SubListIterable],direct,explicit=[Iterable<JSArray.E>,JSArray,JSArray.E,JSArray<ArrayIterator.E>,List<JSArray.E>],implicit=[JSArray.E],needsArgs*/

/*!strong.class: global#List:deps=[C.bar,EmptyIterable,Iterable,JSArray,ListIterable],explicit=[List,List<B>],needsArgs*/
/*strong.class: global#List:deps=[C.bar,EmptyIterable,Iterable,JSArray,ListIterable,makeListFixedLength],direct,explicit=[List,List.E,List<B>,List<JSArray.E>,List<String>,List<makeListFixedLength.T>],implicit=[List.E],needsArgs*/

import "package:expect/expect.dart";

class A {}

/*!strong.class: B:explicit=[List<B>]*/
/*strong.class: B:explicit=[List<B>],implicit=[B]*/
class B {}

class C {
  /*!strong.element: C.bar:needsArgs,selectors=[Selector(call, bar, arity=1, types=1)]*/
  /*strong.element: C.bar:direct,explicit=[Iterable<bar.T>],implicit=[bar.T],needsArgs,selectors=[Selector(call, bar, arity=1, types=1)]*/
  List<T> bar<T>(Iterable<T> t) => <T>[t.first];
}

main() {
  C c = new C();
  dynamic x = c.bar<B>(<B>[new B()]);
  Expect.isTrue(x is List<B>);
}
