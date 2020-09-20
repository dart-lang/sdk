// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*prod.class: global#Map:deps=[Class],needsArgs*/
/*spec.class: global#Map:deps=[Class],explicit=[Map,Map<Object?,Object?>],indirect,needsArgs*/

/*prod.class: global#LinkedHashMap:deps=[Map],needsArgs*/
/*spec.class: global#LinkedHashMap:deps=[Map],direct,explicit=[LinkedHashMap<LinkedHashMap.K,LinkedHashMap.V>],implicit=[LinkedHashMap.K,LinkedHashMap.V],needsArgs*/

/*prod.class: global#JsLinkedHashMap:deps=[LinkedHashMap],implicit=[JsLinkedHashMap.K],needsArgs*/
/*spec.class: global#JsLinkedHashMap:deps=[LinkedHashMap],direct,explicit=[JsLinkedHashMap.K,JsLinkedHashMap.V,void Function(JsLinkedHashMap.K,JsLinkedHashMap.V)],implicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],needsArgs*/

/*prod.class: global#double:*/
/*spec.class: global#double:implicit=[double]*/

/*class: global#JSDouble:*/

main() {
  var c = new Class<double, int>();
  var map = c.m();
  var set = map.keys.toSet();
  set is Set<String>;
}

/*spec.class: Class:implicit=[Class.S,Class.T],indirect,needsArgs*/
/*prod.class: Class:needsArgs*/
class Class<T, S> {
  m() {
    return <T, S>{};
  }
}
