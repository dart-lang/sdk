// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*strong.class: global#JSArray:deps=[ArrayIterator,EmptyIterable,List,ListIterable,SubListIterable],direct,explicit=[Iterable<JSArray.E>,JSArray,JSArray.E,JSArray<ArrayIterator.E>,List<JSArray.E>],implicit=[JSArray.E],needsArgs*/
/*omit.class: global#JSArray:deps=[EmptyIterable,List,ListIterable,SubListIterable],explicit=[JSArray],needsArgs*/

/*strong.element: method:implicit=[method.T],indirect,needsArgs*/
/*omit.element: method:needsArgs*/
@NoInline()
method<T>() {
  return () => <T>[];
}

@NoInline()
test(o) => o is List<int>;

main() {
  Expect.isTrue(test(method<int>().call()));
  Expect.isFalse(test(method<String>().call()));
}
