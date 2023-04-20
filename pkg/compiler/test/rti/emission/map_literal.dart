// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: global#Map:instance*/

/*class: global#LinkedHashMap:*/
/*spec.class: global#JsLinkedHashMap:checkedInstance,checks=[],instance*/
/*prod.class: global#JsLinkedHashMap:checks=[],instance*/

/*spec.class: global#double:checkedInstance,instance,typeArgument*/

/*class: global#JSNumNotInt:checks=[$isTrustedGetRuntimeType],instance*/

main() {
  <int, double>{}[0] = 0.5;
}
