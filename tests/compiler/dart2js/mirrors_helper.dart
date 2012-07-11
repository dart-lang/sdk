// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is read by 'mirrors_test.dart'.
 */

#library('mirrors_helper');

typedef E Func<E,F extends Foo>(F f);

main() {

}

class Foo {

}

interface Bar<E> {

}

class Baz<E,F extends Foo> implements Bar<E> {
  Baz();
  const Baz.named();
  factory Baz.factory();

  method1(e) {}
  static void method2(E e, [F f = null]) {}
  void method3(E func1(F f), Func<E,F> func2) {}

  bool operator==(Object other) => return false;
  Baz<E,F> operator negate() => this;
}

class Boz extends Foo {
  var field1;
  int _field2;
  final String field3;

  int get field2() => _field2;
  void set field2(int value) {
    _field2 = value;
  }
}

