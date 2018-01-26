// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#List:needsArgs,deps=[Class],indirectTest,explicit=[List]*/
/*class: global#JSArray:needsArgs,deps=[List],indirectTest,explicit=[JSArray],implicit=[JSArray.E]*/

main() {
  var c = new Class<int>();
  var list = c.m();
  var set = list.toSet();
  set is Set<String>;
}

/*class: Class:needsArgs,indirectTest,implicit=[Class.T]*/
class Class<T> {
  m() {
    return <T>[];
  }
}
