// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: global#List:deps=[Class.m,JSArray.markFixedList],explicit=[List,List<Object>,List<String>?,List<markFixedList.T>],indirect,needsArgs*/
/*prod.class: global#List:deps=[Class.m],indirect,needsArgs*/

/*spec.class: global#JSArray:deps=[ArrayIterator,List],explicit=[JSArray,JSArray.E,JSArray<ArrayIterator.E>],implicit=[JSArray.E],indirect,needsArgs*/
/*prod.class: global#JSArray:deps=[List],implicit=[JSArray.E],indirect,needsArgs*/

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
