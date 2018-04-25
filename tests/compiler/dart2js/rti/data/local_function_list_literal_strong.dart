// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*class: global#JSArray:deps=[EmptyIterable,List,ListIterable,SubListIterable],explicit=[JSArray],needsArgs*/

/*element: method:needsArgs*/
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
