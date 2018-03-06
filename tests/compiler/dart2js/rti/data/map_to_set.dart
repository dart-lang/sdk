// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*ast.class: global#Map:deps=[Class],needsArgs*/
/*kernel.class: global#Map:deps=[Class],indirect,needsArgs*/
/*ast.class: global#LinkedHashMap:deps=[Map],needsArgs*/
/*kernel.class: global#LinkedHashMap:deps=[Map],explicit=[LinkedHashMap<LinkedHashMap.K,LinkedHashMap.V>],implicit=[LinkedHashMap.K,LinkedHashMap.V],indirect,needsArgs*/
/*ast.class: global#JsLinkedHashMap:deps=[LinkedHashMap],implicit=[JsLinkedHashMap.K],needsArgs*/
/*kernel.class: global#JsLinkedHashMap:deps=[LinkedHashMap],explicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],implicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],indirect,needsArgs*/
/*ast.class: global#double:explicit=[double]*/
/*kernel.class: global#double:explicit=[double],implicit=[double]*/
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
