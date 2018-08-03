// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class A<T> {}

class B<T extends A> extends A implements C {
  A m(A a) {}
  A field;
}

class C<S, T> {}

class D extends A<int> {}

main() {
  ClassMirror aDecl = reflectClass(A);
  ClassMirror bDecl = reflectClass(B);
  ClassMirror cDecl = reflectClass(C);
  TypeMirror aInstance = reflect(new A()).type;
  TypeMirror aInstanceDynamic = reflect(new A<dynamic>()).type;
  TypeMirror dInstance = reflect(new D()).type;
  TypeMirror cInstance = reflect(new C<dynamic, dynamic>()).type;
  TypeMirror cNestedInstance = reflect(new C<C, dynamic>()).type;
  TypeMirror cTypeArgument = cNestedInstance.typeArguments.first;
  TypeMirror superA = bDecl.superclass;
  TypeMirror superC = bDecl.superinterfaces.single;
  MethodMirror m = bDecl.declarations[#m];
  VariableMirror field = bDecl.declarations[#field];
  TypeMirror returnTypeA = m.returnType;
  TypeMirror parameterTypeA = m.parameters.first.type;
  TypeMirror fieldTypeA = field.type;
  TypeMirror upperBoundA = bDecl.typeVariables.single.upperBound;
  TypeMirror dynamicMirror = currentMirrorSystem().dynamicType;

  Expect.isTrue(aDecl.isOriginalDeclaration);
  Expect.isTrue(reflect(dInstance).type.isOriginalDeclaration);
  Expect.isFalse(aInstance.isOriginalDeclaration);
  Expect.isFalse(aInstanceDynamic.isOriginalDeclaration);
  Expect.isFalse(superA.isOriginalDeclaration);
  Expect.isFalse(superC.isOriginalDeclaration);
  Expect.isFalse(returnTypeA.isOriginalDeclaration);
  Expect.isFalse(parameterTypeA.isOriginalDeclaration);
  Expect.isFalse(fieldTypeA.isOriginalDeclaration);
  Expect.isFalse(upperBoundA.isOriginalDeclaration);
  Expect.isFalse(cInstance.isOriginalDeclaration);
  Expect.isFalse(cNestedInstance.isOriginalDeclaration);
  Expect.isFalse(cTypeArgument.isOriginalDeclaration);

  Expect.isTrue(aDecl.typeArguments.isEmpty);
  Expect.isTrue(dInstance.typeArguments.isEmpty);
  Expect.equals(dynamicMirror, aInstance.typeArguments.single);
  Expect.equals(dynamicMirror, aInstanceDynamic.typeArguments.single);
  Expect.equals(dynamicMirror, superA.typeArguments.single);
  Expect.equals(dynamicMirror, superC.typeArguments.first);
  Expect.equals(dynamicMirror, superC.typeArguments.last);
  Expect.equals(dynamicMirror, returnTypeA.typeArguments.single);
  Expect.equals(dynamicMirror, parameterTypeA.typeArguments.single);
  Expect.equals(dynamicMirror, fieldTypeA.typeArguments.single);
  Expect.equals(dynamicMirror, upperBoundA.typeArguments.single);
  Expect.equals(dynamicMirror, cInstance.typeArguments.first);
  Expect.equals(dynamicMirror, cInstance.typeArguments.last);
  Expect.equals(dynamicMirror, cNestedInstance.typeArguments.last);
  Expect.equals(dynamicMirror, cTypeArgument.typeArguments.first);
  Expect.equals(dynamicMirror, cTypeArgument.typeArguments.last);
}
