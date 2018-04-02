// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#List:deps=[Class.m,EmptyIterable,Iterable,JSArray,ListIterable,SetMixin],explicit=[List],implicit=[List.E],indirect,needsArgs*/
/*class: global#JSArray:deps=[EmptyIterable,List,ListIterable,SetMixin,SubListIterable],explicit=[JSArray],implicit=[JSArray.E],indirect,needsArgs*/

main() {
  var c = new Class();
  var list = c.m<int>();
  var set = list.toSet();
  set is Set<String>;
}

class Class {
  /*element: Class.m:implicit=[m.T],indirect,needsArgs,selectors=[Selector(call, m, arity=0, types=1)]*/
  m<T>() {
    return <T>[];
  }
}
