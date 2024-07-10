// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.class: global#List:deps=[Class,JSArray.markFixedList],explicit=[List,List<Object>,List<Object?>,List<String>?,List<markFixedList.T>],needsArgs,test*/
/*prod.class: global#List:deps=[Class],explicit=[List],needsArgs,test*/

/*spec.class: global#JSArray:deps=[ArrayIterator,List],explicit=[JSArray.E,JSArray<ArrayIterator.E>],implicit=[JSArray.E],needsArgs,test*/
/*prod.class: global#JSArray:deps=[List],implicit=[JSArray.E],needsArgs,test*/

main() {
  var c = Class<int>();
  var list = c.m();
  var set = list.toSet();
  set is Set<String>;
}

/*class: Class:implicit=[Class.T],needsArgs,test*/
class Class<T> {
  m() {
    return <T>[];
  }
}
