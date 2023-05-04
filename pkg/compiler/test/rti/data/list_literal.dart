// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: global#List:deps=[Class.m,JSArray.markFixedList],explicit=[List,List<Object>,List<Object?>,List<String>?,List<markFixedList.T>],needsArgs,test*/
/*prod.class: global#List:deps=[Class.m],needsArgs,test*/

/*spec.class: global#JSArray:deps=[ArrayIterator,List],explicit=[JSArray,JSArray.E,JSArray<ArrayIterator.E>],implicit=[JSArray.E],needsArgs,test*/
/*prod.class: global#JSArray:deps=[List],implicit=[JSArray.E],needsArgs,test*/

main() {
  var c = Class();
  var list = c.m<int>();
  var set = list.toSet();
  set is Set<String>;
}

class Class {
  /*member: Class.m:implicit=[m.T],needsArgs,selectors=[Selector(call, m, arity=0, types=1)],test*/
  m<T>() {
    return <T>[];
  }
}
