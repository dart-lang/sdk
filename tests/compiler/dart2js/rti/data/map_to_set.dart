// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#Map:needsArgs,deps=[Class]*/
/*class: global#LinkedHashMap:needsArgs,deps=[Map]*/
/*class: global#JsLinkedHashMap:needsArgs,deps=[LinkedHashMap],implicit=[JsLinkedHashMap.K]*/
/*class: global#double:explicit=[double],required,checks=[num]*/

main() {
  var c = new Class<double, int>();
  var map = c.m();
  var set = map.keys.toSet();
  set is Set<String>;
}

/*class: Class:needsArgs*/
class Class<T, S> {
  m() {
    return <T, S>{};
  }
}
