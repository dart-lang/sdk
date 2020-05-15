// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec:nnbd-off.class: global#List:deps=[Class.m],explicit=[List,List<String>],indirect,needsArgs*/
/*prod:nnbd-off.class: global#List:deps=[Class.m],explicit=[List],indirect,needsArgs*/

/*spec:nnbd-off.class: global#JSArray:deps=[ArrayIterator,List],explicit=[JSArray,JSArray.E,JSArray<ArrayIterator.E>],implicit=[JSArray.E],indirect,needsArgs*/
/*prod:nnbd-off.class: global#JSArray:deps=[List],explicit=[JSArray],implicit=[JSArray.E],indirect,needsArgs*/

main() {
  var c = new Class();
  var list = c.m<int>();
  var set = list.toSet();
  set is Set<String>;
}

class Class {
  /*member: Class.m:implicit=[m.T],indirect,needsArgs,selectors=[Selector(call, m, arity=0, types=1)]*/
  m<T>() {
    return <T>[];
  }
}
