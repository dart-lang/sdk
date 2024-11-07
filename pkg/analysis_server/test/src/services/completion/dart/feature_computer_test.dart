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
      completionTarget.containingNode,
      cursorIndex,
    );

    if (expectedType == null) {
      expect(type, null);
    } else {
      expect(type?.getDisplayString(), expectedType);
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

  Future<void> test_argumentList_named_second() async {
    await assertContextType('''
void f({String p1, int p2}) {}

void g() {
  f(p1: '', p2: ^);
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

  Future<void> test_forEachPartsWithPattern() async {
    await assertContextType('''
void f() {
  for ((int x) in ^) {}
}
''', 'Iterable<dynamic>');
  }

  Future<void> test_forPartsWithPattern_condition() async {
    await assertContextType('''
void f() {
  for ((var x); ^;) {}
}
''', 'bool');
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

  Future<void> test_listPattern_beforeTypeArgument() async {
    await assertContextType('''
void f(List<int> l) {
  if (l case ^<int>[var e]) {}
}
''');
  }

  Future<void> test_listPattern_element() async {
    await assertContextType('''
void f(List<int> l) {
  if (l case <int>[^var e]) {}
}
''', 'int');
  }

  Future<void> test_listPattern_element_empty_noTypeArgument() async {
    await assertContextType('''
void f(List<int> l) {
  if (l case [^]) {}
}
''', 'int');
  }

  Future<void> test_listPattern_element_empty_typeArgument() async {
    await assertContextType('''
void f(List<int> l) {
  if (l case <int>[^]) {}
}
''', 'int');
  }

  Future<void> test_listPattern_typeArgument() async {
    await assertContextType('''
void f(List<int> l) {
  if (l case <^int>[var e]) {}
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

  Future<void> test_mapPattern_empty() async {
    await assertContextType('''
void f(Map<String, int> m) {
  if (m case <String, int>{^}) {}
}
''', 'String');
  }

  Future<void> test_mapPatternEntry_key_after() async {
    await assertContextType('''
void f(Map<String, int> m) {
  if (m case <String, int>{'a'^ : var v}) {}
}
''', 'String');
  }

  Future<void> test_mapPatternEntry_key_before() async {
    await assertContextType('''
void f(Map<String, int> m) {
  if (m case <String, int>{^'a' : var v}) {}
}
''', 'String');
  }

  Future<void> test_mapPatternEntry_value() async {
    await assertContextType('''
void f(String k, int v) {
  if (m case <String, int>{'a' : ^var v}) {}
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

  Future<void> test_objectPattern() async {
    await assertContextType('''
void f(List<int> l) {
  if (l case List(length: ^)) {}
}
''', 'int');
  }

  Future<void> test_patternAssignment_withoutType() async {
    await assertContextType('''
void f(Map<String, int> m) {
  {'a': a} = ^m;
}
''');
  }

  Future<void> test_patternAssignment_withType() async {
    await assertContextType('''
void f(List<int> l) {
  int i;
  [i] = ^l;
}
''', 'List<int>');
  }

  Future<void> test_patternVariableDeclaration_withoutType() async {
    await assertContextType('''
void f((int, int) r) {
  var (a, b) = ^r;
}
''');
  }

  @failingTest
  Future<void> test_patternVariableDeclaration_withType() async {
    await assertContextType('''
void f((int, int) r) {
  (int a, int b) = ^r;
}
''', '(int, int)');
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

  Future<void> test_recordLiteral_named_afterPositional_1() async {
    await assertContextType('''
(int a, {String b}) f() => (0, b: ^);
''', 'String');
  }

  Future<void> test_recordLiteral_named_afterPositional_2() async {
    await assertContextType('''
(int a, int b, {String c}) f() => (0, c: ^, 1);
''', 'String');
  }

  Future<void> test_recordLiteral_named_first_afterColon_1() async {
    await assertContextType('''
({int a, String b}) f() => (b: ^);
''', 'String');
  }

  Future<void> test_recordLiteral_named_first_afterColon_2() async {
    await assertContextType('''
({int a, String b}) f() => (b:^);
''', 'String');
  }

  Future<void> test_recordLiteral_named_first_afterColon_3() async {
    await assertContextType('''
({int a, String b}) f() => (b: x^);
''', 'String');
  }

  Future<void> test_recordLiteral_named_first_inName() async {
    await assertContextType('''
({int a, String b}) f() => (b^:);
''');
  }

  Future<void> test_recordLiteral_positional_afterNamed_existing_1() async {
    await assertContextType('''
(int, String, {int foo}) f() => (foo: 0, ^);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_afterNamed_existing_2() async {
    await assertContextType('''
(int, String, {int foo}) f() => (0, foo: 0, ^);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_afterNamed_notExisting() async {
    await assertContextType('''
(int, String) f() => (foo: 0, ^);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_afterPositional_1() async {
    await assertContextType('''
(int, String) f() => (0, ^);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_afterPositional_2() async {
    await assertContextType('''
(int, String) f() => (0, x^);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_afterPositional_3() async {
    await assertContextType('''
(int, String) f() => (0, ^x);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_afterPositional_4() async {
    await assertContextType('''
(int, String) f() => (0, x^y);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_afterPositional_hasNext_1() async {
    await assertContextType('''
(int, String) f() => (0, ^, 42);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_afterPositional_hasNext_2() async {
    await assertContextType('''
(int, String) f() => (0, x^, 42);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_afterPositional_hasNext_3() async {
    await assertContextType('''
(int, String) f() => (0, ^x, 42);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_asNamed() async {
    await assertContextType('''
(int a, String b) f() => (b: ^);
''');
  }

  Future<void> test_recordLiteral_positional_beforeNamed_noComma_1() async {
    await assertContextType('''
(int, String) f() => (^ foo: 0);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_beforeNamed_noComma_2() async {
    await assertContextType('''
(int, String) f() => (0, ^ foo: 0);
''', 'String');
  }

  Future<void> test_recordLiteral_positional_first_1() async {
    await assertContextType('''
(int, String) f() => (^);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_first_2() async {
    await assertContextType('''
(int, String) f() => (x^);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_first_3() async {
    await assertContextType('''
(int, String) f() => (^x);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_first_4() async {
    await assertContextType('''
(int, String) f() => (x^y);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_first_5() async {
    await assertContextType('''
(int, String) f() => (^,);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_first_6() async {
    await assertContextType('''
(int, String) f() => ( ^ ,);
''', 'int');
  }

  Future<void> test_recordLiteral_positional_tooMany() async {
    await assertContextType('''
(int, double) f() => (0, 1, ^);
''');
  }

  Future<void> test_recordPattern_empty() async {
    await assertContextType('''
void f((int, String) r) {
  if (r case (^)) {}
}
''', 'int');
  }

  Future<void> test_recordPattern_named() async {
    await assertContextType('''
void f((int, {String y}) r) {
  if (r case (1, y: ^)) {}
}
''', 'String');
  }

  Future<void> test_recordPattern_positional_last() async {
    await assertContextType('''
void f((int, String) r) {
  if (r case (1, ^)) {}
}
''', 'String');
  }

  Future<void> test_recordPattern_positional_middle() async {
    await assertContextType('''
void f((int, String, int) r) {
  if (r case (1, ^, 3)) {}
}
''', 'String');
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

  Future<void> test_whenClause() async {
    await assertContextType('''
void f(int i) {
  if (i case > 0 when ^) {}
}
''', 'bool');
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
