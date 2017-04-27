// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>(List<T> s) => null;
main() {
  String x = f(/*@typeArgs=String*/ ['hi']);
  String y =
      f(/*@typeArgs=String*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 42]);
}
