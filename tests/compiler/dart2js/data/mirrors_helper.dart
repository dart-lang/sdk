// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is read by 'mirrors_test.dart'.
 */

library mirrors_helper;

typedef E Func<E, F extends Foo>(F f);

main() {}

/// Singleline doc comment.
@Metadata(null)
// Singleline comment 1.
// Singleline comment 2.
@Metadata(true)
@Metadata(false)
@Metadata(0)
@Metadata(1.5)
@Metadata("Foo")
@Metadata(const ["Foo"])
@Metadata(const {'foo': "Foo"})
@metadata
/** Multiline doc comment. */
/* Multiline comment. */ class Foo {
  m(@metadata a) {}
}

abstract class Bar<E> {}

class Baz<E, F extends Foo> implements Bar<E> {
  Baz();
  const Baz.named();
  factory Baz.factory() => new Baz<E, F>();

  static method1(e) {}
  void method2(E e, [F f = null]) {}
  Baz<E, F> method3(E func1(F f), Func<E, F> func2) => null;

  bool operator ==(Object other) => false;
  int operator -() => 0;
  operator$foo() {}
}

class Boz extends Foo {
  var field1;
  int _field2;
  final String field3 = "field3";

  int get field2 => _field2;
  void set field2(int value) {
    _field2 = value;
  }
}

// ignore: UNUSED_ELEMENT
class _PrivateClass {
  var _privateField;
  // ignore: UNUSED_ELEMENT
  get _privateGetter => _privateField;
  // ignore: UNUSED_ELEMENT
  void set _privateSetter(value) => _privateField = value;
  // ignore: UNUSED_ELEMENT
  void _privateMethod() {}
  _PrivateClass._privateConstructor();
  factory _PrivateClass._privateFactoryConstructor() => null;
}

const metadata = const Metadata(null);

class Metadata {
  final data;
  const Metadata(this.data);
}
