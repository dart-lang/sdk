// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Class1.instanceMethod1:MethodDeclarationsMacro1.new()
 Class1.instanceGetter1:MethodDeclarationsMacro1.new()
 Class1.[]:MethodDeclarationsMacro1.new()
 Class1.instanceField1:FieldDeclarationsMacro1.new()
 Class1.instanceField2:FieldDeclarationsMacro1.new()
 Class1.instanceField3:FieldDeclarationsMacro1.new()
 Class1.instanceSetter1:MethodDeclarationsMacro1.new()
 Class1.:ConstructorDeclarationsMacro1.new()
 Class1.redirect:ConstructorDeclarationsMacro1.new()
 Class1.fact:ConstructorDeclarationsMacro1.new()
 Class1:ClassDeclarationsMacro2.new()
 Class1:ClassDeclarationsMacro1.new()
 Class2.instanceMethod1:MethodDeclarationsMacro1.new()
 Class2.instanceField1:FieldDeclarationsMacro1.new()
 Class2:ClassDeclarationsMacro2.new()
 Class2:ClassDeclarationsMacro1.new()
 topLevelFunction1:FunctionDeclarationsMacro1.new()
 topLevelFunction2:FunctionDeclarationsMacro1.new()
 topLevelField1:VariableDeclarationsMacro1.new()
 topLevelField2:VariableDeclarationsMacro1.new()
 topLevelField3:VariableDeclarationsMacro1.new()
 topLevelField4:VariableDeclarationsMacro1.new()
 topLevelGetter1:FunctionDeclarationsMacro1.new()
 topLevelSetter1:FunctionDeclarationsMacro1.new()*/

import 'package:macro/macro.dart';

@FunctionDeclarationsMacro1()
/*member: topLevelFunction1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelFunction1GeneratedMethod_() {}

*/
void topLevelFunction1() {}

@FunctionDeclarationsMacro1()
/*member: topLevelFunction2:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelFunction2GeneratedMethod_e() {}

*/
external void topLevelFunction2();

@VariableDeclarationsMacro1()
/*member: topLevelField1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelField1GeneratedMethod_() {}

*/
int? topLevelField1;

@VariableDeclarationsMacro1()
/*member: topLevelField2:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelField2GeneratedMethod_e() {}

*/
external int? topLevelField2;

@VariableDeclarationsMacro1()
/*member: topLevelField3:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelField3GeneratedMethod_f() {}

*/
final int? topLevelField3 = null;

@VariableDeclarationsMacro1()
/*member: topLevelField4:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelField4GeneratedMethod_l() {}

*/
late int? topLevelField4;

@FunctionDeclarationsMacro1()
/*member: topLevelGetter1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelGetter1GeneratedMethod_g() {}

*/
int? get topLevelGetter1 => null;

@FunctionDeclarationsMacro1()
/*member: topLevelSetter1=:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void topLevelSetter1GeneratedMethod_s() {}

*/
void set topLevelSetter1(int? value) {}

@ClassDeclarationsMacro1()
@ClassDeclarationsMacro2()
/*class: Class1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1Introspection() {
  print("constructors='','redirect','fact'");
  print("fields='instanceField1','instanceField2','instanceField3'");
  print("methods='instanceMethod1','instanceGetter1','[]','instanceSetter1','Class1_GeneratedMethod_','Class1_redirectGeneratedMethod_f','Class1_factGeneratedMethod_f'");
}


augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1GeneratedMethod_() {}

*/
class Class1 {
  @ConstructorDeclarationsMacro1()
  /*member: Class1.:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class1 {
void Class1_GeneratedMethod_() {}

}
*/
  Class1();

  @ConstructorDeclarationsMacro1()
  /*member: Class1.redirect:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class1 {
void Class1_redirectGeneratedMethod_f() {}

}
*/
  factory Class1.redirect() = Class1;

  @ConstructorDeclarationsMacro1()
  /*member: Class1.fact:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

augment class Class1 {
void Class1_factGeneratedMethod_f() {}

}
*/
  factory Class1.fact() => new Class1();

  @MethodDeclarationsMacro1()
  /*member: Class1.instanceMethod1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1_instanceMethod1GeneratedMethod_() {}

*/
  void instanceMethod1() {}

  @MethodDeclarationsMacro1()
  /*member: Class1.instanceGetter1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1_instanceGetter1GeneratedMethod_g() {}

*/
  int? get instanceGetter1 => null;

  @MethodDeclarationsMacro1()
  /*member: Class1.instanceSetter1=:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1_instanceSetter1GeneratedMethod_s() {}

*/
  void set instanceSetter1(int? value) {}

  @MethodDeclarationsMacro1()
  /*member: Class1.[]:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1_operatorGeneratedMethod_o() {}

*/
  int operator [](int i) => i;

  @FieldDeclarationsMacro1()
  /*member: Class1.instanceField1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1_instanceField1GeneratedMethod_() {}

*/
  int? instanceField1;

  @FieldDeclarationsMacro1()
  /*member: Class1.instanceField2:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1_instanceField2GeneratedMethod_f() {}

*/
  final int? instanceField2 = null;

  @FieldDeclarationsMacro1()
  /*member: Class1.instanceField3:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class1_instanceField3GeneratedMethod_fl() {}

*/
  late final int? instanceField3 = null;
}

@ClassDeclarationsMacro1()
@ClassDeclarationsMacro2()
/*class: Class2:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class2Introspection() {
  print("constructors=");
  print("fields='instanceField1'");
  print("methods='instanceMethod1'");
}


augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class2GeneratedMethod_a() {}

*/
abstract class Class2 {
  @MethodDeclarationsMacro1()
  /*member: Class2.instanceMethod1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class2_instanceMethod1GeneratedMethod_() {}

*/
  void instanceMethod1();

  @FieldDeclarationsMacro1()
  /*member: Class2.instanceField1:
declarations:
augment library 'org-dartlang-test:///a/b/c/main.dart';

void Class2_instanceField1GeneratedMethod_a() {}

*/
  abstract int? instanceField1;
}
