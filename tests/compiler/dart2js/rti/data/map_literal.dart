// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*ast.class: global#Map:*/
/*kernel.class: global#Map:indirect,needsArgs*/
/*ast.class: global#LinkedHashMap:deps=[Map]*/
/*kernel.class: global#LinkedHashMap:deps=[Map],explicit=[LinkedHashMap<LinkedHashMap.K,LinkedHashMap.V>],implicit=[LinkedHashMap.K,LinkedHashMap.V],indirect,needsArgs*/
/*ast.class: global#JsLinkedHashMap:deps=[LinkedHashMap]*/
/*kernel.class: global#JsLinkedHashMap:deps=[LinkedHashMap],direct,explicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],implicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],needsArgs*/
/*ast.class: global#double:explicit=[double]*/
/*kernel.class: global#double:explicit=[double],implicit=[double]*/
/*class: global#JSDouble:*/

main() {
  <int, double>{}[0] = 0.5;
}
