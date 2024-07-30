// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test static members.

library lib;

import 'dart:mirrors';

import 'stringify.dart';

class Foo {
  static String bar = '...';
  static const int biz = 5;
  String aux = '';
  static foo() {}
  baz() {}
}

void main() {
  expect('Variable(s(aux) in s(Foo))',
      reflectClass(Foo).declarations[new Symbol('aux')]);
  expect('Method(s(baz) in s(Foo))',
      reflectClass(Foo).declarations[new Symbol('baz')]);
  expect('<null>', reflectClass(Foo).declarations[new Symbol('aux=')]);
  expect('Method(s(foo) in s(Foo), static)',
      reflectClass(Foo).declarations[new Symbol('foo')]);
  expect('Variable(s(bar) in s(Foo), static)',
      reflectClass(Foo).declarations[new Symbol('bar')]);
  expect('Variable(s(biz) in s(Foo), static, final, const)',
      reflectClass(Foo).declarations[new Symbol('biz')]);
}
