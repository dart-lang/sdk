// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*strong.class: global#JSArray:deps=[ArrayIterator,List],explicit=[JSArray,JSArray.E,JSArray<ArrayIterator.E>],implicit=[JSArray.E],indirect,needsArgs*/
/*omit.class: global#JSArray:deps=[List],explicit=[JSArray],needsArgs*/

/*strong.member: method:implicit=[method.T],indirect,needsArgs*/
/*omit.member: method:needsArgs*/
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
