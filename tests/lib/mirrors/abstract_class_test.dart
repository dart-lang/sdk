// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.abstract_class_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

abstract class Foo {
  foo();
}
class Bar extends Foo {
  foo() {}
}

abstract class FunctionFoo implements Function {
  call();
}
class FunctionBar extends FunctionFoo {
  call() {}
}

abstract class GenericFoo<T> {
  T genericFoo();
}
class GenericBar<T> extends GenericFoo<T> {
  T genericFoo() {}
}

void main() {
  // FunctionTypeMirror
  baz() {}
  Expect.isFalse(reflect(baz).type.isAbstract);

  return;  /// 01: ok

  // Unbound ClassMirror
  Expect.isTrue(reflectClass(Foo).isAbstract);
  Expect.isFalse(reflectClass(Bar).isAbstract);
  Expect.isTrue(reflect(new Bar()).type.superclass.isAbstract);
  Expect.isFalse(reflect(new Bar()).type.isAbstract);

  Expect.isTrue(reflectClass(FunctionFoo).isAbstract);
  Expect.isFalse(reflectClass(FunctionBar).isAbstract);
  Expect.isTrue(reflect(new FunctionBar()).type.superclass.isAbstract);
  Expect.isFalse(reflect(new FunctionBar()).type.isAbstract);

  Expect.isTrue(reflectClass(GenericFoo).isAbstract);
  Expect.isFalse(reflectClass(GenericBar).isAbstract);

  // Bound ClassMirror
  Expect.isTrue(reflect(new GenericBar<int>()).type.superclass.isAbstract);
  Expect.isFalse(reflect(new GenericBar<int>()).type.isAbstract);
}
