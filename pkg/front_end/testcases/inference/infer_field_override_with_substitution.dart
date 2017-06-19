// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class A<T> {
  List<T> get x;
  void set y(List<T> value);
  List<T> z;
}

class B extends A<int> {
  var /*@topType=List<int>*/ x;
  var /*@topType=List<int>*/ y;
  var /*@topType=List<int>*/ z;
}

main() {}
