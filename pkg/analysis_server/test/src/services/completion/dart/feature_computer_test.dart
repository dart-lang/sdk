// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FeatureComputerTest);
  });
}

@reflectiveTest
class FeatureComputerTest extends AbstractSingleUnitTest {
  @override
  bool verifyNoTestUnitErrors = false;

  Future<void> assertContextType(String content, String expectedType) async {
    var index = content.indexOf('^');
    if (index < 0) {
      fail('Missing node offset marker (^) in content');
    }
    content = content.substring(0, index) + content.substring(index + 1);
    await resolveTestUnit(content);
    // TODO(jwren) Consider changing this from the NodeLocator to the optype
    // node finding logic to be more consistent with what the user behavior
    // here will be.
    var node = NodeLocator(index).searchWithin(testUnit);
    var computer = FeatureComputer(
        testAnalysisResult.typeSystem, testAnalysisResult.typeProvider);
    var type = computer.computeContextType(node, index);

    if (expectedType == null) {
      expect(type, null);
    } else {
      expect(type?.getDisplayString(), expectedType);
    }
  }

  Future<void> test_argumentList_first() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g(int j) {
  f(^j);
}
''', 'int');
  }

  @failingTest
  Future<void> test_argumentList_implicitFirst() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g(int j) {
  f(^);
}
''', 'int');
  }

  Future<void> test_argumentList_noParameters() async {
    await assertContextType('''
void f() {}
void g() {
  f(^);
}
''', null);
  }

  Future<void> test_argumentList_noParameters_whitespage() async {
    await assertContextType('''
void f() {}
void g() {
  f(  ^   );
}
''', null);
  }

  @failingTest
  Future<void> test_argumentList_secondArg() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g(int j) {
  f(1, ^);
}
''', 'String');
  }

  Future<void> test_argumentList_secondArg2() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g(int j) {
  f(1, w^);
}
''', 'String');
  }

  @failingTest
  Future<void> test_argumentList_thirdArg() async {
    await assertContextType('''
void f(int i, String str, bool b) {}
void g(int j) {
  f(1, '2', ^);
}
''', 'bool');
  }

  @failingTest
  Future<void> test_argumentList_thirdArg2() async {
    await assertContextType('''
void f(int i, String str, bool b, num n) {}
void g(int j) {
  f(1, '2', ^);
}
''', 'bool');
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
  var i = ^s.length;
}
''', null);
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
''', null);
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
''', null);
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
''', null);
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
''', null);
  }

  Future<void> test_setOrMapLiteral_set_beforeTypeParameter() async {
    await assertContextType('''
void f() {
  var s = ^<int>{};
}
''', null);
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
''', null);
  }
}
