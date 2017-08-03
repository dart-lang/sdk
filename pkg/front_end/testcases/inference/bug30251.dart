// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>(T t) => t;

class C {
  final /*@topType=dynamic*/ x;
  C(int p) : x = /*@typeArgs=int*/ f(1 /*@target=num::+*/ + p);
}

main() {}
