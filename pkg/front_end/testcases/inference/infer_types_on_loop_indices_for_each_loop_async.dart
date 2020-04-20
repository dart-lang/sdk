// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

class Foo {
  int bar = 42;
}

class Bar<T extends Stream<String>> {
  foo(T t) async {
    await for (var /*@ type=String* */ i in t) {
      int x = /*error:INVALID_ASSIGNMENT*/ i;
    }
  }
}

class Baz<T, E extends Stream<T>, S extends E> {
  foo(S t) async {
    await for (var /*@ type=Baz::T* */ i in t) {
      int x = /*error:INVALID_ASSIGNMENT*/ i;
      T y = i;
    }
  }
}

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => null;
}

test() async {
  var /*@ type=MyStream<Foo*>* */ myStream = new MyStream<Foo>();
  await for (var /*@ type=Foo* */ x in myStream) {
    String y = /*error:INVALID_ASSIGNMENT*/ x;
  }

  await for (dynamic x in myStream) {
    String y = /*info:DYNAMIC_CAST*/ x;
  }

  await for (String x in /*error:FOR_IN_OF_INVALID_ELEMENT_TYPE*/ myStream) {
    String y = x;
  }

  var /*@ type=dynamic */ z;
  await for (z in myStream) {
    String y = /*info:DYNAMIC_CAST*/ z;
  }

  Stream stream = myStream;
  await for (Foo /*info:DYNAMIC_CAST*/ x in stream) {
    var /*@ type=Foo* */ y = x;
  }

  dynamic stream2 = myStream;
  await for (Foo /*info:DYNAMIC_CAST*/ x in /*info:DYNAMIC_CAST*/ stream2) {
    var /*@ type=Foo* */ y = x;
  }

  var /*@ type=Map<String*, Foo*>* */ map = <String, Foo>{};
  // Error: map must be a Stream.
  await for (var /*@ type=dynamic */ x in /*error:FOR_IN_OF_INVALID_TYPE*/ map) {
    String y = /*info:DYNAMIC_CAST*/ x;
  }
}

main() {}
