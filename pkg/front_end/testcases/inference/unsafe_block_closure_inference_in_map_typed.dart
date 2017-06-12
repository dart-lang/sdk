// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef int F();
main() {
  var /*@type=Map<int, () -> int>*/ v = <int, F>{
    1: /*@returnType=int*/ () {
      return 1;
    }
  };
}
