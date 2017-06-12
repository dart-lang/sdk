// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generics_substitution;

@MirrorsUsed(targets: "test.generics_substitution")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class SuperGeneric<R, S> {
  R r;
  s(S s) {}
}

class Generic<T> extends SuperGeneric<T, int> {
  T t() {}
}

main() {
  ClassMirror genericDecl = reflectClass(Generic);
  ClassMirror genericOfString = reflect(new Generic<String>()).type;
  ClassMirror superGenericDecl = reflectClass(SuperGeneric);
  ClassMirror superOfTAndInt = genericDecl.superclass;
  ClassMirror superOfStringAndInt = genericOfString.superclass;

  Expect.isTrue(genericDecl.isOriginalDeclaration);
  Expect.isFalse(genericOfString.isOriginalDeclaration);
  Expect.isTrue(superGenericDecl.isOriginalDeclaration);
  Expect.isFalse(superOfTAndInt.isOriginalDeclaration);
  Expect.isFalse(superOfStringAndInt.isOriginalDeclaration);

  Symbol r(ClassMirror cm) =>
      (cm.declarations[#r] as VariableMirror).type.simpleName;
  Symbol s(ClassMirror cm) =>
      (cm.declarations[#s] as MethodMirror).parameters[0].type.simpleName;
  Symbol t(ClassMirror cm) =>
      (cm.declarations[#t] as MethodMirror).returnType.simpleName;

  Expect.equals(#T, r(genericDecl.superclass));
  Expect.equals(#int, s(genericDecl.superclass));
  Expect.equals(#T, t(genericDecl));

  Expect.equals(#String, r(genericOfString.superclass));
  Expect.equals(#int, s(genericOfString.superclass));
  Expect.equals(#String, t(genericOfString));

  Expect.equals(#R, r(superGenericDecl));
  Expect.equals(#S, s(superGenericDecl));

  Expect.equals(#T, r(superOfTAndInt));
  Expect.equals(#int, s(superOfTAndInt));

  Expect.equals(#String, r(superOfStringAndInt));
  Expect.equals(#int, s(superOfStringAndInt));
}
