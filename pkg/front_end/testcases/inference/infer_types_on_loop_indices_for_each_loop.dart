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
    for (var /*@promotedType=none*/ i in t) {
      int x = /*error:INVALID_ASSIGNMENT*/ /*@promotedType=none*/ i;
    }
  }
}

class Baz<T, E extends Iterable<T>, S extends E> {
  void foo(S t) {
    for (var /*@promotedType=none*/ i in t) {
      int x = /*error:INVALID_ASSIGNMENT*/ /*@promotedType=none*/ i;
      T y = /*@promotedType=none*/ i;
    }
  }
}

test() {
  var /*@type=List<Foo>*/ list = <Foo>[];
  for (var /*@promotedType=none*/ x in /*@promotedType=none*/ list) {
    String y = /*error:INVALID_ASSIGNMENT*/ /*@promotedType=none*/ x;
  }

  for (dynamic /*@promotedType=none*/ x in /*@promotedType=none*/ list) {
    String y = /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ x;
  }

  for (String /*@promotedType=none*/ x
      in /*error:FOR_IN_OF_INVALID_ELEMENT_TYPE*/ /*@promotedType=none*/ list) {
    String y = /*@promotedType=none*/ x;
  }

  var /*@type=dynamic*/ z;
  for (z in /*@promotedType=none*/ list) {
    String y = /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ z;
  }

  Iterable iter = /*@promotedType=none*/ list;
  for (Foo /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ x
      in /*@promotedType=none*/ iter) {
    var /*@type=Foo*/ y = /*@promotedType=none*/ x;
  }

  dynamic iter2 = /*@promotedType=none*/ list;
  for (Foo /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ x
      in /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ iter2) {
    var /*@type=Foo*/ y = /*@promotedType=none*/ x;
  }

  var /*@type=Map<String, Foo>*/ map = <String, Foo>{};
  // Error: map must be an Iterable.
  for (var /*@promotedType=none*/ x
      in /*error:FOR_IN_OF_INVALID_TYPE*/ /*@promotedType=none*/ map) {
    String y = /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ x;
  }

  // We're not properly inferring that map.keys is an Iterable<String>
  // and that x is a String.
  for (var /*@promotedType=none*/ x in /*@promotedType=none*/ map.keys) {
    String y = /*@promotedType=none*/ x;
  }
}
