// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*spec.class: global#JSArray:deps=[ArrayIterator,List],explicit=[JSArray,JSArray.E,JSArray<ArrayIterator.E>],implicit=[JSArray.E],needsArgs,test*/
/*prod.class: global#JSArray:deps=[List],implicit=[JSArray.E],needsArgs,test*/

@pragma('dart2js:noInline')
/*member: method:implicit=[method.T],needsArgs,test*/
method<T>() {
  return /*spec.*/ () => <T>[];
}

@pragma('dart2js:noInline')
test(o) => o is List<int>;

main() {
  makeLive(test(method<int>().call()));
  makeLive(test(method<String>().call()));
}
