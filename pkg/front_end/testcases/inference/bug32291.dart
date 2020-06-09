// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  var /*@ type=List<List<String*>*>* */ l = /*@ typeArgs=List<String*>* */ [
    /*@ typeArgs=String* */ ["hi", "world"]
  ];
  var /*@ type=Iterable<List<String*>*>* */ i1 =
      l. /*@target=Iterable.map*/ /*@ typeArgs=List<String*>* */ map(
          /*@ returnType=List<String*>* */ (/*@ type=List<String*>* */ ll) =>
              ll /*@target=List.==*/ ?? /*@ typeArgs=String* */ []);
  var /*@ type=Iterable<int*>* */ i2 =
      i1. /*@target=Iterable.map*/ /*@ typeArgs=int* */ map(
          /*@ returnType=int* */ (List<String> l) =>
              l. /*@target=List.length*/ length);
  print(i2);
}
