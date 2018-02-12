// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: global#Map:checks=[]*/
/*class: global#LinkedHashMap:*/
/*class: global#JsLinkedHashMap:checks=[$isLinkedHashMap]*/
/*class: global#double:checks=[]*/
/*class: global#JSDouble:checks=[$isdouble]*/

main() {
  <int, double>{}[0] = 0.5;
}
