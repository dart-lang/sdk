// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_test;

import 'dart:mirrors';
import "package:expect/expect.dart";

String toplevelVariable = "";

class C {
  final int i;
  const C(this.i);
}

class A<T> {
  static int staticField = 0;
  @C(42)
  @C(44)
  String field = "";
  var dynamicTypeField;
  T typeVariableField;
  H<int> parameterizedTypeField;
}

class H<T> {}

testOriginalDeclaration() {
  ClassMirror a = reflectClass(A);
  VariableMirror staticField = a.declarations[#staticField] as VariableMirror;
  VariableMirror field = a.declarations[#field] as VariableMirror;
  VariableMirror dynamicTypeField =
      a.declarations[#dynamicTypeField] as VariableMirror;
  VariableMirror typeVariableField =
      a.declarations[#typeVariableField] as VariableMirror;
  VariableMirror parameterizedTypeField =
      a.declarations[#parameterizedTypeField] as VariableMirror;

  Expect.equals(reflectType(int), staticField.type);
  Expect.equals(reflectClass(String), field.type);
  Expect.equals(reflectType(dynamic), dynamicTypeField.type);
  Expect.equals(a.typeVariables.single, typeVariableField.type);
  Expect.equals(reflect(new H<int>()).type, parameterizedTypeField.type);

  Expect.equals(2, field.metadata.length);
  Expect.equals(reflect(const C(42)), field.metadata.first);
  Expect.equals(reflect(const C(44)), field.metadata.last);
}

testInstance() {
  ClassMirror aOfString = reflect(new A<String>()).type;
  VariableMirror staticField =
      aOfString.declarations[#staticField] as VariableMirror;
  VariableMirror field = aOfString.declarations[#field] as VariableMirror;
  VariableMirror dynamicTypeField =
      aOfString.declarations[#dynamicTypeField] as VariableMirror;
  VariableMirror typeVariableField =
      aOfString.declarations[#typeVariableField] as VariableMirror;
  VariableMirror parameterizedTypeField =
      aOfString.declarations[#parameterizedTypeField] as VariableMirror;

  Expect.equals(reflectType(int), staticField.type);
  Expect.equals(reflectClass(String), field.type);
  Expect.equals(reflectType(dynamic), dynamicTypeField.type);
  Expect.equals(reflectClass(String), typeVariableField.type);
  Expect.equals(reflect(new H<int>()).type, parameterizedTypeField.type);

  Expect.equals(2, field.metadata.length);
  Expect.equals(reflect(const C(42)), field.metadata.first);
  Expect.equals(reflect(const C(44)), field.metadata.last);
}

testTopLevel() {
  LibraryMirror currentLibrary = currentMirrorSystem().findLibrary(#field_test);
  VariableMirror topLevel =
      currentLibrary.declarations[#toplevelVariable] as VariableMirror;
  Expect.equals(reflectClass(String), topLevel.type);
}

main() {
  testOriginalDeclaration();
  testInstance();
  testTopLevel();
}
