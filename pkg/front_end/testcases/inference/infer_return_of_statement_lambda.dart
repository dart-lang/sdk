// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

List<String> strings() {
  var /*@type=Iterable<String>*/ stuff = /*@typeArgs=dynamic*/ []
      . /*@typeArgs=String*/ /*@target=Iterable::expand*/ expand(
          /*@returnType=List<String>*/ (/*@type=dynamic*/ i) {
    return <String>[];
  });
  return stuff. /*@target=Iterable::toList*/ toList();
}

main() {
  strings();
}
