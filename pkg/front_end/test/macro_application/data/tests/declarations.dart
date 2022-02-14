// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/macro.dart';

/*member: topLevelFunction1:

void topLevelFunction1GeneratedMethod_() {}
*/
@FunctionDeclarationsMacro1()
void topLevelFunction1() {}

/*member: topLevelFunction2:

void topLevelFunction2GeneratedMethod_e() {}
*/
@FunctionDeclarationsMacro1()
external void topLevelFunction2();

/*member: topLevelField1:

void topLevelField1GeneratedMethod_() {}
*/
@VariableDeclarationsMacro1()
int? topLevelField1;

/*member: topLevelField2:

void topLevelField2GeneratedMethod_e() {}
*/
@VariableDeclarationsMacro1()
external int? topLevelField2;

/*member: topLevelField3:

void topLevelField3GeneratedMethod_f() {}
*/
@VariableDeclarationsMacro1()
final int? topLevelField3 = null;

/*member: topLevelField4:

void topLevelField4GeneratedMethod_l() {}
*/
@VariableDeclarationsMacro1()
late int? topLevelField4;

/*member: topLevelGetter1:

void topLevelGetter1GeneratedMethod_g() {}
*/
@FunctionDeclarationsMacro1()
int? get topLevelGetter1 => null;

/*member: topLevelSetter1=:

void topLevelSetter1GeneratedMethod_s() {}
*/
@FunctionDeclarationsMacro1()
void set topLevelSetter1(int? value) {}

/*class: Class1:

void Class1GeneratedMethod_() {}

void Class1Introspection() {
  print("constructors=''");
  print("fields='instanceField1','instanceField2','instanceField3'");
  print("methods='instanceMethod1','instanceGetter1','[]','instanceSetter1'");
}
*/
@ClassDeclarationsMacro1()
@ClassDeclarationsMacro2()
class Class1 {
  /*member: Class1.:

augment class Class1 {
void Class1_GeneratedMethod_() {}

}*/
  @ConstructorDeclarationsMacro1()
  Class1();

  /*member: Class1.redirect:

augment class Class1 {
void Class1_redirectGeneratedMethod_f() {}

}*/
  @ConstructorDeclarationsMacro1()
  factory Class1.redirect() = Class1;

  /*member: Class1.fact:

augment class Class1 {
void Class1_factGeneratedMethod_f() {}

}*/
  @ConstructorDeclarationsMacro1()
  factory Class1.fact() => new Class1();

  /*member: Class1.instanceMethod1:

void Class1_instanceMethod1GeneratedMethod_() {}
*/
  @MethodDeclarationsMacro1()
  void instanceMethod1() {}

  /*member: Class1.instanceGetter1:

void Class1_instanceGetter1GeneratedMethod_g() {}
*/
  @MethodDeclarationsMacro1()
  int? get instanceGetter1 => null;

  /*member: Class1.instanceSetter1=:

void Class1_instanceSetter1GeneratedMethod_s() {}
*/
  @MethodDeclarationsMacro1()
  void set instanceSetter1(int? value) {}

  /*member: Class1.[]:

void Class1_[]GeneratedMethod_o() {}
*/
  @MethodDeclarationsMacro1()
  int operator [](int i) => i;

  /*member: Class1.instanceField1:

void Class1_instanceField1GeneratedMethod_() {}
*/
  @FieldDeclarationsMacro1()
  int? instanceField1;

  /*member: Class1.instanceField2:

void Class1_instanceField2GeneratedMethod_f() {}
*/
  @FieldDeclarationsMacro1()
  final int? instanceField2 = null;

  /*member: Class1.instanceField3:

void Class1_instanceField3GeneratedMethod_fl() {}
*/
  @FieldDeclarationsMacro1()
  late final int? instanceField3 = null;
}

/*class: Class2:

void Class2GeneratedMethod_a() {}

void Class2Introspection() {
  print("constructors=");
  print("fields='instanceField1'");
  print("methods='instanceMethod1'");
}
*/
@ClassDeclarationsMacro1()
@ClassDeclarationsMacro2()
abstract class Class2 {
  /*member: Class2.instanceMethod1:

void Class2_instanceMethod1GeneratedMethod_a() {}
*/
  @MethodDeclarationsMacro1()
  void instanceMethod1();

  /*member: Class2.instanceField1:

void Class2_instanceField1GeneratedMethod_() {}
*/
  @FieldDeclarationsMacro1()
  abstract int? instanceField1;
}
