// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  D<T> f<T>() => null;
}

class D<T> {}

C c;
var /*@topType=D<int>*/ f = c. /*@target=C::f*/ f<int>();

main() {}
