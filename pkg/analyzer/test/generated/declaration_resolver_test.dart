// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.declaration_resolver_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(DeclarationResolverTest);
  runReflectiveTests(StrongModeDeclarationResolverTest);
}

CompilationUnit _cloneResolveUnit(CompilationUnit unit) {
  CompilationUnit clonedUnit = AstCloner.clone(unit);
  new DeclarationResolver().resolve(clonedUnit, unit.element);
  return clonedUnit;
}

SimpleIdentifier _findSimpleIdentifier(
    AstNode root, String code, String search) {
  return EngineTestCase.findNode(
      root, code, search, (n) => n is SimpleIdentifier);
}

@reflectiveTest
class DeclarationResolverTest extends ResolverTestCase {
  void fail_visitMethodDeclaration_setter_duplicate() {
    // https://github.com/dart-lang/sdk/issues/25601
    String code = r'''
class C {
  set zzz(x) {}
  set zzz(y) {}
}
''';
    CompilationUnit unit = resolveSource(code);
    PropertyAccessorElement firstElement =
        _findSimpleIdentifier(unit, code, 'zzz(x)').staticElement;
    PropertyAccessorElement secondElement =
        _findSimpleIdentifier(unit, code, 'zzz(y)').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier firstName = _findSimpleIdentifier(unit2, code, 'zzz(x)');
    SimpleIdentifier secondName = _findSimpleIdentifier(unit2, code, 'zzz(y)');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }

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
        _findSimpleIdentifier(unit, code, 'zzz =>').staticElement;
    expect(getterElement.isGetter, isTrue);
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = _findSimpleIdentifier(unit2, code, 'zzz =>');
    expect(getterName.staticElement, same(getterElement));
  }

  void test_functionDeclaration_setter() {
    String code = r'''
void set zzz(_) {}
''';
    CompilationUnit unit = resolveSource(code);
    PropertyAccessorElement setterElement =
        _findSimpleIdentifier(unit, code, 'zzz(_)').staticElement;
    expect(setterElement.isSetter, isTrue);
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = _findSimpleIdentifier(unit2, code, 'zzz(_)');
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
        _findSimpleIdentifier(unit, code, 'zzz =>').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = _findSimpleIdentifier(unit2, code, 'zzz =>');
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
        _findSimpleIdentifier(unit, code, 'zzz(x)').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier setterName = _findSimpleIdentifier(unit2, code, 'zzz(x)');
    expect(setterName.staticElement, same(setterElement));
  }

  void test_visitMethodDeclaration_getter_duplicate() {
    String code = r'''
class C {
  int get zzz => 1;
  String get zzz => null;
}
''';
    CompilationUnit unit = resolveSource(code);
    PropertyAccessorElement firstElement =
        _findSimpleIdentifier(unit, code, 'zzz => 1').staticElement;
    PropertyAccessorElement secondElement =
        _findSimpleIdentifier(unit, code, 'zzz => null').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier firstName = _findSimpleIdentifier(unit2, code, 'zzz => 1');
    SimpleIdentifier secondName =
        _findSimpleIdentifier(unit2, code, 'zzz => null');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }

  void test_visitMethodDeclaration_method_duplicate() {
    String code = r'''
class C {
  void zzz(x) {}
  void zzz(y) {}
}
''';
    CompilationUnit unit = resolveSource(code);
    MethodElement firstElement =
        _findSimpleIdentifier(unit, code, 'zzz(x)').staticElement;
    MethodElement secondElement =
        _findSimpleIdentifier(unit, code, 'zzz(y)').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier firstName = _findSimpleIdentifier(unit2, code, 'zzz(x)');
    SimpleIdentifier secondName = _findSimpleIdentifier(unit2, code, 'zzz(y)');
    expect(firstName.staticElement, same(firstElement));
    expect(secondName.staticElement, same(secondElement));
  }
}

/**
 * Strong mode DeclarationResolver tests
 */
@reflectiveTest
class StrongModeDeclarationResolverTest extends ResolverTestCase {
  @override
  void setUp() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
  }

  void test_genericFunction_typeParameter() {
    String code = r'''
/*=T*/ max/*<T>*/(/*=T*/ x, /*=T*/ y) => null;
''';
    CompilationUnit unit = resolveSource(code);
    FunctionDeclaration node = _findSimpleIdentifier(unit, code, 'max').parent;
    TypeParameter t = node.functionExpression.typeParameters.typeParameters[0];

    FunctionElement element = node.name.staticElement;
    TypeParameterElement tElement = element.typeParameters[0];
    expect(tElement, isNotNull);
    expect(element.typeParameters.toString(), "[T]");
    expect(element.type.toString(), "<T>(T, T) → T");
    expect(t.element, same(tElement));

    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    node = _findSimpleIdentifier(unit2, code, 'max').parent;
    t = node.functionExpression.typeParameters.typeParameters[0];
    expect(t.element, same(tElement));
  }

  void test_genericMethod_typeParameter() {
    String code = r'''
class C {
  /*=T*/ max/*<T>*/(/*=T*/ x, /*=T*/ y) => null;
}
''';
    CompilationUnit unit = resolveSource(code);
    MethodDeclaration node = _findSimpleIdentifier(unit, code, 'max').parent;
    TypeParameter t = node.typeParameters.typeParameters[0];

    MethodElement element = node.name.staticElement;
    TypeParameterElement tElement = element.typeParameters[0];
    expect(tElement, isNotNull);
    expect(element.typeParameters.toString(), "[T]");
    expect(element.type.toString(), "<T>(T, T) → T");
    expect(t.element, same(tElement));

    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    node = _findSimpleIdentifier(unit2, code, 'max').parent;
    t = node.typeParameters.typeParameters[0];
    expect(t.element, same(tElement));
  }
}
