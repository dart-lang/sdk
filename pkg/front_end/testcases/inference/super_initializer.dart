// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => null;

class C extends B {
  C() : super(/*@typeArgs=int*/ f());
}

class B {
  B(int x);
}

main() {}
