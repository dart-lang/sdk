// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#Map:checks=[],instance*/
/*class: global#LinkedHashMap:checkedInstance*/
/*class: global#JsLinkedHashMap:checkedInstance,checks=[$isLinkedHashMap],instance*/
/*class: global#double:checkedInstance,checks=[],instance,typeArgument*/
/*class: global#JSNumber:checks=[$isdouble,$isnum],instance*/
/*class: global#JSDouble:checks=[],instance*/

main() {
  <int, double>{}[0] = 0.5;
}
