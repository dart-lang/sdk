// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#List:deps=[Class],explicit=[List],indirect,needsArgs*/
/*class: global#JSArray:deps=[List],explicit=[JSArray],implicit=[JSArray.E],indirect,needsArgs*/

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
