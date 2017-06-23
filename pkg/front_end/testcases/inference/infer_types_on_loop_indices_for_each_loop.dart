// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class Foo {
  int bar = 42;
}

class Bar<T extends Iterable<String>> {
  void foo(T t) {
    for (var /*@type=String*/ i in t) {
      int x = /*error:INVALID_ASSIGNMENT*/ i;
    }
  }
}

class Baz<T, E extends Iterable<T>, S extends E> {
  void foo(S t) {
    for (var /*@type=Baz::T*/ i in t) {
      int x = /*error:INVALID_ASSIGNMENT*/ i;
      T y = i;
    }
  }
}

test() {
  var /*@type=List<Foo>*/ list = <Foo>[];
  for (var /*@type=Foo*/ x in list) {
    String y = /*error:INVALID_ASSIGNMENT*/ x;
  }

  for (dynamic x in list) {
    String y = /*info:DYNAMIC_CAST*/ x;
  }

  for (String x in /*error:FOR_IN_OF_INVALID_ELEMENT_TYPE*/ list) {
    String y = x;
  }

  var /*@type=dynamic*/ z;
  for (z in list) {
    String y = /*info:DYNAMIC_CAST*/ z;
  }

  Iterable iter = list;
  for (Foo /*info:DYNAMIC_CAST*/ x in iter) {
    var /*@type=Foo*/ y = x;
  }

  dynamic iter2 = list;
  for (Foo /*info:DYNAMIC_CAST*/ x in /*info:DYNAMIC_CAST*/ iter2) {
    var /*@type=Foo*/ y = x;
  }

  var /*@type=Map<String, Foo>*/ map = <String, Foo>{};
  // Error: map must be an Iterable.
  for (var /*@type=dynamic*/ x in /*error:FOR_IN_OF_INVALID_TYPE*/ map) {
    String y = /*info:DYNAMIC_CAST*/ x;
  }

  // We're not properly inferring that map.keys is an Iterable<String>
  // and that x is a String.
  for (var /*@type=String*/ x in map. /*@target=Map::keys*/ keys) {
    String y = x;
  }
}

main() {}
