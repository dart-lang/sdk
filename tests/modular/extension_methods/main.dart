// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'def2.dart';

main() {
  testExplicitAccess(new Class(42));
  testImplicitAccess(new Class(87));
  testStaticAccess();
  testExplicitGenericAccess(new GenericClass<String>('foo'), 'bar');
  testImplicitGenericAccess(new GenericClass<String>('baz'), 'boz');
}

testExplicitAccess(Class c) {
  Expect.equals(c.field, Extension(c).method());
  Expect.equals(c.field, Extension(c).property);
  Expect.equals(123, Extension(c).property = 123);
  var f = Extension(c).method;
  Expect.equals(c.field, f());
}

testImplicitAccess(Class c) {
  Expect.equals(c.field, c.method());
  Expect.equals(42, c.methodWithOptionals());
  Expect.equals(123, c.methodWithOptionals(123));
  Expect.equals(c.field, c.property);
  Expect.equals(123, c.property = 123);
  var f = c.method;
  Expect.equals(c.field, f());
  var f2 = c.methodWithOptionals;
  Expect.equals(42, f2());
  Expect.equals(87, f2(87));
}

testStaticAccess() {
  Expect.equals(Extension.staticField, Extension.staticMethod());
  Expect.equals(Extension.staticField, Extension.staticProperty);
  Expect.equals(123, Extension.staticProperty = 123);
}

testExplicitGenericAccess<T>(GenericClass<T> c, T value) {
  Expect.equals(c.field, GenericExtension<T>(c).method());
  Expect.equals(c.field, GenericExtension<T>(c).property);
  Expect.equals(value, GenericExtension<T>(c).property = value);
  var f = GenericExtension<T>(c).method;
  Expect.equals(c.field, f());
}

testImplicitGenericAccess<T>(GenericClass<T> c, T value) {
  Expect.equals(c.field, c.method());
  Expect.equals(c.field, c.property);
  Expect.equals(value, c.property = value);
  var f = c.method;
  Expect.equals(c.field, f());
}
