// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

T f<T>() => null;

class A {}

A aTopLevel;
void set aTopLevelSetter(A value) {}

class C {
  A aField;
  void set aSetter(A value) {}
  void test() {
    A aLocal;
    for (aLocal in /*@ typeArgs=Iterable<A*>* */ f()) {}

    for (/*@target=C.aField*/ /*@target=C.aField*/ aField
        in /*@ typeArgs=Iterable<A*>* */ f()) {}

    for (/*@target=C.aSetter*/ /*@target=C.aSetter*/ aSetter
        in /*@ typeArgs=Iterable<A*>* */ f()) {}

    for (aTopLevel in /*@ typeArgs=Iterable<A*>* */ f()) {}

    for (aTopLevelSetter in /*@ typeArgs=Iterable<A*>* */ f()) {}
  }
}

main() {}
