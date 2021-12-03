// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextTypeTest);
  });
}

@reflectiveTest
class ContextTypeTest extends FeatureComputerTest {
  Future<void> assertContextType(String content, [String? expectedType]) async {
    await completeIn(content);
    var result = testAnalysisResult;
    var computer = FeatureComputer(result.typeSystem, result.typeProvider);
    var type = computer.computeContextType(
        completionTarget.containingNode, cursorIndex);

    if (expectedType == null) {
      expect(type, null);
    } else {
      expect(type?.getDisplayString(withNullability: false), expectedType);
    }
  }

  Future<void> test_argumentList_instanceCreation() async {
    await assertContextType('''
class C {
  C({String s}) {}
}
void f() {
  C(s:^);
}
''', 'String');
  }

  Future<void> test_argumentList_named_afterColon() async {
    await assertContextType('''
void f({int i, String s, bool b}) {}
void g() {
  f(s:^);
}
''', 'String');
  }

  Future<void> test_argumentList_named_afterColon_withSpace() async {
    await assertContextType('''
void f({int i, String s, bool b}) {}
void g() {
  f(s: ^);
}
''', 'String');
  }

  Future<void> test_argumentList_named_beforeColon() async {
    await assertContextType('''
void f({int i = 0}) {}
void g() {
  f(i^:);
}
''');
  }

  Future<void> test_argumentList_named_beforeLabel() async {
    await assertContextType('''
void f({int i = 0}) {}
void g() {
  f(^i:);
}
''');
  }

  Future<void>
      test_argumentList_named_beforeLabel_hasPreviousParameter() async {
    await assertContextType('''
void f(int i, {String s = ''}) {}
void g() {
  f(^s:);
}
''', 'int');
  }

  Future<void>
      test_argumentList_named_beforeLabel_hasPreviousParameter2() async {
    await assertContextType('''
void f(int i, {String s = ''}) {}
void g() {
  f(^ s:);
}
''', 'int');
  }

  Future<void> test_argumentList_named_method() async {
    await assertContextType('''
class C {
  void m(int i) {}
}
void f(C c) {
  c.m(^);
}
''', 'int');
  }

  Future<void> test_argumentList_named_unresolved_hasNamedParameters() async {
    await assertContextType('''
void f({int i}) {}

void g() {
  f(j: ^);
}
''');
  }

  Future<void> test_argumentList_named_unresolved_noNamedParameters() async {
    await assertContextType('''
void f() {}

void g() {
  f(j: ^);
}
''');
  }

  Future<void> test_argumentList_named_with_requiredPositional() async {
    await assertContextType('''
void f(String s, {int i}) {}
void g() {
  f('str', i: ^);
}
''', 'int');
  }

  Future<void>
      test_argumentList_named_with_requiredPositional_defaultValue() async {
    await assertContextType('''
void f(String s, {int i = 0}) {}
void g() {
  f('str', i: ^);
}
''', 'int');
  }

  Future<void> test_argumentList_noParameters() async {
    await assertContextType('''
void f() {}
void g() {
  f(^);
}
''');
  }

  Future<void> test_argumentList_noParameters_whitespace() async {
    await assertContextType('''
void f() {}
void g() {
  f(  ^  );
}
''');
  }

  Future<void> test_argumentList_noParameters_whitespace_left() async {
    await assertContextType('''
void f() {}
void g() {
  f(  ^);
}
''');
  }

  Future<void> test_argumentList_noParameters_whitespace_right() async {
    await assertContextType('''
void f() {}
void g() {
  f(^  );
}
''');
  }

  Future<void> test_argumentList_positional() async {
    await assertContextType('''
void f([int i]) {}
void g() {
  f(^);
}
''', 'int');
  }

  Future<void> test_argumentList_positional_asNamed() async {
    await assertContextType('''
void f([int i]) {}
void g() {
  f(i: ^);
}
''');
  }

  Future<void> test_argumentList_positional_asNamed_beforeColon() async {
    await assertContextType('''
void f(String s, bool b, [int i = 0]) {}
void g() {
  f(i^:);
}
''');
  }

  Future<void> test_argumentList_positional_asNamed_beforeLabel() async {
    await assertContextType('''
void f([int i = 0]) {}
void g() {
  f(^i:);
}
''', 'int');
  }

  Future<void>
      test_argumentList_positional_asNamed_beforeLabel_hasPreviousParameter() async {
    await assertContextType('''
void f(String s, [int i = 0]) {}
void g() {
  f(^i:);
}
''', 'String');
  }

  Future<void> test_argumentList_positional_whitespace() async {
    await assertContextType('''
void f([int i]) {}
void g() {
  f(  ^  );
}
''', 'int');
  }

  Future<void> test_argumentList_positional_with_requiredPositional() async {
    await assertContextType('''
void f(String s, bool b, [int i]) {}
void g() {
  f('str', false, ^);
}
''', 'int');
  }

  Future<void>
      test_argumentList_positional_with_requiredPositional_defaultValue() async {
    await assertContextType('''
void f(String s, bool b, [int i = 2]) {}
void g() {
  f('str', false, ^);
}
''', 'int');
  }

  Future<void> test_argumentList_requiredPositional_asNamed() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f(i: ^);
}
''');
  }

  Future<void> test_argumentList_requiredPositional_first() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f(^w);
}
''', 'int');
  }

  Future<void> test_argumentList_requiredPositional_first2() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f( ^ , 'str');
}
''', 'int');
  }

  Future<void> test_argumentList_requiredPositional_first_implicit() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f(^);
}
''', 'int');
  }

  Future<void> test_argumentList_requiredPositional_last() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f(1, 'str', t^);
}
''', 'bool');
  }

  Future<void> test_argumentList_requiredPositional_last_implicit() async {
    await assertContextType('''
void f(int i, String str, bool b, num n) {}
void g() {
  f(1, 'str', ^);
}
''', 'bool');
  }

  Future<void> test_argumentList_requiredPositional_last_implicit2() async {
    await assertContextType('''
void f(int i, String str, bool b, num n) {}
void g() {
  f(1, 'str', ^ );
}
''', 'bool');
  }

  Future<void> test_argumentList_requiredPositional_middle() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f(1, w^);
}
''', 'String');
  }

  Future<void> test_argumentList_requiredPositional_middle2() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f(1, ^, );
}
''', 'String');
  }

  Future<void> test_argumentList_requiredPositional_middle3() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f(1, ^ , );
}
''', 'String');
  }

  Future<void> test_argumentList_requiredPositional_middle_implicit() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g() {
  f(1, ^ );
}
''', 'String');
  }

  Future<void> test_argumentList_typeParameter_resolved() async {
    await assertContextType('''
class A {}
class B {}
class C<T extends A> {
  void m(T t) {}
}
void f(C<B> c) {
  c.m(^);
}
''', 'B');
  }

  Future<void> test_argumentList_typeParameter_unresolved() async {
    await assertContextType('''
class A {}
class C<T extends A> {
  void m1(T t) {}
  void m2() {
    m1(^);
  }
}
''', 'A');
  }

  Future<void> test_assertInitializer_with_identifier() async {
    await assertContextType('''
class C {
  C(int i) : assert(b^);
}
''', 'bool');
  }

  Future<void> test_assertInitializer_with_identifier_whitespace() async {
    await assertContextType('''
class C {
  C(int i) : assert(  b^  );
}
''', 'bool');
  }

  Future<void> test_assertInitializer_without_identifier() async {
    await assertContextType('''
class C {
  C(int i) : assert(^);
}
''', 'bool');
  }

  Future<void> test_assertInitializer_without_identifier_whitespace() async {
    await assertContextType('''
class C {
  C(int i) : assert(  ^  );
}
''', 'bool');
  }

  Future<void> test_assignmentExpression_withoutType() async {
    await assertContextType('''
void g(String s) {
  var x = ^s.length;
}
''');
  }

  Future<void> test_assignmentExpression_withType() async {
    await assertContextType('''
void g() {
  int i = ^a;
}
''', 'int');
  }

  Future<void> test_binaryExpression_RHS() async {
    await assertContextType('''
class C {
  C(int i) : assert(0 < i^);
}
''', 'num');
  }

  Future<void> test_className_period() async {
    await assertContextType('''
int x = List.^;
''', 'int');
  }

  Future<void> test_className_period_identifier() async {
    await assertContextType('''
int x = List.^;
''', 'int');
  }

  Future<void> test_className_typeArguments_period() async {
    await assertContextType('''
int x = List<double>.^;
''', 'int');
  }

  Future<void> test_className_typeArguments_period_identifier() async {
    await assertContextType('''
int x = List<double>.foo^;
''', 'int');
  }

  Future<void> test_fieldDeclaration_int() async {
    await assertContextType('''
class Foo {
  int i=^;
}
''', 'int');
  }

  Future<void> test_fieldDeclaration_int_missingSemicolon() async {
    await assertContextType('''
class Foo {
  int i=^
}
''', 'int');
  }

  Future<void> test_fieldDeclaration_int_multiple() async {
    await assertContextType('''
class Foo {
  int i=1,j=2,k=^;
}
''', 'int');
  }

  Future<void> test_fieldDeclaration_int_multiple_whitespace() async {
    await assertContextType('''
class Foo {
  int i = 1 , j = 2 , k =  ^  ;
}
''', 'int');
  }

  Future<void> test_fieldDeclaration_int_whitespace() async {
    await assertContextType('''
class Foo {
  int i = ^ ;
}
''', 'int');
  }

  Future<void> test_fieldDeclaration_var() async {
    await assertContextType('''
class Foo {
  var x =^;
}
''');
  }

  Future<void> test_fieldDeclaration_var_impliedType_int() async {
    await assertContextType('''
class Foo {
  var i = ^ ;
}
''', 'int');
  }

  Future<void> test_fieldDeclaration_var_impliedType_list() async {
    await assertContextType('''
class Foo {
  var list = ^ ;
}
''', 'List<dynamic>');
  }

  Future<void> test_fieldDeclaration_var_impliedType_string() async {
    await assertContextType('''
class Foo {
  var string = ^ ;
}
''', 'String');
  }

  Future<void> test_fieldDeclaration_var_whitespace() async {
    await assertContextType('''
class Foo {
  var x = ^ ;
}
''');
  }

  Future<void> test_ifElement() async {
    await assertContextType('''
void f(bool b, int e) {
  var m = <int, String>{if (^) e : ''};
}
''', 'bool');
  }

  Future<void> test_ifElement_identifier() async {
    await assertContextType('''
void f(bool b, int e) {
  var m = <int, String>{if (b^) e : ''};
}
''', 'bool');
  }

  Future<void> test_ifStatement_condition() async {
    await assertContextType('''
void foo() {
  if(^) {}
}
''', 'bool');
  }

  Future<void> test_ifStatement_condition2() async {
    await assertContextType('''
void foo() {
  if(t^) {}
}
''', 'bool');
  }

  Future<void> test_ifStatement_condition_whitespace() async {
    await assertContextType('''
void foo() {
  if(  ^  ) {}
}
''', 'bool');
  }

  Future<void> test_listLiteral_beforeTypeParameter() async {
    await assertContextType('''
void f(int e) {
  var l = ^<int>[e];
}
''');
  }

  Future<void> test_listLiteral_element() async {
    await assertContextType('''
void f(int e) {
  var l = <int>[^e];
}
''', 'int');
  }

  Future<void> test_listLiteral_element_empty() async {
    await assertContextType('''
void f(int e) {
  var l = <int>[^];
}
''', 'int');
  }

  Future<void> test_listLiteral_typeParameter() async {
    await assertContextType('''
void f(int e) {
  var l = <^int>[e];
}
''');
  }

  Future<void> test_mapLiteralEntry_key() async {
    await assertContextType('''
void f(String k, int v) {
  var m = <String, int>{^k : v};
}
''', 'String');
  }

  Future<void> test_mapLiteralEntry_value() async {
    await assertContextType('''
void f(String k, int v) {
  var m = <String, int>{k : ^v};
}
''', 'int');
  }

  Future<void> test_namedExpression() async {
    await assertContextType('''
void f({int i}) {}
void g(int j) {
  f(i: ^j);
}
''', 'int');
  }

  Future<void> test_propertyAccess() async {
    await assertContextType('''
class C {
  int f;
}
void g(C c) {
  int i = c.^f;
}
''', 'int');
  }

  Future<void> test_setOrMapLiteral_map_beforeTypeParameter() async {
    await assertContextType('''
void f() {
  var m = ^<int, int>{};
}
''');
  }

  Future<void> test_setOrMapLiteral_map_element() async {
    await assertContextType('''
void f(bool b, int e) {
  var m = <int, String>{^ : ''};
}
''', 'int');
  }

  Future<void> test_setOrMapLiteral_map_typeParameter() async {
    await assertContextType('''
void f() {
  var m = <int, ^int>{};
}
''');
  }

  Future<void> test_setOrMapLiteral_set_beforeTypeParameter() async {
    await assertContextType('''
void f() {
  var s = ^<int>{};
}
''');
  }

  Future<void> test_setOrMapLiteral_set_element() async {
    await assertContextType('''
void f(int e) {
  var s = <int>{^e};
}
''', 'int');
  }

  Future<void> test_setOrMapLiteral_set_typeParameter() async {
    await assertContextType('''
void f() {
  var s = <^int>{};
}
''');
  }

  Future<void> test_topLevelVariableDeclaration_int() async {
    await assertContextType('''
int i=^;
''', 'int');
  }

  Future<void> test_topLevelVariableDeclaration_int_missingSemicolon() async {
    await assertContextType('''
int i=^
''', 'int');
  }

  Future<void> test_topLevelVariableDeclaration_int_multiple() async {
    await assertContextType('''
int i=1,j=2,k=^;
''', 'int');
  }

  Future<void>
      test_topLevelVariableDeclaration_int_multiple_whitespace() async {
    await assertContextType('''
int i = 1 , j = 2 , k =  ^  ;
''', 'int');
  }

  Future<void> test_topLevelVariableDeclaration_int_whitespace() async {
    await assertContextType('''
int i =  ^  ;
''', 'int');
  }

  Future<void> test_topLevelVariableDeclaration_var() async {
    await assertContextType('''
var x=^;
''');
  }

  Future<void> test_topLevelVariableDeclaration_var_noEqual() async {
    await assertContextType('''
int x^;
''');
  }

  Future<void> test_topLevelVariableDeclaration_var_whitespace() async {
    await assertContextType('''
var x=  ^  ;
''');
  }
}

abstract class FeatureComputerTest extends AbstractSingleUnitTest {
  int cursorIndex = 0;

  late CompletionTarget completionTarget;

  @override
  bool verifyNoTestUnitErrors = false;

  Future<void> completeIn(String content) async {
    cursorIndex = content.indexOf('^');
    if (cursorIndex < 0) {
      fail('Missing node offset marker (^) in content');
    }
    content =
        content.substring(0, cursorIndex) + content.substring(cursorIndex + 1);
    await resolveTestCode(content);
    completionTarget = CompletionTarget.forOffset(testUnit, cursorIndex);
  }
}
