// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#Map:deps=[Class],needsArgs*/
/*class: global#LinkedHashMap:deps=[Map],needsArgs*/
/*class: global#JsLinkedHashMap:deps=[LinkedHashMap],implicit=[JsLinkedHashMap.K],needsArgs*/
/*class: global#double:checks=[num],explicit=[double],required*/

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
