// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*spec:nnbd-off.member: method:implicit=[method.T],indirect,needsArgs*/
/*prod:nnbd-off.member: method:needsArgs*/
/*spec:nnbd-off.class: global#JSArray:deps=[ArrayIterator,List],direct,explicit=[JSArray,JSArray.E,JSArray<ArrayIterator.E>],implicit=[JSArray.E],needsArgs*/
/*prod:nnbd-off.class: global#JSArray:deps=[List],explicit=[JSArray],needsArgs*/

@pragma('dart2js:noInline')
method<T>() {
  return () => <T>[];
}

@pragma('dart2js:noInline')
test(o) => o is List<int>;

main() {
  Expect.isTrue(test(method<int>().call()));
  Expect.isFalse(test(method<String>().call()));
}
