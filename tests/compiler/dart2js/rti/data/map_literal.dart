// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*!strong.class: global#Map:*/
/*strong.class: global#Map:explicit=[Map],indirect,needsArgs*/

/*!strong.class: global#LinkedHashMap:deps=[Map]*/
/*strong.class: global#LinkedHashMap:deps=[Map],explicit=[LinkedHashMap<LinkedHashMap.K,LinkedHashMap.V>],implicit=[LinkedHashMap.K,LinkedHashMap.V],indirect,needsArgs*/

/*!strong.class: global#JsLinkedHashMap:deps=[LinkedHashMap]*/
/*strong.class: global#JsLinkedHashMap:deps=[LinkedHashMap],direct,explicit=[JsLinkedHashMap.K,JsLinkedHashMap.V,void Function(JsLinkedHashMap.K,JsLinkedHashMap.V)],implicit=[JsLinkedHashMap.K,JsLinkedHashMap.V],needsArgs*/

/*!strong.class: global#double:explicit=[double]*/
/*strong.class: global#double:explicit=[double],implicit=[double]*/

/*class: global#JSDouble:*/

main() {
  <int, double>{}[0] = 0.5;
}
