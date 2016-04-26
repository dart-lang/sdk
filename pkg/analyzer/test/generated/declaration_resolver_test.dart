// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.declaration_resolver_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(DeclarationResolverMetadataTest);
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
class DeclarationResolverMetadataTest extends ResolverTestCase {
  String code;
  CompilationUnit unit;
  CompilationUnit unit2;

  void checkMetadata(String search) {
    NodeList<Annotation> metadata = _findMetadata(unit, search);
    NodeList<Annotation> metadata2 = _findMetadata(unit2, search);
    expect(metadata, isNotEmpty);
    for (int i = 0; i < metadata.length; i++) {
      expect(
          metadata2[i].elementAnnotation, same(metadata[i].elementAnnotation));
    }
  }

  void setupCode(String code) {
    this.code = code;
    unit = resolveSource(code + ' const a = null;');
    unit2 = _cloneResolveUnit(unit);
  }

  void test_metadata_classDeclaration() {
    setupCode('@a class C {}');
    checkMetadata('C');
  }

  void test_metadata_classTypeAlias() {
    setupCode('@a class C = D with E; class D {} class E {}');
    checkMetadata('C');
  }

  void test_metadata_constructorDeclaration_named() {
    setupCode('class C { @a C.x(); }');
    checkMetadata('x');
  }

  void test_metadata_constructorDeclaration_unnamed() {
    setupCode('class C { @a C(); }');
    checkMetadata('C()');
  }

  void test_metadata_declaredIdentifier() {
    setupCode('f(x, y) { for (@a var x in y) {} }');
    checkMetadata('var');
  }

  void test_metadata_enumDeclaration() {
    setupCode('@a enum E { v }');
    checkMetadata('E');
  }

  void test_metadata_exportDirective() {
    addNamedSource('/foo.dart', 'class C {}');
    setupCode('@a export "foo.dart";');
    checkMetadata('export');
  }

  void test_metadata_fieldDeclaration() {
    setupCode('class C { @a int x; }');
    checkMetadata('x');
  }

  void test_metadata_fieldFormalParameter() {
    setupCode('class C { var x; C(@a this.x); }');
    checkMetadata('this');
  }

  void test_metadata_fieldFormalParameter_withDefault() {
    setupCode('class C { var x; C([@a this.x = null]); }');
    checkMetadata('this');
  }

  void test_metadata_functionDeclaration_function() {
    setupCode('@a f() {}');
    checkMetadata('f');
  }

  void test_metadata_functionDeclaration_getter() {
    setupCode('@a get f() => null;');
    checkMetadata('f');
  }

  void test_metadata_functionDeclaration_setter() {
    setupCode('@a set f(value) {}');
    checkMetadata('f');
  }

  void test_metadata_functionTypeAlias() {
    setupCode('@a typedef F();');
    checkMetadata('F');
  }

  void test_metadata_functionTypedFormalParameter() {
    setupCode('f(@a g()) {}');
    checkMetadata('g');
  }

  void test_metadata_functionTypedFormalParameter_withDefault() {
    setupCode('f([@a g() = null]) {}');
    checkMetadata('g');
  }

  void test_metadata_importDirective() {
    addNamedSource('/foo.dart', 'class C {}');
    setupCode('@a import "foo.dart";');
    checkMetadata('import');
  }

  void test_metadata_importDirective_partiallyResolved() {
    addNamedSource('/foo.dart', 'class C {}');
    this.code = 'const a = null; @a import "foo.dart";';
    Source source = addNamedSource('/test.dart', code);
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    analysisContext.computeResult(source, LIBRARY_ELEMENT1);
    unit = analysisContext.computeResult(target, RESOLVED_UNIT1);
    unit2 = _cloneResolveUnit(unit);
    checkMetadata('import');
  }

  void test_metadata_libraryDirective() {
    setupCode('@a library L;');
    checkMetadata('L');
  }

  void test_metadata_localFunctionDeclaration() {
    setupCode('f() { @a g() {} }');
    // Note: metadata on local function declarations is ignored by the
    // analyzer.  TODO(paulberry): is this a bug?
    FunctionDeclaration node = EngineTestCase.findNode(
        unit, code, 'g', (AstNode n) => n is FunctionDeclaration);
    expect((node as FunctionDeclarationImpl).metadata, isEmpty);
  }

  void test_metadata_localVariableDeclaration() {
    setupCode('f() { @a int x; }');
    checkMetadata('x');
  }

  void test_metadata_methodDeclaration_getter() {
    setupCode('class C { @a get m => null; }');
    checkMetadata('m');
  }

  void test_metadata_methodDeclaration_method() {
    setupCode('class C { @a m() {} }');
    checkMetadata('m');
  }

  void test_metadata_methodDeclaration_setter() {
    setupCode('class C { @a set m(value) {} }');
    checkMetadata('m');
  }

  void test_metadata_partDirective() {
    addNamedSource('/foo.dart', 'part of L;');
    setupCode('library L; @a part "foo.dart";');
    checkMetadata('part');
  }

  void test_metadata_simpleFormalParameter() {
    setupCode('f(@a x) {}) {}');
    checkMetadata('x');
  }

  void test_metadata_simpleFormalParameter_withDefault() {
    setupCode('f([@a x = null]) {}');
    checkMetadata('x');
  }

  void test_metadata_topLevelVariableDeclaration() {
    setupCode('@a int x;');
    checkMetadata('x');
  }

  void test_metadata_typeParameter_ofClass() {
    setupCode('class C<@a T> {}');
    checkMetadata('T');
  }

  void test_metadata_typeParameter_ofClassTypeAlias() {
    setupCode('class C<@a T> = D with E; class D {} class E {}');
    checkMetadata('T');
  }

  void test_metadata_typeParameter_ofFunction() {
    setupCode('f<@a T>() {}');
    checkMetadata('T');
  }

  void test_metadata_typeParameter_ofTypedef() {
    setupCode('typedef F<@a T>();');
    checkMetadata('T');
  }

  NodeList<Annotation> _findMetadata(CompilationUnit unit, String search) {
    AstNode node =
        EngineTestCase.findNode(unit, code, search, (AstNode _) => true);
    while (node != null) {
      if (node is AnnotatedNode && node.metadata.isNotEmpty) {
        return node.metadata;
      }
      if (node is NormalFormalParameter && node.metadata.isNotEmpty) {
        return node.metadata;
      }
      node = node.parent;
    }
    fail('Node not found');
    return null;
  }
}

@reflectiveTest
class DeclarationResolverTest extends ResolverTestCase {
  @override
  void setUp() {
    super.setUp();
  }

  void test_enumConstant_partiallyResolved() {
    String code = r'''
enum Fruit {apple, pear}
''';
    Source source = addNamedSource('/test.dart', code);
    LibrarySpecificUnit target = new LibrarySpecificUnit(source, source);
    analysisContext.computeResult(source, LIBRARY_ELEMENT1);
    CompilationUnit unit =
        analysisContext.computeResult(target, RESOLVED_UNIT1);
    _cloneResolveUnit(unit);
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

  void test_visitExportDirective_notExistingSource() {
    String code = r'''
export 'foo.dart';
''';
    CompilationUnit unit = resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  void test_visitExportDirective_unresolvedUri() {
    String code = r'''
export 'package:foo/bar.dart';
''';
    CompilationUnit unit = resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  void test_visitFunctionExpression() {
    String code = r'''
main(List<String> items) {
  items.forEach((item) {});
}
''';
    CompilationUnit unit = resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  void test_visitImportDirective_notExistingSource() {
    String code = r'''
import 'foo.dart';
''';
    CompilationUnit unit = resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  void test_visitImportDirective_unresolvedUri() {
    String code = r'''
import 'package:foo/bar.dart';
''';
    CompilationUnit unit = resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
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

  void test_visitMethodDeclaration_getterSetter() {
    String code = r'''
class C {
  int _field = 0;
  int get field => _field;
  void set field(value) {_field = value;}
}
''';
    CompilationUnit unit = resolveSource(code);
    FieldElement getterElement =
        _findSimpleIdentifier(unit, code, 'field =').staticElement;
    PropertyAccessorElement setterElement =
        _findSimpleIdentifier(unit, code, 'field(').staticElement;
    // re-resolve
    CompilationUnit unit2 = _cloneResolveUnit(unit);
    SimpleIdentifier getterName = _findSimpleIdentifier(unit2, code, 'field =');
    SimpleIdentifier setterName = _findSimpleIdentifier(unit2, code, 'field(');
    expect(getterName.staticElement, same(getterElement));
    expect(setterName.staticElement, same(setterElement));
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

  void test_visitMethodDeclaration_setter_duplicate() {
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

  void test_visitMethodDeclaration_unaryMinus() {
    String code = r'''
class C {
  C operator -() => null;
  C operator -(C other) => null;
}
''';
    CompilationUnit unit = resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
  }

  void test_visitPartDirective_notExistingSource() {
    String code = r'''
part 'foo.bar';
''';
    CompilationUnit unit = resolveSource(code);
    // re-resolve
    _cloneResolveUnit(unit);
    // no other validations than built into DeclarationResolver
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
