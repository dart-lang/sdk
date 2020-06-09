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
  Future<void> assertContextType(String content, String expectedType) async {
    var index = content.indexOf('^');
    if (index < 0) {
      fail('Missing node offset marker (^) in content');
    }
    content = content.substring(0, index) + content.substring(index + 1);
    await resolveTestUnit(content);
    var node = NodeLocator(index).searchWithin(testUnit);
    var computer = FeatureComputer(
        testAnalysisResult.typeSystem, testAnalysisResult.typeProvider);
    var type = computer.computeContextType(node);

    if (expectedType == null) {
      expect(type, null);
    } else {
      expect(type?.getDisplayString(), expectedType);
    }
  }

  Future<void> test_adjacentString_afterFirst() async {
    await assertContextType('''
void f(String s) {}
void g() {
  f('a' ^'b');
}
''', 'String');
  }

  Future<void> test_adjacentString_beforeFirst() async {
    await assertContextType('''
void f(String s) {}
void g() {
  f(^'a' 'b');
}
''', 'String');
  }

  Future<void> test_argumentList() async {
    await assertContextType('''
void f(int i) {}
void g(int j) {
  f(^j);
}
''', 'int');
  }

  Future<void> test_assertInitializer() async {
    await assertContextType('''
class C {
  C(int i) : assert(^i > 0);
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
void g(String s) {
  int i = ^s.length;
}
''', 'int');
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
  var m = <int, String>{^if (b) e : ''};
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
