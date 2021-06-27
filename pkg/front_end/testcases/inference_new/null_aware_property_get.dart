// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
/*@testedFeatures=inference*/
library test;

class Class {
  T method<T>() => null;
}

main() {
  Class c;
  num Function() f = /*@target=Class.==*/ /*@type=Class**/ c
      ?. /*@target=Class.method*/ method;
}
