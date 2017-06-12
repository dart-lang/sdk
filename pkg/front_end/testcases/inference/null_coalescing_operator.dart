// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

main() {
  List<int> x;
  var /*@type=List<int>*/ y = x ?? /*@typeArgs=int*/ [];
  List<int> z = y;
}
