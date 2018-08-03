// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*strong.class: global#Map:deps=[Class,JsLinkedHashMap,MapMixin],explicit=[Map,Map<JsLinkedHashMap.K,JsLinkedHashMap.V>,Map<MapMixin.K,MapMixin.V>],indirect,needsArgs*/
/*omit.class: global#Map:deps=[Class],needsArgs*/

/*strong.class: global#LinkedHashMap:deps=[Map],direct,explicit=[LinkedHashMap<LinkedHashMap.K,LinkedHashMap.V>],implicit=[LinkedHashMap.K,LinkedHashMap.V],needsArgs*/
/*omit.class: global#LinkedHashMap:deps=[Map],needsArgs*/

/*strong.class: global#JsLinkedHashMap:deps=[LinkedHashMap],explicit=[JsLinkedHashMap.K,JsLinkedHashMap.V,Map<JsLinkedHashMap.K,JsLinkedHashMap.V>,void Function(JsLinkedHashMap.K,JsLinkedHashMap.V)],implicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],indirect,needsArgs*/
/*omit.class: global#JsLinkedHashMap:deps=[LinkedHashMap],implicit=[JsLinkedHashMap.K],needsArgs*/

/*strong.class: global#double:explicit=[double],implicit=[double]*/
/*omit.class: global#double:explicit=[double]*/

/*class: global#JSDouble:*/

main() {
  var c = new Class<double, int>();
  var map = c.m();
  var set = map.keys.toSet();
  set is Set<String>;
}

/*strong.class: Class:implicit=[Class.S,Class.T],indirect,needsArgs*/
/*omit.class: Class:needsArgs*/
class Class<T, S> {
  m() {
    return <T, S>{};
  }
}
