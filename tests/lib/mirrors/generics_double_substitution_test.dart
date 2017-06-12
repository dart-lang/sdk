// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generics_double_substitution;

@MirrorsUsed(targets: "test.generics_double_substitution")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class A<R> {}

class B<S> {}

class C<T> extends B<A<T>> {
  A<T> field;
  A<T> returnType() {}
  parameterType(A<T> param) {}
}

main() {
  ClassMirror cOfString = reflect(new C<String>()).type;
  ClassMirror aOfString = reflect(new A<String>()).type;

  VariableMirror field = cOfString.declarations[#field];
  Expect.equals(aOfString, field.type);

  MethodMirror returnType = cOfString.declarations[#returnType];
  Expect.equals(aOfString, returnType.returnType);

  MethodMirror parameterType = cOfString.declarations[#parameterType];
  Expect.equals(aOfString, parameterType.parameters.single.type);

  ClassMirror typeArgOfSuperclass = cOfString.superclass.typeArguments.single;
  Expect.equals(aOfString, typeArgOfSuperclass); // //# 01: ok
}
