// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

// Test derived from language/generic_methods_dynamic_test/05

/*spec.class: global#JSArray:deps=[ArrayIterator,List],explicit=[JSArray.E,JSArray<ArrayIterator.E>],implicit=[JSArray.E],needsArgs,test*/
/*prod.class: global#JSArray:deps=[List],implicit=[JSArray.E],needsArgs,test*/

/*spec.class: global#List:deps=[C.bar,JSArray.markFixedList],explicit=[List,List<B>,List<Object>,List<Object?>,List<String>?,List<markFixedList.T>],needsArgs,test*/
/*prod.class: global#List:deps=[C.bar],explicit=[List,List<B>],needsArgs,test*/

class A {}

/*class: B:explicit=[List<B>],implicit=[B]*/
class B {}

class C {
  /*spec.member: C.bar:explicit=[Iterable<bar.T>],implicit=[bar.T],needsArgs,selectors=[Selector(call, bar, arity=1, types=1)],test*/
  /*prod.member: C.bar:implicit=[bar.T],needsArgs,selectors=[Selector(call, bar, arity=1, types=1)],test*/
  List<T> bar<T>(Iterable<T> t) => <T>[t.first];
}

main() {
  C c = C();
  dynamic x = c.bar<B>(<B>[new B()]);
  makeLive(x is List<B>);
}
