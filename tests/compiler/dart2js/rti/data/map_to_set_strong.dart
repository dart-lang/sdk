// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#Map:deps=[Class],indirect,needsArgs*/
/*class: global#LinkedHashMap:deps=[Map],explicit=[LinkedHashMap<LinkedHashMap.K,LinkedHashMap.V>],implicit=[LinkedHashMap.K,LinkedHashMap.V],indirect,needsArgs*/
/*class: global#JsLinkedHashMap:deps=[LinkedHashMap],explicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],implicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],indirect,needsArgs*/
/*class: global#double:explicit=[double],implicit=[double]*/
/*class: global#JSDouble:*/

main() {
  var c = new Class<double, int>();
  var map = c.m();
  var set = map.keys.toSet();
  set is Set<String>;
}

/*ast.class: Class:needsArgs*/
/*kernel.class: Class:implicit=[Class.S,Class.T],indirect,needsArgs*/
class Class<T, S> {
  m() {
    return <T, S>{};
  }
}
