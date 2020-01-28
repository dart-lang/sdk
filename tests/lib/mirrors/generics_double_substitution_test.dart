// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generics_double_substitution;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class A<R> {}

class B<S> {}

class C<T> extends B<A<T>> {
  late A<T> field;
  A<T> returnType() => new A<T>();
  parameterType(A<T> param) {}
}

main() {
  ClassMirror cOfString = reflect(new C<String>()).type;
  ClassMirror aOfString = reflect(new A<String>()).type;

  VariableMirror field = cOfString.declarations[#field] as VariableMirror;
  Expect.equals(aOfString, field.type);

  MethodMirror returnType = cOfString.declarations[#returnType] as MethodMirror;
  Expect.equals(aOfString, returnType.returnType);

  MethodMirror parameterType = cOfString.declarations[#parameterType] as MethodMirror;
  Expect.equals(aOfString, parameterType.parameters.single.type);

  ClassMirror typeArgOfSuperclass = cOfString.superclass!.typeArguments.single as ClassMirror;
  Expect.equals(aOfString, typeArgOfSuperclass); //# 01: ok
}
