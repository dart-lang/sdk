// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.declaration_resolver_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(DeclarationResolverTest);
}

@reflectiveTest
class DeclarationResolverTest extends ResolverTestCase {
  @override
  void setUp() {
    super.setUp();
  }

  void test_functionDeclaration_getter() {
    String code = r'''
int get zzz => 42;
''';
    CompilationUnit unit = resolveSource(code);
    PropertyAccessorElement getterElement =
        findSimpleIdentifier(unit, code, 'zzz =>').staticElement;
    expect(getterElement.isGetter, isTrue);
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = findSimpleIdentifier(unit2, code, 'zzz =>');
    expect(getterName.staticElement, same(getterElement));
  }

  void test_functionDeclaration_setter() {
    String code = r'''
void set zzz(_) {}
''';
    CompilationUnit unit = resolveSource(code);
    PropertyAccessorElement setterElement =
        findSimpleIdentifier(unit, code, 'zzz(_)').staticElement;
    expect(setterElement.isSetter, isTrue);
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = findSimpleIdentifier(unit2, code, 'zzz(_)');
    expect(getterName.staticElement, same(setterElement));
  }

  void test_invalid_functionDeclaration_getter_inFunction() {
    String code = r'''
main() {
  int get zzz => 42;
}
''';
    CompilationUnit unit = resolveSource(code);
    FunctionElement getterElement =
        findSimpleIdentifier(unit, code, 'zzz =>').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = findSimpleIdentifier(unit2, code, 'zzz =>');
    expect(getterName.staticElement, same(getterElement));
  }

  void test_invalid_functionDeclaration_setter_inFunction() {
    String code = r'''
main() {
  set zzz(x) {}
}
''';
    CompilationUnit unit = resolveSource(code);
    FunctionElement setterElement =
        findSimpleIdentifier(unit, code, 'zzz(x)').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier setterName = findSimpleIdentifier(unit2, code, 'zzz(x)');
    expect(setterName.staticElement, same(setterElement));
  }

  static SimpleIdentifier findSimpleIdentifier(
      AstNode root, String code, String search) {
    return EngineTestCase.findNode(
        root, code, search, (n) => n is SimpleIdentifier);
  }

  static CompilationUnit _cloneResolveUnit(CompilationUnit unit) {
    CompilationUnit clonedUnit = AstCloner.clone(unit);
    new DeclarationResolver().resolve(clonedUnit, unit.element);
    return clonedUnit;
  }
}
