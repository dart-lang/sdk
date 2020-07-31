// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*@testedFeatures=inference*/

void test() {
  List<dynamic> l = /*@ typeArgs=dynamic */ [1, "hello"];
  List<String> l2 = l
      . /*@target=Iterable.map*/ /*@ typeArgs=String* */ map(
          /*@ returnType=String* */ (dynamic element) =>
              element. /*@target=Object.toString*/ toString())
      . /*@target=Iterable.toList*/ toList();
}

void main() {}
