// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*kernel.class: global#List:deps=[Class,EmptyIterable,Iterable,JSArray,ListIterable,SetMixin],explicit=[List],implicit=[List.E],indirect,needsArgs*/
/*strong.class: global#List:deps=[Class,EmptyIterable,Iterable,JSArray,ListIterable,SetMixin,makeListFixedLength],direct,explicit=[List,List.E,List<JSArray.E>,List<String>,List<makeListFixedLength.T>],implicit=[List.E],needsArgs*/
/*omit.class: global#List:deps=[Class,EmptyIterable,Iterable,JSArray,ListIterable,SetMixin],explicit=[List],implicit=[List.E],indirect,needsArgs*/

/*kernel.class: global#JSArray:deps=[EmptyIterable,List,ListIterable,SetMixin,SubListIterable],explicit=[JSArray],implicit=[JSArray.E],indirect,needsArgs*/
/*strong.class: global#JSArray:deps=[ArrayIterator,EmptyIterable,List,ListIterable,SetMixin,SubListIterable],explicit=[Iterable<JSArray.E>,JSArray,JSArray.E,JSArray<ArrayIterator.E>,List<JSArray.E>],implicit=[JSArray.E],indirect,needsArgs*/
/*omit.class: global#JSArray:deps=[EmptyIterable,List,ListIterable,SetMixin,SubListIterable],explicit=[JSArray],implicit=[JSArray.E],indirect,needsArgs*/

main() {
  var c = new Class<int>();
  var list = c.m();
  var set = list.toSet();
  set is Set<String>;
}

/*class: Class:implicit=[Class.T],indirect,needsArgs*/
class Class<T> {
  m() {
    return <T>[];
  }
}
