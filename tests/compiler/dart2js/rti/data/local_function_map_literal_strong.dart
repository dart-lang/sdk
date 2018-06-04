// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*strong.class: global#LinkedHashMap:deps=[Map],direct,explicit=[LinkedHashMap<LinkedHashMap.K,LinkedHashMap.V>],implicit=[LinkedHashMap.K,LinkedHashMap.V],needsArgs*/
/*omit.class: global#LinkedHashMap:deps=[Map],needsArgs*/

/*strong.element: method:implicit=[method.T],indirect,needsArgs*/
/*omit.element: method:needsArgs*/
@NoInline()
method<T>() {
  return () => <T, int>{};
}

@NoInline()
test(o) => o is Map<int, int>;

main() {
  Expect.isTrue(test(method<int>().call()));
  Expect.isFalse(test(method<String>().call()));
}
