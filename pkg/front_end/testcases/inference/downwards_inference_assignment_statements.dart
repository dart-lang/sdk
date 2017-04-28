// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  List<int> l;
  l = /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"];
  l = (l = /*@typeArgs=int*/ [1]);
}
