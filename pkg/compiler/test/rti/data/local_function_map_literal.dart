// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

/*spec.class: global#LinkedHashMap:deps=[Map],direct,explicit=[LinkedHashMap<LinkedHashMap.K,LinkedHashMap.V>],implicit=[LinkedHashMap.K,LinkedHashMap.V],needsArgs*/
/*prod.class: global#LinkedHashMap:deps=[Map],needsArgs*/

@pragma('dart2js:noInline')
/*spec.member: method:implicit=[method.T],indirect,needsArgs*/
/*prod.member: method:needsArgs*/
method<T>() {
  return /*spec.needsSignature*/ () => <T, int>{};
}

@pragma('dart2js:noInline')
test(o) => o is Map<int, int>;

main() {
  makeLive(test(method<int>().call()));
  makeLive(test(method<String>().call()));
}
